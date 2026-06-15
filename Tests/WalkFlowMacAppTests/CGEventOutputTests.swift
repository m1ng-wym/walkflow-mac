import Carbon.HIToolbox
import CoreGraphics
import XCTest
@testable import WalkFlowCore
@testable import WalkFlowMacApp

final class CGEventOutputTests: XCTestCase {
    func testScrollActionsMapToExpectedDeltasWithoutPostingRealEvents() {
        let poster = RecordingEventPoster()
        let output = CGEventOutput(poster: poster)

        output.execute(.scrollUp(step: .single), scrollSettings: .defaults)
        output.execute(.scrollDown(step: .continuous), scrollSettings: .defaults)

        XCTAssertEqual(poster.events, [
            .scroll(deltaY: ScrollSettings.defaults.singleStepDeltaY),
            .scroll(deltaY: -ScrollSettings.defaults.continuousDeltaY)
        ])
    }

    func testRightCommandPostsRightCommandDownAndUpWithoutPostingRealEvents() {
        let poster = RecordingEventPoster()
        let output = CGEventOutput(poster: poster)

        output.execute(.pressRightCommand, scrollSettings: .defaults)

        XCTAssertEqual(poster.events, [
            .key(keyCode: CGKeyCode(kVK_RightCommand), keyDown: true, flags: .maskCommand),
            .key(keyCode: CGKeyCode(kVK_RightCommand), keyDown: false, flags: [])
        ])
    }

    func testNoOpActionsDoNotPostEvents() {
        let poster = RecordingEventPoster()
        let output = CGEventOutput(poster: poster)

        output.execute(.none, scrollSettings: .defaults)
        output.execute(.stopContinuousScroll, scrollSettings: .defaults)

        XCTAssertTrue(poster.events.isEmpty)
    }
}

private final class RecordingEventPoster: CGEventPosting {
    enum Event: Equatable {
        case scroll(deltaY: Int32)
        case key(keyCode: CGKeyCode, keyDown: Bool, flags: CGEventFlags)
    }

    private(set) var events: [Event] = []

    func postScroll(deltaY: Int32) {
        events.append(.scroll(deltaY: deltaY))
    }

    func postKey(keyCode: CGKeyCode, keyDown: Bool, flags: CGEventFlags) {
        events.append(.key(keyCode: keyCode, keyDown: keyDown, flags: flags))
    }
}
