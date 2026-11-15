import XCTest
@testable import StationConnection

final class PlaybackQueueTests: XCTestCase {
    private let a = Station.fixture(1), b = Station.fixture(2), c = Station.fixture(3), d = Station.fixture(4)

    func testUsesTheSourceListWithoutDuplicates() {
        let queue = PlaybackQueue.resolve(for: b, source: [a, b, b, c], current: [], favorites: [])
        XCTAssertEqual(queue, [a, b, c])
    }

    func testIgnoresASourceThatDoesNotContainTheStation() {
        XCTAssertEqual(PlaybackQueue.resolve(for: d, source: [a, b], current: [], favorites: []), [d])
    }

    func testKeepsTheCurrentQueueWhenItContainsTheStation() {
        XCTAssertEqual(PlaybackQueue.resolve(for: b, source: nil, current: [a, b, c], favorites: [d]), [a, b, c])
    }

    func testFallsBackToFavoritesThenToTheStationAlone() {
        XCTAssertEqual(PlaybackQueue.resolve(for: d, source: nil, current: [a], favorites: [c, d]), [c, d])
        XCTAssertEqual(PlaybackQueue.resolve(for: d, source: nil, current: [a], favorites: [b]), [d])
    }

    func testNeighborWrapsAround() {
        let queue = [a, b, c]
        XCTAssertEqual(PlaybackQueue.neighbor(in: queue, of: a.id, direction: .next), b)
        XCTAssertEqual(PlaybackQueue.neighbor(in: queue, of: c.id, direction: .next), a)
        XCTAssertEqual(PlaybackQueue.neighbor(in: queue, of: a.id, direction: .previous), c)
    }

    func testNeighborStartsAtAnEdgeWhenTheStationIsNotInTheQueue() {
        XCTAssertEqual(PlaybackQueue.neighbor(in: [a, b, c], of: "x", direction: .next), a)
        XCTAssertEqual(PlaybackQueue.neighbor(in: [a, b, c], of: nil, direction: .previous), c)
    }

    func testThereIsNoNeighborWithLessThanTwoStations() {
        XCTAssertNil(PlaybackQueue.neighbor(in: [a], of: a.id, direction: .next))
        XCTAssertNil(PlaybackQueue.neighbor(in: [], of: nil, direction: .next))
    }
}
