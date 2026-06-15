import XCTest
@testable import WalkFlowCore

final class GestureClassifierTests: XCTestCase {
    func testNilSnapshotReturnsHandLost() {
        let classifier = GestureClassifier()
        let result = classifier.classify(nil)
        XCTAssertEqual(result.kind, .handLost)
    }

    func testOpenPalmClassifiesFiveExtendedFingers() {
        let classifier = GestureClassifier()
        let result = classifier.classify(.openPalm(timestamp: 1))
        XCTAssertEqual(result.kind, .openPalm)
    }

    func testOpenPalmClassifiesLeftAndRightHands() {
        let classifier = GestureClassifier()

        XCTAssertEqual(classifier.classify(.openPalm(timestamp: 1, handedness: .right)).kind, .openPalm)
        XCTAssertEqual(classifier.classify(.openPalm(timestamp: 1, handedness: .left)).kind, .openPalm)
    }

    func testIndexUpRequiresOnlyIndexExtendedUpward() {
        let classifier = GestureClassifier()
        let result = classifier.classify(.indexUp(timestamp: 1))
        XCTAssertEqual(result.kind, .indexUp)
    }

    func testIndexDownRequiresOnlyIndexExtendedDownward() {
        let classifier = GestureClassifier()
        let result = classifier.classify(.indexDown(timestamp: 1))
        XCTAssertEqual(result.kind, .indexDown)
    }

    func testFistRequiresAllFingersCurled() {
        let classifier = GestureClassifier()
        let result = classifier.classify(.fist(timestamp: 1))
        XCTAssertEqual(result.kind, .fist)
    }

    func testOKPinchRequiresThumbIndexContactAndOtherFingersExtended() {
        let classifier = GestureClassifier()
        let result = classifier.classify(.okPinch(timestamp: 1))
        XCTAssertEqual(result.kind, .okPinch)
    }

    func testLowConfidenceReturnsHandLost() {
        let classifier = GestureClassifier(minimumJointConfidence: 0.8)
        let result = classifier.classify(.openPalm(timestamp: 1, confidence: 0.2))
        XCTAssertEqual(result.kind, .handLost)
    }
}

private extension HandPoseSnapshot {
    static func openPalm(timestamp: TimeInterval, confidence: Double = 1, handedness: Handedness = .right) -> HandPoseSnapshot {
        fixture(timestamp: timestamp, confidence: confidence, tips: [
            .thumbTip: HandPoint(x: 0.20, y: 0.62, confidence: confidence),
            .indexTip: HandPoint(x: 0.38, y: 0.90, confidence: confidence),
            .middleTip: HandPoint(x: 0.50, y: 0.94, confidence: confidence),
            .ringTip: HandPoint(x: 0.62, y: 0.90, confidence: confidence),
            .littleTip: HandPoint(x: 0.76, y: 0.80, confidence: confidence)
        ], handedness: handedness)
    }

    static func indexUp(timestamp: TimeInterval, confidence: Double = 1) -> HandPoseSnapshot {
        fixture(timestamp: timestamp, confidence: confidence, tips: [
            .thumbTip: HandPoint(x: 0.34, y: 0.46, confidence: confidence),
            .indexTip: HandPoint(x: 0.50, y: 0.92, confidence: confidence),
            .middleTip: HandPoint(x: 0.55, y: 0.45, confidence: confidence),
            .ringTip: HandPoint(x: 0.62, y: 0.43, confidence: confidence),
            .littleTip: HandPoint(x: 0.69, y: 0.41, confidence: confidence)
        ])
    }

    static func indexDown(timestamp: TimeInterval, confidence: Double = 1) -> HandPoseSnapshot {
        var snapshot = fixture(timestamp: timestamp, confidence: confidence, tips: [
            .thumbTip: HandPoint(x: 0.34, y: 0.46, confidence: confidence),
            .indexTip: HandPoint(x: 0.50, y: 0.08, confidence: confidence),
            .middleTip: HandPoint(x: 0.55, y: 0.45, confidence: confidence),
            .ringTip: HandPoint(x: 0.62, y: 0.43, confidence: confidence),
            .littleTip: HandPoint(x: 0.69, y: 0.41, confidence: confidence)
        ])
        snapshot.points[.indexPIP] = HandPoint(x: 0.50, y: 0.26, confidence: confidence)
        snapshot.points[.indexDIP] = HandPoint(x: 0.50, y: 0.16, confidence: confidence)
        return snapshot
    }

    static func fist(timestamp: TimeInterval, confidence: Double = 1) -> HandPoseSnapshot {
        fixture(timestamp: timestamp, confidence: confidence, tips: [
            .thumbTip: HandPoint(x: 0.39, y: 0.47, confidence: confidence),
            .indexTip: HandPoint(x: 0.45, y: 0.45, confidence: confidence),
            .middleTip: HandPoint(x: 0.52, y: 0.44, confidence: confidence),
            .ringTip: HandPoint(x: 0.59, y: 0.44, confidence: confidence),
            .littleTip: HandPoint(x: 0.66, y: 0.43, confidence: confidence)
        ])
    }

    static func okPinch(timestamp: TimeInterval, confidence: Double = 1) -> HandPoseSnapshot {
        fixture(timestamp: timestamp, confidence: confidence, tips: [
            .thumbTip: HandPoint(x: 0.38, y: 0.63, confidence: confidence),
            .indexTip: HandPoint(x: 0.41, y: 0.64, confidence: confidence),
            .middleTip: HandPoint(x: 0.53, y: 0.91, confidence: confidence),
            .ringTip: HandPoint(x: 0.64, y: 0.88, confidence: confidence),
            .littleTip: HandPoint(x: 0.76, y: 0.80, confidence: confidence)
        ])
    }

    static func fixture(
        timestamp: TimeInterval,
        confidence: Double,
        tips: [HandJointName: HandPoint],
        handedness: Handedness = .right
    ) -> HandPoseSnapshot {
        var points: [HandJointName: HandPoint] = [
            .wrist: HandPoint(x: 0.50, y: 0.10, confidence: confidence),
            .thumbCMC: HandPoint(x: 0.38, y: 0.28, confidence: confidence),
            .thumbMP: HandPoint(x: 0.34, y: 0.38, confidence: confidence),
            .thumbIP: HandPoint(x: 0.30, y: 0.48, confidence: confidence),
            .indexMCP: HandPoint(x: 0.44, y: 0.40, confidence: confidence),
            .indexPIP: HandPoint(x: 0.47, y: 0.58, confidence: confidence),
            .indexDIP: HandPoint(x: 0.49, y: 0.72, confidence: confidence),
            .middleMCP: HandPoint(x: 0.52, y: 0.40, confidence: confidence),
            .middlePIP: HandPoint(x: 0.52, y: 0.60, confidence: confidence),
            .middleDIP: HandPoint(x: 0.52, y: 0.74, confidence: confidence),
            .ringMCP: HandPoint(x: 0.60, y: 0.38, confidence: confidence),
            .ringPIP: HandPoint(x: 0.62, y: 0.58, confidence: confidence),
            .ringDIP: HandPoint(x: 0.63, y: 0.70, confidence: confidence),
            .littleMCP: HandPoint(x: 0.68, y: 0.34, confidence: confidence),
            .littlePIP: HandPoint(x: 0.72, y: 0.52, confidence: confidence),
            .littleDIP: HandPoint(x: 0.74, y: 0.66, confidence: confidence)
        ]
        for (joint, point) in tips {
            points[joint] = point
        }
        return HandPoseSnapshot(points: points, handedness: handedness, timestamp: timestamp)
    }
}
