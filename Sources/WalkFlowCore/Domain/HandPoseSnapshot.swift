import Foundation

public enum HandJointName: String, CaseIterable, Sendable {
    case wrist
    case thumbCMC
    case thumbMP
    case thumbIP
    case thumbTip
    case indexMCP
    case indexPIP
    case indexDIP
    case indexTip
    case middleMCP
    case middlePIP
    case middleDIP
    case middleTip
    case ringMCP
    case ringPIP
    case ringDIP
    case ringTip
    case littleMCP
    case littlePIP
    case littleDIP
    case littleTip
}

public struct HandPoint: Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var confidence: Double

    public init(x: Double, y: Double, confidence: Double) {
        self.x = x
        self.y = y
        self.confidence = confidence
    }
}

public enum Handedness: Equatable, Sendable {
    case left
    case right
    case unknown
}

public struct HandPoseSnapshot: Equatable, Sendable {
    public var points: [HandJointName: HandPoint]
    public var handedness: Handedness
    public var timestamp: TimeInterval

    public init(points: [HandJointName: HandPoint], handedness: Handedness, timestamp: TimeInterval) {
        self.points = points
        self.handedness = handedness
        self.timestamp = timestamp
    }

    public subscript(_ joint: HandJointName) -> HandPoint? {
        points[joint]
    }
}
