import Foundation

public struct GestureTimingSettings: Equatable, Sendable {
    public var readyHoldMilliseconds: Int
    public var scrollHoldMilliseconds: Int
    public var continuousScrollHoldMilliseconds: Int
    public var commandHoldMilliseconds: Int
    public var commandCooldownMilliseconds: Int
    public var controlWindowSeconds: Double

    public static let defaults = GestureTimingSettings(
        readyHoldMilliseconds: 300,
        scrollHoldMilliseconds: 300,
        continuousScrollHoldMilliseconds: 700,
        commandHoldMilliseconds: 300,
        commandCooldownMilliseconds: 1000,
        controlWindowSeconds: 5.0
    )
}

public struct ScrollSettings: Equatable, Sendable {
    public var singleStepDeltaY: Int32
    public var continuousDeltaY: Int32
    public var continuousIntervalMilliseconds: Int

    public static let defaults = ScrollSettings(
        singleStepDeltaY: 6,
        continuousDeltaY: 3,
        continuousIntervalMilliseconds: 80
    )
}

public struct HUDSettings: Equatable, Sendable {
    public var isPinned: Bool
    public var isVisible: Bool
    public var savedOriginX: Double?
    public var savedOriginY: Double?

    public static let defaults = HUDSettings(
        isPinned: true,
        isVisible: true,
        savedOriginX: nil,
        savedOriginY: nil
    )
}

public struct AppSettings: Equatable, Sendable {
    public var gestureTiming: GestureTimingSettings
    public var scroll: ScrollSettings
    public var hud: HUDSettings

    public static let defaults = AppSettings(
        gestureTiming: .defaults,
        scroll: .defaults,
        hud: .defaults
    )
}
