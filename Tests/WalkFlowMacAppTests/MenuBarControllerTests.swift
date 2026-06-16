import AppKit
import AVFoundation
import XCTest
@testable import WalkFlowCore
@testable import WalkFlowMacApp

final class MenuBarControllerTests: XCTestCase {
    func testMenuContainsRequiredActions() {
        XCTAssertEqual(
            MenuBarController.requiredMenuTitles,
            ["Enable", "Pause", "Show HUD", "Open Window", "Settings", "Quit"]
        )
    }

    func testInstalledMenuContainsRequiredActions() {
        let controller = makeMenuController()

        XCTAssertEqual(controller.installedMenuTitles, MenuBarController.requiredMenuTitles)
    }

    func testEnableAndPauseMenuItemsUpdateAppController() throws {
        let appController = makeAppController()
        appController.setEnabled(false)
        let controller = makeMenuController(appController: appController)

        try performMenuItem(titled: "Enable", in: controller)
        try performMenuItem(titled: "Pause", in: controller)

        XCTAssertTrue(appController.state.isEnabled)
        XCTAssertTrue(appController.state.isPaused)
    }

    func testEnableMenuItemTogglesHardSwitch() throws {
        let appController = makeAppController()
        let controller = makeMenuController(appController: appController)

        try performMenuItem(titled: "Enable", in: controller)
        XCTAssertFalse(appController.state.isEnabled)

        try performMenuItem(titled: "Enable", in: controller)
        XCTAssertTrue(appController.state.isEnabled)
    }

    func testPauseMenuItemTogglesPauseAndResume() throws {
        let appController = makeAppController()
        let controller = makeMenuController(appController: appController)

        try performMenuItem(titled: "Pause", in: controller)
        XCTAssertTrue(appController.state.isPaused)

        try performMenuItem(titled: "Pause", in: controller)
        XCTAssertFalse(appController.state.isPaused)
    }

    private func makeMenuController(appController: AppController? = nil) -> MenuBarController {
        let appController = appController ?? makeAppController()
        return MenuBarController(
            appController: appController,
            mainWindowController: MainWindowController(appController: appController),
            hudWindowController: HUDWindowController(settingsStore: SettingsStore(defaults: makeDefaults()))
        )
    }

    private func makeAppController() -> AppController {
        AppController(
            settingsStore: MenuBarFakeSettingsStore(),
            permissions: MenuBarFakePermissionService(snapshot: PermissionSnapshot(camera: .granted, accessibility: .granted, inputMonitoring: .notRequired)),
            camera: MenuBarFakeCameraController(),
            eventOutput: MenuBarRecordingControlEventOutput()
        )
    }

    private func performMenuItem(titled title: String, in controller: MenuBarController) throws {
        let menu = try XCTUnwrap(controller.statusItem.menu)
        let item = try XCTUnwrap(menu.items.first { $0.title == title })
        let action = try XCTUnwrap(item.action)
        XCTAssertTrue(NSApp.sendAction(action, to: item.target, from: item))
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "WalkFlowMac.MenuBarControllerTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}

private final class MenuBarFakeSettingsStore: SettingsStoring {
    func load() -> AppSettings { .defaults }
    func save(_ settings: AppSettings) {}
}

private final class MenuBarFakePermissionService: PermissionServicing {
    let snapshotValue: PermissionSnapshot

    init(snapshot: PermissionSnapshot) {
        snapshotValue = snapshot
    }

    func snapshot() -> PermissionSnapshot {
        snapshotValue
    }

    func requestCameraAccess(completion: @escaping (Bool) -> Void) {
        completion(false)
    }

    func promptForAccessibility() {}
}

private final class MenuBarFakeCameraController: CameraControlling {
    let session = AVCaptureSession()
    weak var consumer: CameraFrameConsumer?

    func configure() throws {}
    func start() {}
    func stop() {}
}

private final class MenuBarRecordingControlEventOutput: ControlEventOutput {
    func execute(_ action: ControlAction, scrollSettings: ScrollSettings) {}
}
