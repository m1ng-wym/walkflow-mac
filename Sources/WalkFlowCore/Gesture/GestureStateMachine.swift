import Foundation

public enum GestureMode: Equatable, Sendable {
    case disabled
    case blocked
    case standby
    case ready
}

public struct GestureStateOutput: Equatable, Sendable {
    public var mode: GestureMode
    public var action: ControlAction
    public var hud: HUDPresentation

    public init(mode: GestureMode, action: ControlAction, hud: HUDPresentation) {
        self.mode = mode
        self.action = action
        self.hud = hud
    }
}

public struct GestureStateMachine {
    private let settings: AppSettings
    private var mode: GestureMode = .standby
    private var currentGesture: GestureKind = .none
    private var currentGestureStartedAt: TimeInterval?
    private var lastActionAt: TimeInterval?
    private var isContinuousScrolling = false
    private var singleScrollFiredForCurrentGesture = false
    private var okPinchLatched = false
    private var okCooldownUntil: TimeInterval = 0
    private var isVoiceInputActive = false

    public init(settings: AppSettings) {
        self.settings = settings
    }

    public mutating func handle(_ observation: GestureObservation) -> GestureStateOutput {
        let shouldStopContinuousForGestureChange = isContinuousScrolling && observation.kind != currentGesture
        updateGestureTracking(with: observation)

        if mode == .ready,
           isVoiceInputActive,
           observation.kind != .okPinch,
           observation.kind != .handLost,
           observation.kind != .fist {
            okPinchLatched = false
            isContinuousScrolling = false
            return output(action: .none, hud: commandHUD())
        }

        if shouldStopContinuousForGestureChange,
           observation.kind != .handLost,
           observation.kind != .fist {
            return output(action: .stopContinuousScroll, hud: defaultHUD())
        }

        if mode == .ready,
           let lastActionAt,
           isVoiceInputActive == false,
           observation.timestamp - lastActionAt > settings.gestureTiming.controlWindowSeconds {
            mode = .standby
            isContinuousScrolling = false
            singleScrollFiredForCurrentGesture = false
            currentGestureStartedAt = observation.timestamp
            self.lastActionAt = nil
            return output(action: .none, hud: .init(dot: .green, icon: .none, message: "Standby"))
        }

        switch observation.kind {
        case .handLost:
            mode = .standby
            isContinuousScrolling = false
            return output(action: .stopContinuousScroll, hud: .init(dot: .red, icon: .none, message: "Hand Lost"))
        case .fist:
            mode = .standby
            isContinuousScrolling = false
            return output(action: .stopContinuousScroll, hud: .init(dot: .red, icon: .none, message: "Stop"))
        case .openPalm:
            okPinchLatched = false
            if mode == .ready {
                return output(action: .none, hud: defaultHUD())
            }
            if heldMilliseconds(at: observation.timestamp) >= settings.gestureTiming.readyHoldMilliseconds {
                mode = .ready
                lastActionAt = observation.timestamp
                return output(action: .none, hud: defaultHUD())
            }
            return output(action: .none, hud: defaultHUD())
        case .indexUp:
            return scrollOutput(direction: .up, timestamp: observation.timestamp)
        case .indexDown:
            return scrollOutput(direction: .down, timestamp: observation.timestamp)
        case .okPinch:
            return commandOutput(timestamp: observation.timestamp)
        case .none:
            okPinchLatched = false
            if isContinuousScrolling {
                isContinuousScrolling = false
                return output(action: .stopContinuousScroll, hud: defaultHUD())
            }
            return output(action: .none, hud: defaultHUD())
        }
    }

    private mutating func updateGestureTracking(with observation: GestureObservation) {
        if observation.kind != currentGesture {
            if isContinuousScrolling {
                isContinuousScrolling = false
            }
            singleScrollFiredForCurrentGesture = false
            currentGesture = observation.kind
            currentGestureStartedAt = observation.timestamp
        }
    }

