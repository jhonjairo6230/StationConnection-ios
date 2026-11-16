import XCTest
@testable import StationConnection

final class JSONFileRepositoryTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    func testReturnsAnEmptyListWhenNothingWasSaved() throws {
        XCTAssertEqual(try JSONFileRepository<Station>(directory: directory, name: "favorites").load(), [])
    }

    func testSavesAndLoadsInTheSameOrder() throws {
        let repository = JSONFileRepository<Station>(directory: directory, name: "favorites")
        try repository.save(makeStations([3, 1, 2]))
        XCTAssertEqual(try repository.load().map(\.name), ["Radio 3", "Radio 1", "Radio 2"])
    }

    func testSavesSongsWithDates() throws {
        let repository = JSONFileRepository<PlayedSong>(directory: directory, name: "songs")
        let played = PlayedSong(song: Song.parse("A - B")!, stationID: "s", stationName: "R", playedAt: Date(timeIntervalSince1970: 1_000))
        try repository.save([played])
        XCTAssertEqual(try repository.load(), [played])
    }

    func testCorruptFilesBecomeAStorageError() throws {
        let repository = JSONFileRepository<Station>(directory: directory, name: "favorites")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("{roto".utf8).write(to: repository.fileURL)
        XCTAssertThrowsError(try repository.load()) { error in
            XCTAssertEqual(error as? StationError, .storageFailed)
        }
    }

    func testUsesTheWebAppFieldNames() throws {
        let repository = JSONFileRepository<Station>(directory: directory, name: "favorites")
        try repository.save([.fixture(1)])
        let text = try String(contentsOf: repository.fileURL, encoding: .utf8)
        XCTAssertTrue(text.contains("\"streamUrl\""))
        XCTAssertTrue(text.contains("\"hls\""))
    }
}
