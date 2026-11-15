import XCTest
@testable import StationConnection

final class UseCasesTests: XCTestCase {
    func testSearchNormalizesTheQuery() async throws {
        let directory = FakeStationDirectory()
        _ = try await SearchStationsUseCase(directory: directory).execute(StationQuery(name: " jazz ", limit: 500))
        XCTAssertEqual(directory.queries.first?.name, "jazz")
        XCTAssertEqual(directory.queries.first?.limit, 100)
    }

    func testCountriesHidesAlmostEmptyOnes() async throws {
        let directory = FakeStationDirectory()
        directory.countryList = [Country(name: "Colombia", code: "CO", stationCount: 500), Country(name: "Islita", code: "XX", stationCount: 2)]
        let countries = try await GetCountriesUseCase(directory: directory).execute()
        XCTAssertEqual(countries.map(\.code), ["CO"])
    }

    func testToggleFavoriteSavesTheNewList() throws {
        let repository = InMemoryListRepository<Station>()
        let useCase = ToggleFavoriteUseCase(repository: repository)
        _ = try useCase.execute(.fixture(1))
        XCTAssertEqual(try repository.load(), [.fixture(1)])
        _ = try useCase.execute(.fixture(1))
        XCTAssertEqual(try repository.load(), [])
    }

    func testReorderFollowsSwiftUIOnMoveSemantics() throws {
        let repository = InMemoryListRepository<Station>()
        try repository.save(makeStations([1, 2, 3, 4]))
        let useCase = ReorderFavoritesUseCase(repository: repository)
        // Mover la primera al final (onMove entrega destino = count).
        XCTAssertEqual(try useCase.move(from: IndexSet(integer: 0), to: 4).map(\.name), ["Radio 2", "Radio 3", "Radio 4", "Radio 1"])
        // Mover la última al principio.
        XCTAssertEqual(try useCase.move(from: IndexSet(integer: 3), to: 0).map(\.name), ["Radio 1", "Radio 2", "Radio 3", "Radio 4"])
    }

    func testImportAddsOnlyNewStations() throws {
        let repository = InMemoryListRepository<Station>()
        try repository.save([.fixture(1)])
        let data = try FavoritesBackup.encode(makeStations([1, 2]))
        let result = try ImportFavoritesUseCase(repository: repository).execute(data)
        XCTAssertEqual(result.added, 1)
        XCTAssertEqual(result.existing, 1)
        XCTAssertEqual(try repository.load().map(\.name), ["Radio 1", "Radio 2"])
    }

    func testRecentsAndSongHistory() throws {
        let recents = RecentsUseCase(repository: InMemoryListRepository<Station>())
        _ = try recents.add(.fixture(1))
        XCTAssertEqual(try recents.add(.fixture(2)).map(\.name), ["Radio 2", "Radio 1"])
        try recents.clear()
        XCTAssertEqual(try recents.load(), [])

        let date = Date(timeIntervalSince1970: 100)
        let history = SongHistoryUseCase(repository: InMemoryListRepository<PlayedSong>(), now: { date })
        let songs = try history.record(Song.parse("A - B")!, on: .fixture(1))
        XCTAssertEqual(songs, [PlayedSong(song: Song.parse("A - B")!, stationID: Station.fixture(1).id, stationName: "Radio 1", playedAt: date)])
    }

    func testStorageErrorsPropagate() {
        let repository = FailingRepository()
        XCTAssertThrowsError(try ToggleFavoriteUseCase(repository: repository).execute(.fixture(1))) { error in
            XCTAssertEqual(error as? StationError, .storageFailed)
        }
    }
}

private struct FailingRepository: FavoritesRepository {
    func load() throws -> [Station] { throw StationError.storageFailed }
    func save(_ stations: [Station]) throws { throw StationError.storageFailed }
}
