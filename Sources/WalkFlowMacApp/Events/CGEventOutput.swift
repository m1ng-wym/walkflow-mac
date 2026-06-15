import Carbon.HIToolbox
import CoreGraphics
import Foundation
import WalkFlowCore

protocol ControlEventOutput {
    func execute(_ action: ControlAction, scrollSettings: ScrollSettings)
}

protocol CGEventPosting {
    func postScroll(deltaY: Int32)
    func postKey(keyCode: CGKeyCode, keyDown: Bool, flags: CGEventFlags)
}

struct SystemCGEventPoster: CGEventPosting {
    func postScroll(deltaY: Int32) {
        guard let event = CGEvent(
            scrollWheelEvent2Source: nil,
            units: .line,
            wheelCount: 1,
            wheel1: deltaY,
            wheel2: 0,
            wheel3: 0
        ) else {
            return
        }
        event.post(tap: .cghidEventTap)
    }

    func postKey(keyCode: CGKeyCode, keyDown: Bool, flags: CGEventFlags) {
        let event = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: keyDown)
        event?.flags = flags
        event?.post(tap: .cghidEventTap)
    }
}

final class CGEventOutput: ControlEventOutput {
    private let poster: CGEventPosting

    init(poster: CGEventPosting = SystemCGEventPoster()) {
        self.poster = poster
    }

    func execute(_ action: ControlAction, scrollSettings: ScrollSettings) {
        switch action {
        case .none:
            return
        case .stopContinuousScroll:
            return
        case .scrollUp(let step):
            poster.postScroll(deltaY: delta(for: step, settings: scrollSettings))
        case .scrollDown(let step):
            poster.postScroll(deltaY: -delta(for: step, settings: scrollSettings))
        case .pressRightCommand:
            postRightCommand()
        }
    }

    private func delta(for step: ScrollStep, settings: ScrollSettings) -> Int32 {
        switch step {
        case .single:
            settings.singleStepDeltaY
        case .continuous:
            settings.continuousDeltaY
        }
    }

    private func postRightCommand() {
        let keyCode = CGKeyCode(kVK_RightCommand)
        poster.postKey(keyCode: keyCode, keyDown: true, flags: .maskCommand)
        poster.postKey(keyCode: keyCode, keyDown: false, flags: [])
    }
}
