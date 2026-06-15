import XCTest
@testable import WalkFlowCore

final class HUDStateReducerTests: XCTestCase {
    func testPermissionBlockShowsRedAlert() {
        let reducer = HUDStateReducer()
        let hud = reducer.presentation(
            isEnabled: true,
            isPaused: false,
            permissions: .init(camera: .denied, accessibility: .granted, inputMonitoring: .notRequired),
            stateOutput: .init(mode: .standby, action: .none, hud: .init(dot: .green, icon: .none, message: "Standby"))
        )
        XCTAssertEqual(hud.dot, .red)
        XCTAssertEqual(hud.icon, .alertTriangle)
    }

    func testDisabledShowsLock() {
        let reducer = HUDStateReducer()
        let hud = reducer.presentation(
            isEnabled: false,
            isPaused: false,
            permissions: .init(camera: .granted, accessibility: .granted, inputMonitoring: .notRequired),
            stateOutput: .init(mode: .standby, action: .none, hud: .init(dot: .green, icon: .none, message: "Standby"))
        )
        XCTAssertEqual(hud.dot, .red)
        XCTAssertEqual(hud.icon, .lock)
    }

    func testStandbyStaysEmptyGreen() {
        let reducer = HUDStateReducer()
        let hud = reducer.presentation(
            isEnabled: true,
            isPaused: false,
            permissions: .init(camera: .granted, accessibility: .granted, inputMonitoring: .notRequired),
            stateOutput: .init(mode: .standby, action: .none, hud: .init(dot: .green, icon: .none, message: "Standby"))
        )
        XCTAssertEqual(hud.dot, .green)
        XCTAssertEqual(hud.icon, .none)
    }

    func testPausedStaysEmptyGreen() {
        let reducer = HUDStateReducer()
        let hud = reducer.presentation(
            isEnabled: true,
            isPaused: true,
            permissions: .init(camera: .granted, accessibility: .granted, inputMonitoring: .notRequired),
            stateOutput: .init(mode: .ready, action: .none, hud: .init(dot: .green, icon: .infinity, message: "Ready"))
        )
        XCTAssertEqual(hud.dot, .green)
        XCTAssertEqual(hud.icon, .none)
        XCTAssertEqual(hud.message, "Paused")
    }

    func testReadyPassesThroughInfinity() {
        let hud = allowedReducerPresentation(
            .init(mode: .ready, action: .none, hud: .init(dot: .green, icon: .infinity, message: "Ready"))
        )
        XCTAssertEqual(hud.dot, .green)
        XCTAssertEqual(hud.icon, .infinity)
    }

    func testScrollPassesThroughArrow() {
        let up = allowedReducerPresentation(
            .init(mode: .ready, action: .scrollUp(step: .single), hud: .init(dot: .green, icon: .arrowUp, message: "Scroll Up"))
        )
        let down = allowedReducerPresentation(
            .init(mode: .ready, action: .scrollDown(step: .continuous), hud: .init(dot: .green, icon: .arrowDown, message: "Scroll Down"))
        )

        XCTAssertEqual(up.icon, .arrowUp)
        XCTAssertEqual(down.icon, .arrowDown)
    }

    func testCommandPassesThroughDribbble() {
        let hud = allowedReducerPresentation(
            .init(mode: .ready, action: .pressRightCommand, hud: .init(dot: .green, icon: .dribbble, message: "Command"))
        )
        XCTAssertEqual(hud.dot, .green)
        XCTAssertEqual(hud.icon, .dribbble)
    }

    func testHandLostPassesThroughRedDotEmptyIcon() {
        let hud = allowedReducerPresentation(
            .init(mode: .standby, action: .stopContinuousScroll, hud: .init(dot: .red, icon: .none, message: "Hand Lost"))
        )
        XCTAssertEqual(hud.dot, .red)
        XCTAssertEqual(hud.icon, .none)
        XCTAssertEqual(hud.message, "Hand Lost")
    }

    func testStopPassesThroughRedDotEmptyIcon() {
        let hud = allowedReducerPresentation(
            .init(mode: .standby, action: .stopContinuousScroll, hud: .init(dot: .red, icon: .none, message: "Stop"))
        )
        XCTAssertEqual(hud.dot, .red)
        XCTAssertEqual(hud.icon, .none)
        XCTAssertEqual(hud.message, "Stop")
    }

    private func allowedReducerPresentation(_ output: GestureStateOutput) -> HUDPresentation {
        HUDStateReducer().presentation(
            isEnabled: true,
            isPaused: false,
            permissions: .init(camera: .granted, accessibility: .granted, inputMonitoring: .notRequired),
            stateOutput: output
        )
    }
}
