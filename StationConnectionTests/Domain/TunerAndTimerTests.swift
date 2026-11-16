import XCTest
@testable import StationConnection

final class TunerDialTests: XCTestCase {
    func testStationsSitInTheMiddleOfTheirLane() {
        XCTAssertEqual(TunerDial.position(of: 0, count: 4), 125)
        XCTAssertEqual(TunerDial.position(of: 3, count: 4), 875)
    }

    func testTuningRightOnAStationLocksIt() {
        XCTAssertEqual(TunerDial.tune(375, count: 4), TunerDial.State(index: 1, offset: 0, isLocked: true))
    }

    func testHalfwayBetweenStationsIsNotLocked() {
        let state = TunerDial.tune(250, count: 4)!
        XCTAssertEqual(state.offset, 1, accuracy: 0.001)
        XCTAssertFalse(state.isLocked)
    }

    func testClampsToTheEdges() {
        XCTAssertEqual(TunerDial.tune(-50, count: 4)?.index, 0)
        XCTAssertEqual(TunerDial.tune(1050, count: 4)?.index, 3)
        XCTAssertNil(TunerDial.tune(500, count: 0))
    }

    func testFrequencyMapsTheDialToFM() {
        XCTAssertEqual(TunerDial.frequency(at: 0), 88)
        XCTAssertEqual(TunerDial.frequency(at: 1000), 108)
        XCTAssertEqual(TunerDial.frequency(at: 123), 90.5)
    }

    func testStaticIsSilentWhenLockedAndLouderFurtherAway() {
        XCTAssertEqual(TunerDial.staticLevel(TunerDial.tune(375, count: 4)), 0)
        let near = TunerDial.staticLevel(TunerDial.State(index: 0, offset: 0.4, isLocked: false))
        let far = TunerDial.staticLevel(TunerDial.State(index: 0, offset: 1, isLocked: false))
        XCTAssertGreaterThan(near, 0)
        XCTAssertGreaterThan(far, near)
        XCTAssertLessThanOrEqual(far, 1)
    }

    func testSeekWrapsAround() {
        XCTAssertEqual(TunerDial.seek(from: 0, count: 4, direction: .next), 125)
        XCTAssertEqual(TunerDial.seek(from: 875, count: 4, direction: .next), 125)
        XCTAssertEqual(TunerDial.seek(from: 0, count: 4, direction: .previous), 875)
        XCTAssertNil(TunerDial.seek(from: 0, count: 0, direction: .next))
    }
}

final class SleepTimerTests: XCTestCase {
    func testVolumeFadesOnlyAtTheEnd() {
        XCTAssertEqual(SleepTimer.fadedVolume(base: 0.8, remaining: 60), 0.8)
        XCTAssertEqual(SleepTimer.fadedVolume(base: 0.8, remaining: 15), 0.4, accuracy: 0.001)
        XCTAssertEqual(SleepTimer.fadedVolume(base: 0.8, remaining: 0), 0)
        XCTAssertEqual(SleepTimer.fadedVolume(base: 0.8, remaining: -5), 0)
    }

    func testFormatsTheCountdown() {
        XCTAssertEqual(SleepTimer.format(remaining: 9), "0:09")
        XCTAssertEqual(SleepTimer.format(remaining: 23 * 60 + 4), "23:04")
        XCTAssertEqual(SleepTimer.format(remaining: 3909), "1:05:09")
        XCTAssertEqual(SleepTimer.format(remaining: 0.5), "0:01")
        XCTAssertEqual(SleepTimer.format(remaining: -1), "0:00")
    }

    func testMenuLabels() {
        XCTAssertEqual(SleepTimer.label(minutes: 15), "15 minutos")
        XCTAssertEqual(SleepTimer.label(minutes: 60), "1 hora")
        XCTAssertEqual(SleepTimer.label(minutes: 90), "1.5 horas")
    }
}