    private func heldMilliseconds(at timestamp: TimeInterval) -> Int {
        guard let currentGestureStartedAt else { return 0 }
        return Int((timestamp - currentGestureStartedAt) * 1000)
    }

    private enum ScrollDirection {
        case up
        case down
    }

    private mutating func scrollOutput(direction: ScrollDirection, timestamp: TimeInterval) -> GestureStateOutput {
        guard mode == .ready else {
            return output(action: .none, hud: defaultHUD())
        }

        let held = heldMilliseconds(at: timestamp)
        let icon: HUDIcon = direction == .up ? .arrowUp : .arrowDown

        if held >= settings.gestureTiming.continuousScrollHoldMilliseconds {
            isContinuousScrolling = true
            lastActionAt = timestamp
            return output(
                action: direction == .up ? .scrollUp(step: .continuous) : .scrollDown(step: .continuous),
                hud: .init(dot: .green, icon: icon, message: direction == .up ? "Scroll Up" : "Scroll Down")
            )
        }

        if held >= settings.gestureTiming.scrollHoldMilliseconds, isContinuousScrolling == false {
            guard singleScrollFiredForCurrentGesture == false else {
                return output(action: .none, hud: .init(dot: .green, icon: icon, message: direction == .up ? "Scroll Up" : "Scroll Down"))
            }
            singleScrollFiredForCurrentGesture = true
            lastActionAt = timestamp
            return output(
                action: direction == .up ? .scrollUp(step: .single) : .scrollDown(step: .single),
                hud: .init(dot: .green, icon: icon, message: direction == .up ? "Scroll Up" : "Scroll Down")
            )
        }

        return output(action: .none, hud: .init(dot: .green, icon: icon, message: direction == .up ? "Scroll Up" : "Scroll Down"))
    }

    private mutating func commandOutput(timestamp: TimeInterval) -> GestureStateOutput {
        guard mode == .ready else {
            return output(action: .none, hud: defaultHUD())
        }

        guard timestamp >= okCooldownUntil else {
            return output(action: .none, hud: isVoiceInputActive ? commandHUD() : .init(dot: .green, icon: .none, message: "Cooldown"))
        }

        guard okPinchLatched == false else {
            return output(action: .none, hud: isVoiceInputActive ? commandHUD() : defaultHUD())
        }

        if heldMilliseconds(at: timestamp) >= settings.gestureTiming.commandHoldMilliseconds {
            okPinchLatched = true
            okCooldownUntil = timestamp + Double(settings.gestureTiming.commandCooldownMilliseconds) / 1000.0
            lastActionAt = timestamp
            isVoiceInputActive.toggle()
            if isVoiceInputActive == false {
                mode = .standby
                isContinuousScrolling = false
                singleScrollFiredForCurrentGesture = false
            }
            return output(
                action: .pressRightCommand,
                hud: isVoiceInputActive
                    ? .init(dot: .green, icon: .dribbble, message: "Command")
                    : .init(dot: .green, icon: .none, message: "Standby")
            )
        }

        return output(action: .none, hud: isVoiceInputActive ? commandHUD() : .init(dot: .green, icon: .none, message: "Command Pending"))
    }

    private func defaultHUD() -> HUDPresentation {
        switch mode {
        case .disabled:
            .init(dot: .red, icon: .lock, message: "Disabled")
        case .blocked:
            .init(dot: .red, icon: .alertTriangle, message: "Permission")
        case .ready:
            isVoiceInputActive
                ? commandHUD()
                : .init(dot: .green, icon: .infinity, message: "Ready")
        case .standby:
            .init(dot: .green, icon: .none, message: "Standby")
        }
    }

    private func commandHUD() -> HUDPresentation {
        .init(dot: .green, icon: .dribbble, message: "Command")
    }

    private func output(action: ControlAction, hud: HUDPresentation) -> GestureStateOutput {
        GestureStateOutput(mode: mode, action: action, hud: hud)
    }
}
