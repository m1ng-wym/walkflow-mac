import AppKit
import AVFoundation
import XCTest
@testable import WalkFlowCore
@testable import WalkFlowMacApp

final class ApplicationMenuControllerTests: XCTestCase {
    private var previousMainMenu: NSMenu?

    override func setUp() {
        super.setUp()
        previousMainMenu = NSApplication.shared.mainMenu
    }

    override func tearDown() {
        NSApplication.shared.mainMenu = previousMainMenu
        previousMainMenu = nil
        super.tearDown()
    }

    func testInstallCreatesStandardApplicationMenus() throws {
        let appController = makeAppController()
        let mainWindow = MainWindowController(appController: appController)
        let controller = ApplicationMenuController(mainWindowController: mainWindow)

        controller.install()

        let mainMenu = try XCTUnwrap(NSApplication.shared.mainMenu)
        XCTAssertEqual(mainMenu.items.map(\.title), ["WalkFlow-Mac", "File", "Window"])
    }

    func testApplicationMenuInstallsHideAndQuitShortcuts() throws {
        let appController = makeAppController()
        let mainWindow = MainWindowController(appController: appController)
        let controller = ApplicationMenuController(mainWindowController: mainWindow)

        controller.install()

        try assertMenuItem(
            title: "Hide WalkFlow-Mac",
            inTopLevelMenu: "WalkFlow-Mac",
            keyEquivalent: "h",
            action: #selector(ApplicationMenuController.hideApplication(_:)),
            target: controller
        )
        try assertMenuItem(
            title: "Quit WalkFlow-Mac",
            inTopLevelMenu: "WalkFlow-Mac",
            keyEquivalent: "q",
            action: #selector(ApplicationMenuController.quitApplication(_:)),
            target: controller
        )
    }

    func testWindowMenusInstallCloseAndMinimizeShortcuts() throws {
        let appController = makeAppController()
        let mainWindow = MainWindowController(appController: appController)
        let controller = ApplicationMenuController(mainWindowController: mainWindow)

        controller.install()

        try assertMenuItem(
            title: "Close Window",
            inTopLevelMenu: "File",
            keyEquivalent: "w",
            action: #selector(ApplicationMenuController.closeMainWindow(_:)),
            target: controller
        )
        try assertMenuItem(
            title: "Minimize",
            inTopLevelMenu: "Window",
            keyEquivalent: "m",
            action: #selector(ApplicationMenuController.minimizeMainWindow(_:)),
            target: controller
        )
    }

    private func assertMenuItem(
        title: String,
        inTopLevelMenu topLevelTitle: String,
        keyEquivalent: String,
        action: Selector,
        target: AnyObject,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let mainMenu = try XCTUnwrap(NSApplication.shared.mainMenu, file: file, line: line)
        let topLevelItem = try XCTUnwrap(mainMenu.items.first { $0.title == topLevelTitle }, file: file, line: line)
        let submenu = try XCTUnwrap(topLevelItem.submenu, file: file, line: line)
        let item = try XCTUnwrap(submenu.items.first { $0.title == title }, file: file, line: line)

        XCTAssertEqual(item.keyEquivalent, keyEquivalent, file: file, line: line)
        XCTAssertEqual(item.keyEquivalentModifierMask.intersection(.deviceIndependentFlagsMask), [.command], file: file, line: line)
        XCTAssertEqual(item.action, action, file: file, line: line)
        XCTAssertTrue(item.target === target, file: file, line: line)
    }

    private func makeAppController() -> AppController {
        AppController(
            settingsStore: ApplicationMenuFakeSettingsStore(),
            permissions: ApplicationMenuFakePermissionService(snapshot: PermissionSnapshot(camera: .granted, accessibility: .granted, inputMonitoring: .notRequired)),
            camera: ApplicationMenuFakeCameraController(),
            eventOutput: ApplicationMenuRecordingControlEventOutput()
        )
    }
}

private final class ApplicationMenuFakeSettingsStore: SettingsStoring {
    func load() -> AppSettings { .defaults }
    func save(_ settings: AppSettings) {}
}

private final class ApplicationMenuFakePermissionService: PermissionServicing {
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

private final class ApplicationMenuFakeCameraController: CameraControlling {
    let session = AVCaptureSession()
    weak var consumer: CameraFrameConsumer?

    func configure() throws {}
    func start() {}
    func stop() {}
}

private final class ApplicationMenuRecordingControlEventOutput: ControlEventOutput {
    func execute(_ action: ControlAction, scrollSettings: ScrollSettings) {}
}
