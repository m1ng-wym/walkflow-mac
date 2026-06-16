import Foundation

public struct RecognitionMetrics: Equatable, Sendable {
    private var totalByGesture: [GestureKind: Int] = [:]
    private var correctByGesture: [GestureKind: Int] = [:]
    public private(set) var falseTriggerCount = 0

    public init() {}

    public mutating func record(expected: GestureKind, actual: GestureKind) {
        totalByGesture[expected, default: 0] += 1
        if expected == actual {
            correctByGesture[expected, default: 0] += 1
        }
        if expected == .none, [.indexUp, .indexDown, .okPinch].contains(actual) {
            falseTriggerCount += 1
        }
    }

    public func accuracy(for gesture: GestureKind) -> Double {
        guard let total = totalByGesture[gesture], total > 0 else {
            return 0
        }
        return Double(correctByGesture[gesture, default: 0]) / Double(total)
    }
}
