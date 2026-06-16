import XCTest
@testable import WalkFlowCore

final class RecognitionMetricsTests: XCTestCase {
    func testAccuracyComputesCorrectly() {
        var metrics = RecognitionMetrics()
        metrics.record(expected: .openPalm, actual: .openPalm)
        metrics.record(expected: .openPalm, actual: .none)
        XCTAssertEqual(metrics.accuracy(for: .openPalm), 0.5)
    }

    func testFalseTriggerCountIncrementsForActionableGestureWhenExpectedNone() {
        var metrics = RecognitionMetrics()
        metrics.record(expected: .none, actual: .okPinch)
        XCTAssertEqual(metrics.falseTriggerCount, 1)
    }
}
