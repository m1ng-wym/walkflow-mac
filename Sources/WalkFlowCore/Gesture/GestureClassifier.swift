import Foundation

public struct GestureClassifier {
    private let minimumJointConfidence: Double
    private let pinchDistanceThreshold: Double

    public init(minimumJointConfidence: Double = 0.45, pinchDistanceThreshold: Double = 0.08) {
        self.minimumJointConfidence = minimumJointConfidence
        self.pinchDistanceThreshold = pinchDistanceThreshold
    }

    public func classify(_ snapshot: HandPoseSnapshot?) -> GestureObservation {
        guard let snapshot else {
            return .init(kind: .handLost, confidence: 0, timestamp: 0)
        }

        guard hasRequiredConfidence(snapshot) else {
            return .init(kind: .handLost, confidence: 0, timestamp: snapshot.timestamp)
        }

        if isOKPinch(snapshot) {
            return .init(kind: .okPinch, confidence: 1, timestamp: snapshot.timestamp)
        }
        if isOpenPalm(snapshot) {
            return .init(kind: .openPalm, confidence: 1, timestamp: snapshot.timestamp)
        }
        if isIndexDirection(snapshot, up: true) {
            return .init(kind: .indexUp, confidence: 1, timestamp: snapshot.timestamp)
        }
        if isIndexDirection(snapshot, up: false) {
            return .init(kind: .indexDown, confidence: 1, timestamp: snapshot.timestamp)
        }
        if isFist(snapshot) {
            return .init(kind: .fist, confidence: 1, timestamp: snapshot.timestamp)
        }
        return .init(kind: .none, confidence: 0.5, timestamp: snapshot.timestamp)
    }

    private func hasRequiredConfidence(_ snapshot: HandPoseSnapshot) -> Bool {
        let required: [HandJointName] = [
            .wrist, .thumbTip, .indexMCP, .indexPIP, .indexTip,
            .middleMCP, .middlePIP, .middleTip,
            .ringMCP, .ringPIP, .ringTip,
            .littleMCP, .littlePIP, .littleTip
        ]
        return required.allSatisfy { snapshot[$0]?.confidence ?? 0 >= minimumJointConfidence }
    }

    private func isOpenPalm(_ snapshot: HandPoseSnapshot) -> Bool {
        isExtended(snapshot, tip: .indexTip, pip: .indexPIP, mcp: .indexMCP)
            && isExtended(snapshot, tip: .middleTip, pip: .middlePIP, mcp: .middleMCP)
            && isExtended(snapshot, tip: .ringTip, pip: .ringPIP, mcp: .ringMCP)
            && isExtended(snapshot, tip: .littleTip, pip: .littlePIP, mcp: .littleMCP)
            && thumbIsAwayFromPalm(snapshot)
    }

    private func isIndexDirection(_ snapshot: HandPoseSnapshot, up: Bool) -> Bool {
        guard isCurled(snapshot, tip: .middleTip, pip: .middlePIP, mcp: .middleMCP),
              isCurled(snapshot, tip: .ringTip, pip: .ringPIP, mcp: .ringMCP),
              isCurled(snapshot, tip: .littleTip, pip: .littlePIP, mcp: .littleMCP),
              let tip = snapshot[.indexTip],
              let pip = snapshot[.indexPIP],
              let mcp = snapshot[.indexMCP] else {
            return false
        }
        let indexExtended = up ? (tip.y > pip.y && pip.y > mcp.y) : (tip.y < pip.y && pip.y < mcp.y)
        guard indexExtended else {
            return false
        }
        return up ? tip.y > mcp.y + 0.25 : tip.y < mcp.y - 0.25
    }

    private func isFist(_ snapshot: HandPoseSnapshot) -> Bool {
        isCurled(snapshot, tip: .indexTip, pip: .indexPIP, mcp: .indexMCP)
            && isCurled(snapshot, tip: .middleTip, pip: .middlePIP, mcp: .middleMCP)
            && isCurled(snapshot, tip: .ringTip, pip: .ringPIP, mcp: .ringMCP)
            && isCurled(snapshot, tip: .littleTip, pip: .littlePIP, mcp: .littleMCP)
    }

    private func isOKPinch(_ snapshot: HandPoseSnapshot) -> Bool {
        guard let thumbTip = snapshot[.thumbTip],
              let indexTip = snapshot[.indexTip] else {
            return false
        }
        let pinched = distance(thumbTip, indexTip) <= pinchDistanceThreshold
        return pinched
            && isExtended(snapshot, tip: .middleTip, pip: .middlePIP, mcp: .middleMCP)
            && isExtended(snapshot, tip: .ringTip, pip: .ringPIP, mcp: .ringMCP)
            && isExtended(snapshot, tip: .littleTip, pip: .littlePIP, mcp: .littleMCP)
    }

    private func isExtended(_ snapshot: HandPoseSnapshot, tip: HandJointName, pip: HandJointName, mcp: HandJointName) -> Bool {
        guard let tip = snapshot[tip], let pip = snapshot[pip], let mcp = snapshot[mcp] else {
            return false
        }
        return tip.y > pip.y && pip.y > mcp.y
    }

    private func isCurled(_ snapshot: HandPoseSnapshot, tip: HandJointName, pip: HandJointName, mcp: HandJointName) -> Bool {
        guard let tip = snapshot[tip], let pip = snapshot[pip], let mcp = snapshot[mcp] else {
            return false
        }
        return tip.y <= pip.y || distance(tip, mcp) < distance(pip, mcp)
    }

    private func thumbIsAwayFromPalm(_ snapshot: HandPoseSnapshot) -> Bool {
        guard let thumbTip = snapshot[.thumbTip], let indexMCP = snapshot[.indexMCP] else {
            return false
        }
        return distance(thumbTip, indexMCP) > 0.12
    }

    private func distance(_ a: HandPoint, _ b: HandPoint) -> Double {
        hypot(a.x - b.x, a.y - b.y)
    }
}
