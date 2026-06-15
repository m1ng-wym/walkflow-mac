import AppKit
import XCTest
@testable import WalkFlowCore
@testable import WalkFlowMacApp

final class HUDWindowControllerTests: XCTestCase {
    func testFallbackOriginUsesUpperRightOfVisibleFrame() {
        let visibleFrame = NSRect(x: 0, y: 0, width: 1440, height: 900)
        let origin = HUDWindowController.fallbackOrigin(visibleFrame: visibleFrame, panelSize: NSSize(width: 160, height: 110))

        XCTAssertEqual(origin.x, 1260)
        XCTAssertEqual(origin.y, 770)
    }

    func testSavedOriginIsRejectedWhenPanelWouldBeOffScreen() {
        let visibleFrame = NSRect(x: 0, y: 0, width: 1440, height: 900)
        let origin = HUDWindowController.restoredOrigin(
            saved: NSPoint(x: 3000, y: 3000),
            visibleFrames: [visibleFrame],
            panelSize: NSSize(width: 160, height: 110)
        )

        XCTAssertEqual(origin, HUDWindowController.fallbackOrigin(visibleFrame: visibleFrame, panelSize: NSSize(width: 160, height: 110)))
    }

    func testSavedOriginIsRejectedWhenPanelWouldBePartiallyOffScreen() {
        let visibleFrame = NSRect(x: 0, y: 0, width: 1440, height: 900)
        let panelSize = NSSize(width: 160, height: 110)
        let origin = HUDWindowController.restoredOrigin(
            saved: NSPoint(x: 1439, y: 899),
            visibleFrames: [visibleFrame],
            panelSize: panelSize
        )

        XCTAssertEqual(origin, HUDWindowController.fallbackOrigin(visibleFrame: visibleFrame, panelSize: panelSize))
    }

    func testPanelIsConfiguredAsPinnedFloatingHUD() throws {
        let controller = HUDWindowController(settingsStore: SettingsStore(defaults: try makeDefaults()))
        let panel = try XCTUnwrap(controller.window as? NSPanel)

        XCTAssertTrue(panel.styleMask.contains(.nonactivatingPanel))
        XCTAssertEqual(panel.level, .floating)
        XCTAssertFalse(panel.isOpaque)
        XCTAssertEqual(panel.backgroundColor, .clear)
        XCTAssertTrue(panel.hasShadow)
        XCTAssertTrue(panel.isMovableByWindowBackground)
        XCTAssertTrue(panel.collectionBehavior.contains(.canJoinAllSpaces))
        XCTAssertTrue(panel.collectionBehavior.contains(.fullScreenAuxiliary))
    }

    func testWindowDidMovePersistsHUDOrigin() throws {
        let defaults = try makeDefaults()
        let store = SettingsStore(defaults: defaults)
        let controller = HUDWindowController(settingsStore: store)

        controller.window?.setFrameOrigin(NSPoint(x: 234, y: 567))
        controller.windowDidMove(Notification(name: NSWindow.didMoveNotification, object: controller.window))

        let settings = store.load()
        XCTAssertEqual(settings.hud.savedOriginX, 234)
        XCTAssertEqual(settings.hud.savedOriginY, 567)
    }

    private func makeDefaults() throws -> UserDefaults {
        let suiteName = "WalkFlowMac.HUDWindowControllerTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
