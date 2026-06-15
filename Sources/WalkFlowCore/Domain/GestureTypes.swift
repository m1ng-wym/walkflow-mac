import Foundation

public enum GestureKind: Equatable, Sendable {
    case none
    case openPalm
    case indexUp
    case indexDown
    case fist
    case okPinch
    case handLost
}

public struct GestureObservation: Equatable, Sendable {
    public var kind: GestureKind
    public var confidence: Double
    public var timestamp: TimeInterval

    public init(kind: GestureKind, confidence: Double, timestamp: TimeInterval) {
        self.kind = kind
        self.confidence = confidence
        self.timestamp = timestamp
    }
}
