import Foundation

public struct GestureClassifier {
    private let minimumJointConfidence: Double
    private let pinchDistanceThreshold: Double

    public init(minimumJointConfidence: Double = 0.45, pinchDistanceThreshold: Double = 0.08) {
        self.minimumJointConfidence = minimumJointConfidence
        self.pinchDistanceThreshold = pinchDistanceThreshold
    }

    public func classify(_ snapshot: HandPoseSnapshot?) -> GestureObservation {
        classify(snapshot, timestamp: snapshot?.timestamp ?? 0)
    }

    public func classify(_ snapshot: HandPoseSnapshot?, timestamp: TimeInterval) -> GestureObservation {
        guard let snapshot else {
            return .init(kind: .handLost, confidence: 0, timestamp: timestamp)
        }

        let hasFullConfidence = hasRequiredConfidence(snapshot)

        if hasFullConfidence {
            if isOKPinch(snapshot) {
                return .init(kind: .okPinch, confidence: 1, timestamp: snapshot.timestamp)
            }
            if isOpenPalm(snapshot) {
                return .init(kind: .openPalm, confidence: 1, timestamp: snapshot.timestamp)
            }
            if isIndexDirection(snapshot, up: true) {
                return .init(kind: .indexUp, confidence: 1, timestamp: snapshot.timestamp)
            }
        }
        if isIndexDirection(snapshot, up: false) {
            return .init(kind: .indexDown, confidence: 1, timestamp: snapshot.timestamp)
        }
        guard hasFullConfidence else {
            return .init(kind: .handLost, confidence: 0, timestamp: snapshot.timestamp)
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

    private func hasConfidence(_ snapshot: HandPoseSnapshot, joints: [HandJointName]) -> Bool {
        joints.allSatisfy { snapshot[$0]?.confidence ?? 0 >= minimumJointConfidence }
    }

    private func isOpenPalm(_ snapshot: HandPoseSnapshot) -> Bool {
        isExtended(snapshot, tip: .indexTip, pip: .indexPIP, mcp: .indexMCP)
            && isExtended(snapshot, tip: .middleTip, pip: .middlePIP, mcp: .middleMCP)
            && isExtended(snapshot, tip: .ringTip, pip: .ringPIP, mcp: .ringMCP)
            && isExtended(snapshot, tip: .littleTip, pip: .littlePIP, mcp: .littleMCP)
            && thumbIsAwayFromPalm(snapshot)
    }

    private func isIndexDirection(_ snapshot: HandPoseSnapshot, up: Bool) -> Bool {
        guard hasConfidence(snapshot, joints: [
            .wrist, .indexMCP, .indexPIP, .indexTip,
            .middleMCP, .middlePIP,
            .ringMCP, .ringPIP,
            .littleMCP, .littlePIP
        ]) else {
            return false
        }

        if up {
            guard isCurled(snapshot, tip: .middleTip, pip: .middlePIP, mcp: .middleMCP),
                  isCurled(snapshot, tip: .ringTip, pip: .ringPIP, mcp: .ringMCP),
                  isCurled(snapshot, tip: .littleTip, pip: .littlePIP, mcp: .littleMCP) else {
                return false
            }
        } else {
            let companionFingerCount = [
                isFoldedOrOccluded(snapshot, tip: .middleTip, pip: .middlePIP, mcp: .middleMCP),
                isFoldedOrOccluded(snapshot, tip: .ringTip, pip: .ringPIP, mcp: .ringMCP),
                isFoldedOrOccluded(snapshot, tip: .littleTip, pip: .littlePIP, mcp: .littleMCP)
            ].filter { $0 }.count
            guard companionFingerCount >= 2 else {
                return false
            }
        }

        guard let tip = snapshot[.indexTip],
              let pip = snapshot[.indexPIP],
              let mcp = snapshot[.indexMCP] else {
            return false
        }
        let indexExtended = up ? (tip.y > pip.y && pip.y > mcp.y) : (tip.y < pip.y && tip.y < mcp.y)
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

    private func isFoldedOrOccluded(_ snapshot: HandPoseSnapshot, tip: HandJointName, pip: HandJointName, mcp: HandJointName) -> Bool {
        guard hasConfidence(snapshot, joints: [pip, mcp]),
              let tipPoint = snapshot[tip] else {
            return false
        }
        if tipPoint.confidence < minimumJointConfidence {
            return true
        }
        return isCurled(snapshot, tip: tip, pip: pip, mcp: mcp)
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
