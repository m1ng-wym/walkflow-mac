import Foundation

public struct HUDStateReducer {
    public init() {}

    public func presentation(
        isEnabled: Bool,
        isPaused: Bool,
        permissions: PermissionSnapshot,
        stateOutput: GestureStateOutput
    ) -> HUDPresentation {
        if isEnabled == false {
            return .init(dot: .red, icon: .lock, message: "Disabled")
        }

        if permissions.canControl == false {
            return .init(dot: .red, icon: .alertTriangle, message: "Permission")
        }

        if isPaused {
            return .init(dot: .green, icon: .none, message: "Paused")
        }

        return stateOutput.hud
    }
}
