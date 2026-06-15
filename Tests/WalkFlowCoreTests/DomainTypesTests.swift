import XCTest
@testable import WalkFlowCore

final class DomainTypesTests: XCTestCase {
    func testDefaultTimingMatchesGestureContract() {
        XCTAssertEqual(AppSettings.defaults.gestureTiming.readyHoldMilliseconds, 300)
        XCTAssertEqual(AppSettings.defaults.gestureTiming.scrollHoldMilliseconds, 300)
        XCTAssertEqual(AppSettings.defaults.gestureTiming.continuousScrollHoldMilliseconds, 700)
        XCTAssertEqual(AppSettings.defaults.gestureTiming.commandHoldMilliseconds, 300)
        XCTAssertEqual(AppSettings.defaults.gestureTiming.commandCooldownMilliseconds, 1000)
        XCTAssertEqual(AppSettings.defaults.gestureTiming.controlWindowSeconds, 5.0)
    }

    func testPermissionsRequireCameraAndAccessibilityToControl() {
        XCTAssertTrue(PermissionSnapshot(camera: .granted, accessibility: .granted, inputMonitoring: .notRequired).canControl)
        XCTAssertFalse(PermissionSnapshot(camera: .denied, accessibility: .granted, inputMonitoring: .notRequired).canControl)
        XCTAssertFalse(PermissionSnapshot(camera: .granted, accessibility: .denied, inputMonitoring: .notRequired).canControl)
    }

    func testHUDPresentationCanRepresentStandbyAndPermissionBlock() {
        XCTAssertEqual(HUDPresentation(dot: .green, icon: .none, message: "Standby").icon, .none)
        XCTAssertEqual(HUDPresentation(dot: .red, icon: .alertTriangle, message: "Permission").dot, .red)
    }
}
