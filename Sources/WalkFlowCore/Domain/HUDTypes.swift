import Foundation

public enum HUDDot: Equatable, Sendable {
    case red
    case green
}

public enum HUDIcon: Equatable, Sendable {
    case none
    case lock
    case unlockOnce
    case alertTriangle
    case infinity
    case arrowUp
    case arrowDown
    case dribbble
}

public struct HUDPresentation: Equatable, Sendable {
    public var dot: HUDDot
    public var icon: HUDIcon
    public var message: String

    public init(dot: HUDDot, icon: HUDIcon, message: String) {
        self.dot = dot
        self.icon = icon
        self.message = message
    }
}
