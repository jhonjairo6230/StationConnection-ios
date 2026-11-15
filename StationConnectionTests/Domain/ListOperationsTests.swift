import XCTest
@testable import StationConnection

final class ListOperationsTests: XCTestCase {
    func testToggleAddsAtTheStartAndRemovesIfPresent() {
        let added = ListOperations.toggle(.fixture(2), in: makeStations([1]))
        XCTAssertEqual(added.map(\.name), ["Radio 2", "Radio 1"])
        XCTAssertEqual(ListOperations.toggle(.fixture(1), in: added).map(\.name), ["Radio 2"])
    }

    func testPushRecentMovesToTheTopWithoutDuplicatesAndRespectsTheMax() {
        let list = makeStations([1, 2, 3])
        XCTAssertEqual(ListOperations.pushRecent(.fixture(3), to: list).map(\.name), ["Radio 3", "Radio 1", "Radio 2"])
        XCTAssertEqual(ListOperations.pushRecent(.fixture(4), to: list, max: 3).map(\.name), ["Radio 4", "Radio 1", "Radio 2"])
    }

    func testMoveClampsTheDestinationAndIgnoresInvalidSources() {
        let list = ["a", "b", "c", "d"]
        XCTAssertEqual(ListOperations.move(list, from: 0, to: 2), ["b", "c", "a", "d"])
        XCTAssertEqual(ListOperations.move(list, from: 3, to: 0), ["d", "a", "b", "c"])
        XCTAssertEqual(ListOperations.move(list, from: 1, to: 99), ["a", "c", "d", "b"])
        XCTAssertEqual(ListOperations.move(list, from: 9, to: 0), list)
    }

    func testSortsByNameInSpanishIgnoringCaseAndAccents() {
        let sorted = ListOperations.sortedByName([
            .fixture(1, name: "Zeta FM"), .fixture(2, name: "Ábaco Radio"), .fixture(3, name: "bolero"), .fixture(4, name: "Árbol"),
        ])
        XCTAssertEqual(sorted.map(\.name), ["Ábaco Radio", "Árbol", "bolero", "Zeta FM"])
    }

    func testSameStationsComparesIdsInAnyOrder() {
        XCTAssertTrue(ListOperations.sameStations(makeStations([1, 2]), makeStations([2, 1])))
        XCTAssertFalse(ListOperations.sameStations(makeStations([1, 2]), makeStations([1, 3])))
        XCTAssertFalse(ListOperations.sameStations(makeStations([1]), makeStations([1, 2])))
    }

    func testPushSongSkipsTheSameSongOnTheSameStation() {
        let song = Song.parse("A - B")!
        let first = PlayedSong(song: song, stationID: "s1", stationName: "R", playedAt: Date())
        let list = ListOperations.pushSong(first, to: [])
        XCTAssertEqual(ListOperations.pushSong(first, to: list).count, 1)
        let otherStation = PlayedSong(song: song, stationID: "s2", stationName: "R", playedAt: Date())
        XCTAssertEqual(ListOperations.pushSong(otherStation, to: list).count, 2)
    }
}
