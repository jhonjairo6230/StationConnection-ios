import XCTest
@testable import StationConnection

/// Foto de los widgets, su almacén, la sincronización y los botones.
@MainActor
final class WidgetTests: XCTestCase {
    private var audio: FakeAudioPlayer!
    private var directory: FakeStationDirectory!
    private var library: LibraryViewModel!
    private var suiteName: String!

    override func setUp() async throws {
        audio = FakeAudioPlayer()
        directory = FakeStationDirectory()
        library = makeLibrary()
        suiteName = "WidgetTests-\(UUID().uuidString)"
    }

    override func tearDown() async throws {
        UserDefaults().removePersistentDomain(forName: suiteName)
    }

    private func makePlayer() -> PlayerViewModel {
        PlayerViewModel(
            audio: audio,
            controls: FakeMediaControls(),
            library: library,
            registerPlay: RegisterPlayUseCase(directory: directory)
        )
    }

    private func makeStore() -> SharedWidgetStore {
        SharedWidgetStore(defaults: UserDefaults(suiteName: suiteName)!)
    }

    // MARK: - WidgetSnapshot.make

    func testSnapshotShowsThePlayingStationAndItsSong() {
        let snapshot = WidgetSnapshot.make(
            station: .fixture(1),
            isPlaying: true,
            song: Song.parse("Artista - Canción"),
            recents: [.fixture(2)],
            favorites: makeStations([1, 2, 3, 4, 5])
        )

        XCTAssertEqual(snapshot.current?.id, Station.fixture(1).id)
        XCTAssertEqual(snapshot.current?.name, "Radio 1")
        XCTAssertTrue(snapshot.isPlaying)
        XCTAssertEqual(snapshot.songTitle, "Canción")
        XCTAssertEqual(snapshot.songArtist, "Artista")
        XCTAssertEqual(snapshot.favorites.map(\.id), makeStations([1, 2, 3, 4]).map(\.id))
    }

    func testWithoutAStationTheLastRecentIsShownStoppedAndWithoutSong() {
        let snapshot = WidgetSnapshot.make(
            station: nil,
            isPlaying: true,
            song: Song.parse("Vieja"),
            recents: [.fixture(7), .fixture(8)],
            favorites: []
        )

        XCTAssertEqual(snapshot.current?.id, Station.fixture(7).id)
        XCTAssertFalse(snapshot.isPlaying)
        XCTAssertNil(snapshot.songTitle)
        XCTAssertTrue(snapshot.favorites.isEmpty)
    }

    // MARK: - SharedWidgetStore

    func testStoreSavesAndLoadsTheSnapshot() {
        let store = makeStore()
        XCTAssertNil(store.load())

        let snapshot = WidgetSnapshot.make(station: .fixture(1), isPlaying: true, song: nil, recents: [], favorites: [.fixture(2)])
        store.save(snapshot)

        XCTAssertTrue(store.isAvailable)
        XCTAssertEqual(store.load(), snapshot)
    }

    func testStoreWithoutAppGroupDoesNothing() {
        let store = SharedWidgetStore(defaults: nil)
        store.save(.empty)

        XCTAssertFalse(store.isAvailable)
        XCTAssertNil(store.load())
    }

    // MARK: - WidgetSync

    func testSyncPublishesOnlyWhenTheSnapshotChanges() async throws {
        let player = makePlayer()
        let store = makeStore()
        var reloads = 0
        let sync = WidgetSync(player: player, library: library, store: store) { reloads += 1 }

        sync.start()
        XCTAssertEqual(reloads, 1)
        XCTAssertEqual(store.load(), .empty)

        sync.publish()
        XCTAssertEqual(reloads, 1, "Sin cambios no se redibuja")

        player.play(.fixture(3))
        audio.simulate(.playing)
        try await waitUntil { store.load()?.isPlaying == true }
        XCTAssertEqual(store.load()?.current?.id, Station.fixture(3).id)
        XCTAssertGreaterThan(reloads, 1)
    }

    func testSyncWithoutAppGroupNeverReloads() {
        var reloads = 0
        let sync = WidgetSync(player: makePlayer(), library: library, store: SharedWidgetStore(defaults: nil)) { reloads += 1 }

        sync.start()

        XCTAssertEqual(reloads, 0)
    }

    // MARK: - WidgetPlaybackActions

    func testPlayingAFavoriteUsesTheFavoritesAsQueue() async {
        library = makeLibrary(favorites: makeStations([1, 2, 3]))
        let player = makePlayer()
        let actions = WidgetPlaybackActions(player: player, library: library, getStations: GetStationsUseCase(directory: directory))

        await actions.play(stationID: Station.fixture(2).id)

        XCTAssertEqual(player.station, .fixture(2))
        XCTAssertEqual(player.queue, makeStations([1, 2, 3]))
    }

    func testPlayingAnUnknownStationAsksTheDirectory() async {
        directory.searchResult = .success([.fixture(9)])
        let player = makePlayer()
        let actions = WidgetPlaybackActions(player: player, library: library, getStations: GetStationsUseCase(directory: directory))

        await actions.play(stationID: Station.fixture(9).id)

        XCTAssertEqual(player.station, .fixture(9))
    }

    func testToggleResumesTheLastStationAndThenStops() {
        library = makeLibrary(favorites: [.fixture(5)])
        library.addRecent(.fixture(4))
        let player = makePlayer()
        let actions = WidgetPlaybackActions(player: player, library: library, getStations: GetStationsUseCase(directory: directory))

        actions.toggle()
        XCTAssertEqual(player.station, .fixture(4))

        actions.toggle()
        XCTAssertEqual(player.status, .stopped)
    }

    func testToggleWithoutRecentsPlaysTheFirstFavorite() {
        library = makeLibrary(favorites: makeStations([5, 6]))
        let player = makePlayer()
        let actions = WidgetPlaybackActions(player: player, library: library, getStations: GetStationsUseCase(directory: directory))

        actions.toggle()

        XCTAssertEqual(player.station, .fixture(5))
    }
}
