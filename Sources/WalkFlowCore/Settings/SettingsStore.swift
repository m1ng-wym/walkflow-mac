import Foundation

public final class SettingsStore {
    private enum Key {
        static let readyHoldMilliseconds = "gesture.readyHoldMilliseconds"
        static let scrollHoldMilliseconds = "gesture.scrollHoldMilliseconds"
        static let continuousScrollHoldMilliseconds = "gesture.continuousScrollHoldMilliseconds"
        static let commandHoldMilliseconds = "gesture.commandHoldMilliseconds"
        static let commandCooldownMilliseconds = "gesture.commandCooldownMilliseconds"
        static let controlWindowSeconds = "gesture.controlWindowSeconds"
        static let singleStepDeltaY = "scroll.singleStepDeltaY"
        static let continuousDeltaY = "scroll.continuousDeltaY"
        static let continuousIntervalMilliseconds = "scroll.continuousIntervalMilliseconds"
        static let hudPinned = "hud.isPinned"
        static let hudVisible = "hud.isVisible"
        static let hudSavedOriginX = "hud.savedOriginX"
        static let hudSavedOriginY = "hud.savedOriginY"
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> AppSettings {
        var settings = AppSettings.defaults
        settings.gestureTiming.readyHoldMilliseconds = int(for: Key.readyHoldMilliseconds, default: settings.gestureTiming.readyHoldMilliseconds)
        settings.gestureTiming.scrollHoldMilliseconds = int(for: Key.scrollHoldMilliseconds, default: settings.gestureTiming.scrollHoldMilliseconds)
        settings.gestureTiming.continuousScrollHoldMilliseconds = int(for: Key.continuousScrollHoldMilliseconds, default: settings.gestureTiming.continuousScrollHoldMilliseconds)
        settings.gestureTiming.commandHoldMilliseconds = int(for: Key.commandHoldMilliseconds, default: settings.gestureTiming.commandHoldMilliseconds)
        settings.gestureTiming.commandCooldownMilliseconds = int(for: Key.commandCooldownMilliseconds, default: settings.gestureTiming.commandCooldownMilliseconds)
        settings.gestureTiming.controlWindowSeconds = double(for: Key.controlWindowSeconds, default: settings.gestureTiming.controlWindowSeconds)
        settings.scroll.singleStepDeltaY = Int32(int(for: Key.singleStepDeltaY, default: Int(settings.scroll.singleStepDeltaY)))
        settings.scroll.continuousDeltaY = Int32(int(for: Key.continuousDeltaY, default: Int(settings.scroll.continuousDeltaY)))
        settings.scroll.continuousIntervalMilliseconds = int(for: Key.continuousIntervalMilliseconds, default: settings.scroll.continuousIntervalMilliseconds)
        settings.hud.isPinned = bool(for: Key.hudPinned, default: settings.hud.isPinned)
        settings.hud.isVisible = bool(for: Key.hudVisible, default: settings.hud.isVisible)
        settings.hud.savedOriginX = optionalDouble(for: Key.hudSavedOriginX)
        settings.hud.savedOriginY = optionalDouble(for: Key.hudSavedOriginY)
        return settings
    }

    public func save(_ settings: AppSettings) {
        defaults.set(settings.gestureTiming.readyHoldMilliseconds, forKey: Key.readyHoldMilliseconds)
        defaults.set(settings.gestureTiming.scrollHoldMilliseconds, forKey: Key.scrollHoldMilliseconds)
        defaults.set(settings.gestureTiming.continuousScrollHoldMilliseconds, forKey: Key.continuousScrollHoldMilliseconds)
        defaults.set(settings.gestureTiming.commandHoldMilliseconds, forKey: Key.commandHoldMilliseconds)
        defaults.set(settings.gestureTiming.commandCooldownMilliseconds, forKey: Key.commandCooldownMilliseconds)
        defaults.set(settings.gestureTiming.controlWindowSeconds, forKey: Key.controlWindowSeconds)
        defaults.set(Int(settings.scroll.singleStepDeltaY), forKey: Key.singleStepDeltaY)
        defaults.set(Int(settings.scroll.continuousDeltaY), forKey: Key.continuousDeltaY)
        defaults.set(settings.scroll.continuousIntervalMilliseconds, forKey: Key.continuousIntervalMilliseconds)
        defaults.set(settings.hud.isPinned, forKey: Key.hudPinned)
        defaults.set(settings.hud.isVisible, forKey: Key.hudVisible)
        defaults.set(settings.hud.savedOriginX, forKey: Key.hudSavedOriginX)
        defaults.set(settings.hud.savedOriginY, forKey: Key.hudSavedOriginY)
    }

    private func int(for key: String, default defaultValue: Int) -> Int {
        defaults.object(forKey: key) == nil ? defaultValue : defaults.integer(forKey: key)
    }

    private func double(for key: String, default defaultValue: Double) -> Double {
        defaults.object(forKey: key) == nil ? defaultValue : defaults.double(forKey: key)
    }

    private func optionalDouble(for key: String) -> Double? {
        defaults.object(forKey: key) == nil ? nil : defaults.double(forKey: key)
    }

    private func bool(for key: String, default defaultValue: Bool) -> Bool {
        defaults.object(forKey: key) == nil ? defaultValue : defaults.bool(forKey: key)
    }
}
