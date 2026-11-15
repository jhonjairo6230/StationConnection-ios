import XCTest
@testable import StationConnection

@MainActor
final class PlayerViewModelTests: XCTestCase {
    private var audio: FakeAudioPlayer!
    private var controls: FakeMediaControls!
    private var directory: FakeStationDirectory!
    private var library: LibraryViewModel!
    private var now = Date(timeIntervalSince1970: 0)

    override func setUp() async throws {
        audio = FakeAudioPlayer()
        controls = FakeMediaControls()
        directory = FakeStationDirectory()
        library = makeLibrary()
        now = Date(timeIntervalSince1970: 0)
    }

    private func makePlayer() -> PlayerViewModel {
        PlayerViewModel(
            audio: audio,
            controls: controls,
            library: library,
            registerPlay: RegisterPlayUseCase(directory: directory),
            clock: { [unowned self] in self.now },
            tickInterval: .milliseconds(10)
        )
    }

    // MARK: - Reproducir

    func testPlayStartsTheStreamAndUsesTheSourceAsQueue() {
        let player = makePlayer()
        let list = makeStations([1, 2, 3])

        player.play(list[1], from: list)

        XCTAssertEqual(audio.playedURLs, [list[1].streamURL])
        XCTAssertEqual(player.station, list[1])
        XCTAssertEqual(player.status, .loading)
        XCTAssertEqual(player.queue, list)
    }

    func testWhenItStartsPlayingItIsAddedToRecentsAndRegisteredOnce() async throws {
        let player = makePlayer()
        player.play(.fixture(1))

        audio.simulate(.playing)
        audio.simulate(.loading)
        audio.simulate(.playing)

        XCTAssertEqual(player.status, .playing)
        XCTAssertEqual(library.recents, [.fixture(1)])
        try await waitUntil { self.directory.registeredPlays.count == 1 }
        XCTAssertEqual(directory.registeredPlays, [Station.fixture(1).id])
    }

    func testToggleStopsWhatIsPlayingAndResumesLater() {
        let player = makePlayer()
        player.play(.fixture(1))
        audio.simulate(.playing)

        player.toggle()
        XCTAssertEqual(player.status, .stopped)
        XCTAssertEqual(audio.stopCount, 1)

        player.toggle()
        XCTAssertEqual(player.status, .loading)
        XCTAssertEqual(audio.playedURLs.count, 2)
    }

    func testFailuresAreShown() {
        let player = makePlayer()
        player.play(.fixture(1))
        audio.simulate(.failed("No se pudo"))
        XCTAssertEqual(player.status, .failed("No se pudo"))
    }

    // MARK: - Cola y ⏮/⏭

    func testSkipMovesThroughTheQueueAndWrapsAround() {
        let player = makePlayer()
        let list = makeStations([1, 2, 3])
        player.play(list[2], from: list)

        player.skip(.next)
        XCTAssertEqual(player.station, list[0])
        player.skip(.previous)
        XCTAssertEqual(player.station, list[2])
        XCTAssertEqual(player.queue, list, "saltar no cambia la cola")
    }

    func testSkipDoesNothingWithASingleStation() {
        let player = makePlayer()
        player.play(.fixture(1))
        player.skip(.next)
        XCTAssertEqual(audio.playedURLs.count, 1)
        XCTAssertNil(player.nextStation)
    }

    func testWithoutSourceAFavoriteUsesTheFavoritesAsQueue() {
        library = makeLibrary(favorites: makeStations([4, 5, 6]))
        let player = makePlayer()
        player.play(.fixture(5))
        XCTAssertEqual(player.queue, makeStations([4, 5, 6]))
    }

    func testCarAndLockScreenCommands() {
        let player = makePlayer()
        let list = makeStations([1, 2])
        player.play(list[0], from: list)
        audio.simulate(.playing)

        controls.simulate(.next)
        XCTAssertEqual(player.station, list[1])
        controls.simulate(.previous)
        XCTAssertEqual(player.station, list[0])
        audio.simulate(.playing)
        controls.simulate(.pause)
        XCTAssertEqual(player.status, .stopped)
        controls.simulate(.play)
        XCTAssertEqual(player.status, .loading)
        XCTAssertTrue(controls.lastCanSkip)
    }

    func testReorderingFavoritesWhilePlayingUpdatesTheQueue() {
        library = makeLibrary(favorites: makeStations([1, 2, 3]))
        let player = makePlayer()
        player.play(.fixture(1), from: library.favorites)

        library.moveFavorites(from: IndexSet(integer: 2), to: 0)

        XCTAssertEqual(player.queue.map(\.name), ["Radio 3", "Radio 1", "Radio 2"])
        XCTAssertEqual(player.nextStation?.name, "Radio 2")
    }

    // MARK: - Sonando ahora

    func testSongTitlesUpdateNowPlayingTheHistoryAndTheLockScreen() {
        let player = makePlayer()
        player.play(.fixture(1))
        audio.simulate(.playing)

        audio.simulateTitle("Juanes - La Camisa Negra")
        audio.simulateTitle("Juanes - La Camisa Negra")
        audio.simulateTitle("Unknown")

        XCTAssertEqual(player.nowPlaying, Song(raw: "Juanes - La Camisa Negra", artist: "Juanes", title: "La Camisa Negra"))
        XCTAssertEqual(library.songs.count, 1)
        XCTAssertEqual(controls.lastInfo?.title, "La Camisa Negra")
        XCTAssertEqual(controls.lastInfo?.artist, "Juanes")
        XCTAssertEqual(controls.lastInfo?.album, "Radio 1")
        XCTAssertEqual(controls.lastInfo?.isPlaying, true)
    }

    func testChangingStationClearsTheSong() {
        let player = makePlayer()
        let list = makeStations([1, 2])
        player.play(list[0], from: list)
        audio.simulateTitle("A - B")
        player.skip(.next)
        XCTAssertNil(player.nowPlaying)
    }

    // MARK: - Temporizador

    func testSleepTimerFadesOutAndStops() async throws {
        let player = makePlayer()
        player.play(.fixture(1))
        audio.simulate(.playing)

        player.setSleepTimer(after: 60)
        XCTAssertEqual(player.sleepRemaining, 60)

        now = Date(timeIntervalSince1970: 45) // faltan 15 s: mitad del fundido
        try await waitUntil { (self.audio.volumeHistory.last ?? 1) < 0.6 }
        XCTAssertEqual(audio.volumeHistory.last ?? 1, 0.5, accuracy: 0.05)

        now = Date(timeIntervalSince1970: 61)
        try await waitUntil { player.status == .stopped }
        XCTAssertNil(player.sleepEndsAt)
        XCTAssertEqual(audio.volume, 1, "el volumen se restaura")
    }

    func testSleepTimerCanBeCancelledAndNeedsSomethingPlaying() {
        let player = makePlayer()
        player.setSleepTimer(after: 60)
        XCTAssertNil(player.sleepEndsAt, "sin nada sonando no se programa")

        player.play(.fixture(1))
        audio.simulate(.playing)
        player.setSleepTimer(after: 60)
        XCTAssertNotNil(player.sleepEndsAt)
        player.setSleepTimer(after: nil)
        XCTAssertNil(player.sleepEndsAt)
    }
}
