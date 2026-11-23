import XCTest
@testable import StationConnection

/// Foto de los widgets, su almacén, la sincronización y los botones.
@MainActor
final class WidgetTests: XCTestCase {
    private var audio: FakeAudioPlayer!
    private var directory: FakeStationDirectory!
    private var library: LibraryViewModel!
    private var suiteName: String!
    private var now = Date(timeIntervalSince1970: 0)
    private var controls: FakeMediaControls!

    override func setUp() async throws {
        audio = FakeAudioPlayer()
        directory = FakeStationDirectory()
        library = makeLibrary()
        suiteName = "WidgetTests-\(UUID().uuidString)"
        now = Date(timeIntervalSince1970: 0)
        controls = FakeMediaControls()
    }

    override func tearDown() async throws {
        UserDefaults().removePersistentDomain(forName: suiteName)
    }

    private func makePlayer() -> PlayerViewModel {
        PlayerViewModel(
            audio: audio,
            controls: controls,
            library: library,
            registerPlay: RegisterPlayUseCase(directory: directory),
            clock: { [unowned self] in self.now }
        )
    }

    private func makeActions(_ player: PlayerViewModel) -> WidgetPlaybackActions {
        WidgetPlaybackActions(
            player: player,
            library: library,
            getStations: GetStationsUseCase(directory: directory),
            clock: { [unowned self] in self.now }
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
        let actions = makeActions(player)

        await actions.play(stationID: Station.fixture(2).id)

        XCTAssertEqual(player.station, .fixture(2))
        XCTAssertEqual(player.queue, makeStations([1, 2, 3]))
    }

    func testPlayingAnUnknownStationAsksTheDirectory() async {
        directory.searchResult = .success([.fixture(9)])
        let player = makePlayer()
        let actions = makeActions(player)

        await actions.play(stationID: Station.fixture(9).id)

        XCTAssertEqual(player.station, .fixture(9))
    }

    func testToggleResumesTheLastStationAndThenStops() {
        library = makeLibrary(favorites: [.fixture(5)])
        library.addRecent(.fixture(4))
        let player = makePlayer()
        let actions = makeActions(player)

        actions.toggle()
        XCTAssertEqual(player.station, .fixture(4))

        now += 2
        actions.toggle()
        XCTAssertEqual(player.status, .stopped)
    }

    func testToggleWithoutRecentsPlaysTheFirstFavorite() {
        library = makeLibrary(favorites: makeStations([5, 6]))
        let player = makePlayer()
        let actions = makeActions(player)

        actions.toggle()

        XCTAssertEqual(player.station, .fixture(5))
    }

    // MARK: - Siri

    func testSiriPlaysTheFavoritesInOrder() {
        library = makeLibrary(favorites: makeStations([3, 1, 2]))
        let player = makePlayer()
        let actions = makeActions(player)

        XCTAssertTrue(actions.playFavorites())

        XCTAssertEqual(player.station, .fixture(3))
        XCTAssertEqual(player.queue, makeStations([3, 1, 2]))
    }

    func testSiriWithoutFavoritesDoesNothing() {
        let player = makePlayer()
        let actions = makeActions(player)

        XCTAssertFalse(actions.playFavorites())
        XCTAssertNil(player.station)
    }

    // MARK: - ▶ y ■ separados, toques repetidos

    func testRepeatedToggleWithinASecondIsIgnored() {
        library.addRecent(.fixture(4))
        let player = makePlayer()
        let actions = makeActions(player)

        actions.toggle()
        now += 0.5
        actions.toggle()

        XCTAssertEqual(player.station, .fixture(4))
        XCTAssertTrue(player.isActive, "El segundo toque repetido no debe detener")
    }

    func testResumeDoesNothingWhenAlreadyPlaying() {
        let player = makePlayer()
        player.play(.fixture(1))
        audio.simulate(.playing)
        let actions = makeActions(player)

        actions.resume()

        XCTAssertEqual(audio.playedURLs.count, 1, "No debe reiniciar la emisora")
    }

    func testResumeRestartsTheCurrentStationAfterStopping() {
        let player = makePlayer()
        player.play(.fixture(1), from: makeStations([1, 2]))
        player.stop()
        let actions = makeActions(player)

        actions.resume()

        XCTAssertEqual(player.station, .fixture(1))
        XCTAssertEqual(player.status, .loading)
        XCTAssertEqual(player.queue, makeStations([1, 2]))
    }

    func testPlayingTheStationThatIsAlreadyPlayingDoesNotRestartIt() async {
        library = makeLibrary(favorites: [.fixture(2)])
        let player = makePlayer()
        player.play(.fixture(2))
        audio.simulate(.playing)
        let actions = makeActions(player)

        await actions.play(stationID: Station.fixture(2).id)

        XCTAssertEqual(audio.playedURLs.count, 1)
    }

    func testStopFromAWidgetIgnoresTheSystemPlayCommandThatFollows() {
        let player = makePlayer()
        player.play(.fixture(1))
        audio.simulate(.playing)
        let actions = makeActions(player)

        actions.stop()
        controls.simulate(.play)
        controls.simulate(.togglePlayPause)
        XCTAssertEqual(player.status, .stopped, "iOS no debe volver a ponerla")

        now += PlayerViewModel.remoteResumeBlock + 1
        controls.simulate(.play)
        XCTAssertEqual(player.status, .loading, "Pasado el margen, ▶ del sistema funciona")
    }

    func testPlayingAgainClearsTheBlock() {
        let player = makePlayer()
        player.play(.fixture(1))
        makeActions(player).stop()

        player.play(.fixture(1))
        player.stop()
        controls.simulate(.play)

        XCTAssertEqual(player.status, .loading)
    }

    // MARK: - Carátula compartida

    func testArtworkTextMatchesTheStationHelpers() {
        let station = Station.fixture(7, name: "La Mega Estéreo")
        XCTAssertEqual(StationArtworkText.initials(for: station.name), "LM")
        XCTAssertEqual(StationArtworkText.initials(for: "Tropicana"), "TR")
        XCTAssertEqual(StationArtworkText.initials(for: "  "), "?")
        XCTAssertEqual(station.gradientIndex, StationArtworkText.gradientIndex(for: station.id))
        XCTAssertTrue((0..<StationArtworkText.gradientCount).contains(station.gradientIndex))
    }

    // MARK: - App Group del perfil de firma

    func testProvisionedGroupsAreReadFromTheEmbeddedProfile() {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0"><dict>
        <key>Entitlements</key><dict>
        <key>com.apple.security.application-groups</key>
        <array><string>group.com.jhonjairo6230.stationconnection.ABCDE12345</string></array>
        </dict></dict></plist>
        """
        // El perfil real es un plist envuelto en bytes de firma (CMS).
        let profile = Data([0x30, 0x82, 0x00, 0xFF]) + Data(xml.utf8) + Data([0x00, 0xA0, 0x82])

        XCTAssertEqual(
            SharedWidgetStore.provisionedGroups(in: profile),
            ["group.com.jhonjairo6230.stationconnection.ABCDE12345"]
        )
    }

    func testProfileWithoutGroupsOrUnreadableGivesNone() {
        XCTAssertEqual(SharedWidgetStore.provisionedGroups(in: Data("basura".utf8)), [])
        let noGroups = Data("<?xml version=\"1.0\"?><plist version=\"1.0\"><dict><key>Entitlements</key><dict/></dict></plist>".utf8)
        XCTAssertEqual(SharedWidgetStore.provisionedGroups(in: noGroups), [])
    }

    func testCandidateGroupsTryTheProjectGroupThenRelatedOnesInAStableOrder() {
        let groups = SharedWidgetStore.candidateGroups(provisioned: [
            "group.otra.app",
            "group.com.jhonjairo6230.stationconnection.ZZZ",
            SharedWidgetStore.appGroup,
            "group.com.jhonjairo6230.StationConnection.AAA",
        ])

        XCTAssertEqual(groups, [
            SharedWidgetStore.appGroup,
            "group.com.jhonjairo6230.StationConnection.AAA",
            "group.com.jhonjairo6230.stationconnection.ZZZ",
            "group.otra.app",
        ])
    }

    func testStoreWithoutDefaultsExplainsWhy() {
        XCTAssertEqual(SharedWidgetStore(defaults: nil).diagnostic, "Sin App Group")
        XCTAssertEqual(SharedWidgetStore(defaults: nil, diagnostic: "La firma no trae App Group").diagnostic, "La firma no trae App Group")
        XCTAssertNil(makeStore().diagnostic)
    }
}
