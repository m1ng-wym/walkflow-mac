import XCTest
@testable import WalkFlowCore

final class GestureStateMachineTests: XCTestCase {
    func testOpenPalmHeldForReadyThresholdEntersReady() {
        var clock = TestClock(now: 0)
        var machine = GestureStateMachine(settings: .defaults)

        XCTAssertEqual(machine.handle(.init(kind: .openPalm, confidence: 1, timestamp: clock.now)).hud.icon, .none)
        clock.now = 0.31
        let result = machine.handle(.init(kind: .openPalm, confidence: 1, timestamp: clock.now))

        XCTAssertEqual(result.mode, .ready)
        XCTAssertEqual(result.hud.icon, .infinity)
    }

    func testReadyExpiresAfterFiveSecondsWithoutAction() {
        var machine = GestureStateMachine(settings: .defaults)
        _ = machine.handle(.init(kind: .openPalm, confidence: 1, timestamp: 0))
        _ = machine.handle(.init(kind: .openPalm, confidence: 1, timestamp: 0.31))

        let result = machine.handle(.init(kind: .none, confidence: 0, timestamp: 5.32))

        XCTAssertEqual(result.mode, .standby)
        XCTAssertEqual(result.hud.icon, .none)
        XCTAssertEqual(result.hud.dot, .green)
    }

    func testHoldingOpenPalmDoesNotRefreshReadyWindow() {
        var machine = GestureStateMachine(settings: .defaults)
        _ = machine.handle(.init(kind: .openPalm, confidence: 1, timestamp: 0))
        _ = machine.handle(.init(kind: .openPalm, confidence: 1, timestamp: 0.31))

        let expired = machine.handle(.init(kind: .openPalm, confidence: 1, timestamp: 5.32))
        let nextFrame = machine.handle(.init(kind: .openPalm, confidence: 1, timestamp: 5.33))

        XCTAssertEqual(expired.mode, .standby)
        XCTAssertEqual(nextFrame.mode, .standby)
        XCTAssertEqual(nextFrame.hud.icon, .none)
    }

    func testIndexUpTriggersSingleThenContinuousScroll() {
        var machine = readyMachine()

        _ = machine.handle(.init(kind: .indexUp, confidence: 1, timestamp: 1.00))
        let single = machine.handle(.init(kind: .indexUp, confidence: 1, timestamp: 1.31))
        let repeatedBeforeContinuous = machine.handle(.init(kind: .indexUp, confidence: 1, timestamp: 1.40))
        let continuous = machine.handle(.init(kind: .indexUp, confidence: 1, timestamp: 1.72))

        XCTAssertEqual(single.action, .scrollUp(step: .single))
        XCTAssertEqual(repeatedBeforeContinuous.action, .none)
        XCTAssertEqual(continuous.action, .scrollUp(step: .continuous))
        XCTAssertEqual(continuous.hud.icon, .arrowUp)
    }

    func testIndexDownTriggersSingleThenContinuousScroll() {
        var machine = readyMachine()

        _ = machine.handle(.init(kind: .indexDown, confidence: 1, timestamp: 1.00))
        let single = machine.handle(.init(kind: .indexDown, confidence: 1, timestamp: 1.31))
        let repeatedBeforeContinuous = machine.handle(.init(kind: .indexDown, confidence: 1, timestamp: 1.40))
        let continuous = machine.handle(.init(kind: .indexDown, confidence: 1, timestamp: 1.72))

        XCTAssertEqual(single.action, .scrollDown(step: .single))
        XCTAssertEqual(repeatedBeforeContinuous.action, .none)
        XCTAssertEqual(continuous.action, .scrollDown(step: .continuous))
        XCTAssertEqual(continuous.hud.icon, .arrowDown)
    }

    func testGestureChangeStopsContinuousScroll() {
        var machine = readyMachine()
        _ = machine.handle(.init(kind: .indexDown, confidence: 1, timestamp: 1.00))
        _ = machine.handle(.init(kind: .indexDown, confidence: 1, timestamp: 1.72))

        let result = machine.handle(.init(kind: .openPalm, confidence: 1, timestamp: 1.80))

        XCTAssertEqual(result.action, .stopContinuousScroll)
    }

    func testOKPinchTriggersRightCommandOnceUntilReleased() {
        var machine = readyMachine()

        _ = machine.handle(.init(kind: .okPinch, confidence: 1, timestamp: 1.00))
        let first = machine.handle(.init(kind: .okPinch, confidence: 1, timestamp: 1.31))
        let heldAfterCooldown = machine.handle(.init(kind: .okPinch, confidence: 1, timestamp: 2.50))
        let releasedDuringVoiceInput = machine.handle(.init(kind: .openPalm, confidence: 1, timestamp: 2.60))
        _ = machine.handle(.init(kind: .okPinch, confidence: 1, timestamp: 2.70))
        let second = machine.handle(.init(kind: .okPinch, confidence: 1, timestamp: 3.01))

        XCTAssertEqual(first.action, .pressRightCommand)
        XCTAssertEqual(first.hud.icon, .dribbble)
        XCTAssertEqual(heldAfterCooldown.action, .none)
        XCTAssertEqual(releasedDuringVoiceInput.hud.icon, .dribbble)
        XCTAssertEqual(second.action, .pressRightCommand)
        XCTAssertEqual(second.mode, .standby)
        XCTAssertEqual(second.hud.icon, .none)
    }

