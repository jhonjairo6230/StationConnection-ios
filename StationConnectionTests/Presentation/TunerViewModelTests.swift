import XCTest
@testable import StationConnection

@MainActor
final class TunerViewModelTests: XCTestCase {
    private var audio: FakeAudioPlayer!
    private var noise: FakeNoiseGenerator!
    private var player: PlayerViewModel!
    private var directory: FakeStationDirectory!
    private let band = makeStations([1, 2, 3, 4])

    override func setUp() async throws {
        audio = FakeAudioPlayer()
        noise = FakeNoiseGenerator()
        directory = FakeStationDirectory()
        directory.searchResult = .success(band)
        player = PlayerViewModel(
            audio: audio,
            controls: FakeMediaControls(),
            library: makeLibrary(),
            registerPlay: RegisterPlayUseCase(directory: directory)
        )
    }

    private func makeViewModel() async -> TunerViewModel {
        let viewModel = TunerViewModel(
            search: SearchStationsUseCase(directory: directory),
            getTags: GetTagsUseCase(directory: directory),
            getCountries: GetCountriesUseCase(directory: directory),
            player: player,
            noise: noise,
            settleDelay: .milliseconds(20)
        )
        await viewModel.onAppear()
        return viewModel
    }

    func testSettlingOnAStationTunesItWithTheBandAsQueue() async throws {
        let viewModel = await makeViewModel()

        viewModel.move(to: TunerDial.position(of: 1, count: 4))

        XCTAssertEqual(viewModel.lockedStation, band[1])
        XCTAssertTrue(noise.isRunning)
        try await waitUntil { self.player.station == self.band[1] }
        XCTAssertEqual(player.queue, band)
    }

    func testStaticIsLoudBetweenStationsAndSilentOnAir() async throws {
        let viewModel = await makeViewModel()
        viewModel.move(to: 250) // a mitad de camino
        XCTAssertGreaterThan(noise.level, 0.5)

        viewModel.move(to: TunerDial.position(of: 1, count: 4))
        try await waitUntil { self.player.station == self.band[1] }
        audio.simulate(.playing)
        viewModel.updateNoise()
        XCTAssertEqual(noise.level, 0)
        XCTAssertEqual(viewModel.statusText, "● EN EL AIRE")
    }

    func testMovingAwayFromABandStationLosesTheSignal() async throws {
        let viewModel = await makeViewModel()
        viewModel.move(to: TunerDial.position(of: 0, count: 4))
        try await waitUntil { self.player.station == self.band[0] }
        audio.simulate(.playing)

        viewModel.move(to: 250)

        XCTAssertEqual(player.status, .stopped)
    }

    func testTheNeedleFollowsStationChangesFromOutside() async throws {
        let viewModel = await makeViewModel()
        player.play(band[2], from: band)

        viewModel.syncToPlayingStation()

        XCTAssertEqual(viewModel.value, TunerDial.position(of: 2, count: 4))
        XCTAssertEqual(viewModel.lockedStation, band[2])
    }

    func testSeekJumpsToTheNextStation() async {
        let viewModel = await makeViewModel()
        viewModel.seek(.next)
        XCTAssertEqual(viewModel.lockedStation, band[0])
        viewModel.seek(.previous)
        XCTAssertEqual(viewModel.lockedStation, band[3])
    }
}
