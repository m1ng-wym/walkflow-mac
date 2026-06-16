import AppKit
import AVFoundation
import XCTest
@testable import WalkFlowCore
@testable import WalkFlowMacApp

final class MainWindowControllerTests: XCTestCase {
    func testMainWindowUsesSplitLayoutWithOneToFourRatio() throws {
        let controller = MainWindowController(appController: makeController())
        let window = try XCTUnwrap(controller.window)
        let split = try XCTUnwrap(window.contentView as? NSSplitView)

        XCTAssertEqual(window.title, "WalkFlow-Mac")
        XCTAssertTrue(split.isVertical)
        XCTAssertEqual(split.arrangedSubviews.count, 2)

        let left = split.arrangedSubviews[0]
        let width = left.constraints.first { constraint in
            constraint.firstAttribute == .width && constraint.relation == .equal
        }
        XCTAssertEqual(width?.constant, 220)
    }

    func testPreviewPaneContainsCameraPreviewView() throws {
        let controller = MainWindowController(appController: makeController())
        let window = try XCTUnwrap(controller.window)
        let split = try XCTUnwrap(window.contentView as? NSSplitView)
        let previewContainer = try XCTUnwrap(split.arrangedSubviews.last as? PreviewContainerView)

        XCTAssertTrue(previewContainer.subviews.contains { $0 is CameraPreviewView })
    }

    func testPreviewPaneAttachesAppControllerCameraSession() throws {
        let camera = MainWindowFakeCameraController()
        let controller = MainWindowController(appController: makeController(camera: camera))
        let window = try XCTUnwrap(controller.window)
        let split = try XCTUnwrap(window.contentView as? NSSplitView)
        let previewContainer = try XCTUnwrap(split.arrangedSubviews.last as? PreviewContainerView)
        let previewView = try XCTUnwrap(previewContainer.subviews.compactMap { $0 as? CameraPreviewView }.first)

        XCTAssertTrue(previewView.previewLayer.session === camera.session)
    }

    func testControlPanelButtonsDriveAppControllerState() throws {
        let appController = makeController()
        let controlPanel = try controlPanel(from: MainWindowController(appController: appController))

        try button(titled: "Enable", in: controlPanel).performClick(nil)
        try button(titled: "Pause", in: controlPanel).performClick(nil)

        XCTAssertFalse(appController.state.isEnabled)
        XCTAssertTrue(appController.state.isPaused)
    }

    func testPermissionPanelRecheckRefreshesPermissionSnapshot() throws {
        let permissions = MainWindowFakePermissionService(snapshot: PermissionSnapshot(camera: .denied, accessibility: .granted, inputMonitoring: .notRequired))
        let appController = makeController(permissions: permissions)
        let controlPanel = try controlPanel(from: MainWindowController(appController: appController))

        permissions.snapshotValue = PermissionSnapshot(camera: .granted, accessibility: .granted, inputMonitoring: .notRequired)
        try button(titled: "Recheck", in: controlPanel).performClick(nil)

        XCTAssertEqual(appController.state.permissions.camera, .granted)
        XCTAssertTrue(appController.state.permissions.canControl)
    }

    private func makeController() -> AppController {
        makeController(
            permissions: MainWindowFakePermissionService(snapshot: PermissionSnapshot(camera: .granted, accessibility: .granted, inputMonitoring: .notRequired))
        )
    }

    private func makeController(permissions: MainWindowFakePermissionService) -> AppController {
        makeController(permissions: permissions, camera: MainWindowFakeCameraController())
    }

    private func makeController(camera: MainWindowFakeCameraController) -> AppController {
        makeController(
            permissions: MainWindowFakePermissionService(snapshot: PermissionSnapshot(camera: .granted, accessibility: .granted, inputMonitoring: .notRequired)),
            camera: camera
        )
    }

    private func makeController(
        permissions: MainWindowFakePermissionService,
        camera: MainWindowFakeCameraController
    ) -> AppController {
        AppController(
            settingsStore: MainWindowFakeSettingsStore(),
            permissions: permissions,
            camera: camera,
            eventOutput: MainWindowRecordingControlEventOutput()
        )
    }

    private func controlPanel(from controller: MainWindowController) throws -> ControlPanelView {
        let window = try XCTUnwrap(controller.window)
        let split = try XCTUnwrap(window.contentView as? NSSplitView)
        return try XCTUnwrap(split.arrangedSubviews.first as? ControlPanelView)
    }

    private func button(titled title: String, in view: NSView) throws -> NSButton {
        try XCTUnwrap(findButton(titled: title, in: view), "Missing button titled \(title)")
    }

    private func findButton(titled title: String, in view: NSView) -> NSButton? {
        if let button = view as? NSButton, button.title == title {
            return button
        }

        let children: [NSView]
        if let stack = view as? NSStackView {
            children = stack.arrangedSubviews + stack.subviews
        } else {
            children = view.subviews
        }

        for subview in children {
            if let button = findButton(titled: title, in: subview) {
                return button
            }
        }

        return nil
    }
}

private final class MainWindowFakeSettingsStore: SettingsStoring {
    func load() -> AppSettings { .defaults }
    func save(_ settings: AppSettings) {}
}

private final class MainWindowFakePermissionService: PermissionServicing {
    var snapshotValue: PermissionSnapshot

    init(snapshot: PermissionSnapshot) {
        snapshotValue = snapshot
    }

    func snapshot() -> PermissionSnapshot {
        snapshotValue
    }

    func requestCameraAccess(completion: @escaping (Bool) -> Void) {
        completion(false)
    }
}

private final class MainWindowFakeCameraController: CameraControlling {
    let session = AVCaptureSession()
    weak var consumer: CameraFrameConsumer?

    func configure() throws {}
    func start() {}
    func stop() {}
}

private final class MainWindowRecordingControlEventOutput: ControlEventOutput {
    func execute(_ action: ControlAction, scrollSettings: ScrollSettings) {}
}
