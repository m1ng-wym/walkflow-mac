import AVFoundation
import Foundation
import WalkFlowCore

protocol HUDPresenting: AnyObject {
    func update(_ presentation: HUDPresentation)
}

protocol SettingsStoring {
    func load() -> AppSettings
    func save(_ settings: AppSettings)
}

extension SettingsStore: SettingsStoring {}

protocol PermissionServicing {
    func snapshot() -> PermissionSnapshot
}

extension SystemPermissionService: PermissionServicing {}

protocol CameraControlling: AnyObject {
    var session: AVCaptureSession { get }
    var consumer: CameraFrameConsumer? { get set }
    func configure() throws
    func start()
    func stop()
}

extension CameraSessionController: CameraControlling {}

protocol VisionDetecting {
    func detect(sampleBuffer: CMSampleBuffer, timestamp: TimeInterval) throws -> HandPoseSnapshot?
}

extension VisionHandPoseProvider: VisionDetecting {}

protocol GestureClassifying {
    func classify(_ snapshot: HandPoseSnapshot?) -> GestureObservation
}

extension GestureClassifier: GestureClassifying {}

final class AppController: CameraFrameConsumer {
    let state = AppStateStore()

    private let settingsStore: SettingsStoring
    private let permissions: PermissionServicing
    private let camera: CameraControlling
    private let vision: VisionDetecting
    private let classifier: GestureClassifying
    private let hudReducer = HUDStateReducer()
    private let eventOutput: ControlEventOutput
    private var stateMachine: GestureStateMachine
    private let stateLock = NSRecursiveLock()

    weak var hudPresenter: HUDPresenting?

    init(
        settingsStore: SettingsStoring = SettingsStore(),
        permissions: PermissionServicing = SystemPermissionService(),
        camera: CameraControlling = CameraSessionController(),
        vision: VisionDetecting = VisionHandPoseProvider(),
        classifier: GestureClassifying = GestureClassifier(),
        eventOutput: ControlEventOutput = CGEventOutput()
    ) {
        self.settingsStore = settingsStore
        self.permissions = permissions
        self.camera = camera
        self.vision = vision
        self.classifier = classifier
        self.eventOutput = eventOutput

        state.settings = settingsStore.load()
        state.permissions = permissions.snapshot()
        stateMachine = GestureStateMachine(settings: state.settings)
        camera.consumer = self
    }

    func refreshPermissions() {
        withStateLock {
            state.permissions = permissions.snapshot()
            publishHUD(.init(mode: .standby, action: .none, hud: .init(dot: .green, icon: .none, message: "Standby")))
        }
    }

    func configureCameraIfPermitted() {
        withStateLock {
            state.permissions = permissions.snapshot()
            publishHUD(.init(mode: .standby, action: .none, hud: .init(dot: .green, icon: .none, message: "Standby")))
            guard state.permissions.camera == .granted else {
                return
            }

            do {
                try camera.configure()
            } catch {
                state.latestHUD = .init(dot: .red, icon: .alertTriangle, message: "Camera")
                publishLatestHUD()
            }
        }
    }

    func startRecognition() {
        withStateLock {
            guard state.isEnabled, state.isPaused == false, state.permissions.canControl else {
                publishHUD(.init(mode: .blocked, action: .none, hud: .init(dot: .red, icon: .alertTriangle, message: "Permission")))
                return
            }
            camera.start()
        }
    }

    func stopRecognition() {
        withStateLock {
            resetGestureStateMachine()
            camera.stop()
        }
    }

    func setEnabled(_ enabled: Bool) {
        withStateLock {
            state.isEnabled = enabled
            resetGestureStateMachine()
            publishHUD(
                .init(
                    mode: enabled ? .standby : .disabled,
                    action: .none,
                    hud: .init(dot: enabled ? .green : .red, icon: enabled ? .unlockOnce : .lock, message: enabled ? "Enabled" : "Disabled")
                )
            )
        }
    }

    func setPaused(_ paused: Bool) {
        withStateLock {
            state.isPaused = paused
            resetGestureStateMachine()
            publishHUD(.init(mode: .standby, action: .none, hud: .init(dot: .green, icon: .none, message: paused ? "Paused" : "Standby")))
        }
    }

    func cameraSession(_ session: CameraSessionController, didOutput sampleBuffer: CMSampleBuffer) {
        let timestamp = Date().timeIntervalSince1970
        let snapshot = try? vision.detect(sampleBuffer: sampleBuffer, timestamp: timestamp)
        let observation = classifier.classify(snapshot)
        handleObservation(observation)
    }

    func handleObservation(_ observation: GestureObservation) {
        withStateLock {
            guard state.permissions.canControl, state.isEnabled, state.isPaused == false else {
                publishHUD(.init(mode: .blocked, action: .none, hud: .init(dot: .green, icon: .none, message: "Standby")))
                return
            }

            let output = stateMachine.handle(observation)
            if output.action != .none {
                eventOutput.execute(output.action, scrollSettings: state.settings.scroll)
            }
            publishHUD(output)
        }
    }

    private func publishHUD(_ output: GestureStateOutput) {
        let hud = hudReducer.presentation(
            isEnabled: state.isEnabled,
            isPaused: state.isPaused,
            permissions: state.permissions,
            stateOutput: output
        )
        state.latestHUD = hud
        publishLatestHUD()
    }

    private func publishLatestHUD() {
        if Thread.isMainThread {
            hudPresenter?.update(state.latestHUD)
        } else {
            let hud = state.latestHUD
            DispatchQueue.main.async { [weak self] in
                self?.hudPresenter?.update(hud)
            }
        }
    }

    private func resetGestureStateMachine() {
        stateMachine = GestureStateMachine(settings: state.settings)
    }

    private func withStateLock<T>(_ work: () throws -> T) rethrows -> T {
        stateLock.lock()
        defer { stateLock.unlock() }
        return try work()
    }
}
