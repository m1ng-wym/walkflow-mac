import Foundation
import WalkFlowCore

final class AppStateStore {
    var isEnabled = true
    var isPaused = false
    var settings = AppSettings.defaults
    var permissions = PermissionSnapshot(camera: .notDetermined, accessibility: .denied, inputMonitoring: .notRequired)
    var latestHUD = HUDPresentation(dot: .green, icon: .none, message: "Standby")
}