    func testCommandHUDPersistsPastReadyTimeoutUntilSecondCommand() {
        var machine = readyMachine()

        _ = machine.handle(.init(kind: .okPinch, confidence: 1, timestamp: 1.00))
        let first = machine.handle(.init(kind: .okPinch, confidence: 1, timestamp: 1.31))
        let afterTimeout = machine.handle(.init(kind: .openPalm, confidence: 1, timestamp: 6.50))
        _ = machine.handle(.init(kind: .okPinch, confidence: 1, timestamp: 6.60))
        let second = machine.handle(.init(kind: .okPinch, confidence: 1, timestamp: 6.91))

        XCTAssertEqual(first.action, .pressRightCommand)
        XCTAssertEqual(afterTimeout.mode, .ready)
        XCTAssertEqual(afterTimeout.hud.icon, .dribbble)
        XCTAssertEqual(second.action, .pressRightCommand)
        XCTAssertEqual(second.mode, .standby)
        XCTAssertEqual(second.hud.icon, .none)
    }

    func testVoiceInputActiveSuppressesScrollAndKeepsCommandHUD() {
        var machine = readyMachine()

        _ = machine.handle(.init(kind: .okPinch, confidence: 1, timestamp: 1.00))
        let first = machine.handle(.init(kind: .okPinch, confidence: 1, timestamp: 1.31))
        _ = machine.handle(.init(kind: .openPalm, confidence: 1, timestamp: 1.40))
        _ = machine.handle(.init(kind: .indexUp, confidence: 1, timestamp: 1.50))
        let heldUp = machine.handle(.init(kind: .indexUp, confidence: 1, timestamp: 1.82))
        _ = machine.handle(.init(kind: .indexDown, confidence: 1, timestamp: 1.90))
        let heldDown = machine.handle(.init(kind: .indexDown, confidence: 1, timestamp: 2.22))
        _ = machine.handle(.init(kind: .okPinch, confidence: 1, timestamp: 2.40))
        let second = machine.handle(.init(kind: .okPinch, confidence: 1, timestamp: 2.71))

        XCTAssertEqual(first.action, .pressRightCommand)
        XCTAssertEqual(heldUp.action, .none)
        XCTAssertEqual(heldUp.hud.icon, .dribbble)
        XCTAssertEqual(heldDown.action, .none)
        XCTAssertEqual(heldDown.hud.icon, .dribbble)
        XCTAssertEqual(second.action, .pressRightCommand)
        XCTAssertEqual(second.mode, .standby)
    }

    func testVoiceInputActiveKeepsCommandHUDDuringSecondOKPendingAndCooldown() {
        var machine = readyMachine()

        _ = machine.handle(.init(kind: .okPinch, confidence: 1, timestamp: 1.00))
        let first = machine.handle(.init(kind: .okPinch, confidence: 1, timestamp: 1.31))
        let heldDuringCooldown = machine.handle(.init(kind: .okPinch, confidence: 1, timestamp: 1.50))
        _ = machine.handle(.init(kind: .openPalm, confidence: 1, timestamp: 2.40))
        let secondPending = machine.handle(.init(kind: .okPinch, confidence: 1, timestamp: 2.50))
        let second = machine.handle(.init(kind: .okPinch, confidence: 1, timestamp: 2.81))

        XCTAssertEqual(first.action, .pressRightCommand)
        XCTAssertEqual(heldDuringCooldown.action, .none)
        XCTAssertEqual(heldDuringCooldown.hud.icon, .dribbble)
        XCTAssertEqual(secondPending.action, .none)
        XCTAssertEqual(secondPending.hud.icon, .dribbble)
        XCTAssertEqual(second.action, .pressRightCommand)
        XCTAssertEqual(second.mode, .standby)
        XCTAssertEqual(second.hud.icon, .none)
    }

    func testFistExitsControlWindowWithRedDot() {
        var machine = readyMachine()

        let result = machine.handle(.init(kind: .fist, confidence: 1, timestamp: 1.00))

        XCTAssertEqual(result.mode, .standby)
        XCTAssertEqual(result.action, .stopContinuousScroll)
        XCTAssertEqual(result.hud.dot, .red)
        XCTAssertEqual(result.hud.icon, .none)
    }

    func testHandLostShowsRedDotAndExitsReady() {
        var machine = readyMachine()

        let result = machine.handle(.init(kind: .handLost, confidence: 1, timestamp: 1.00))

        XCTAssertEqual(result.mode, .standby)
        XCTAssertEqual(result.hud.dot, .red)
        XCTAssertEqual(result.hud.icon, .none)
    }

    private func readyMachine() -> GestureStateMachine {
        var machine = GestureStateMachine(settings: .defaults)
        _ = machine.handle(.init(kind: .openPalm, confidence: 1, timestamp: 0))
        _ = machine.handle(.init(kind: .openPalm, confidence: 1, timestamp: 0.31))
        return machine
    }
}

private struct TestClock: Clock {
    var now: TimeInterval
}
