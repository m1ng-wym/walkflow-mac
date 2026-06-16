import AVFoundation
import Foundation
import OSLog
import WalkFlowCore

protocol HUDPresenting: AnyObject {
    func update(_ presentation: HUDPresentation)
}

protocol HUDTelemetryLogging {
    func log(_ presentation: HUDPresentation)
}

struct OSLogHUDTelemetryLogger: HUDTelemetryLogging {
    private let logger = Logger(subsystem: "com.m1ngwym.walkflowmac", category: "Gesture")

    func log(_ presentation: HUDPresentation) {
        logger.info("gestureHUD=\(presentation.message, privacy: .public) icon=\(String(describing: presentation.icon), privacy: .public)")
    }
}

protocol SettingsStoring {
    func load() -> AppSettings
    func save(_ settings: AppSettings)
}

extension SettingsStore: SettingsStoring {}

protocol PermissionServicing {
    func snapshot() -> PermissionSnapshot
    func requestCameraAccess(completion: @escaping (Bool) -> Void)
    func promptForAccessibility()
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
    private let telemetryLogger: HUDTelemetryLogging
    private var stateMachine: GestureStateMachine
    private let stateLock = NSRecursiveLock()
    private let telemetryLock = NSLock()
    private var lastLoggedHUD: HUDPresentation?

    weak var hudPresenter: HUDPresenting?

    init(
        settingsStore: SettingsStoring = SettingsStore(),
        permissions: PermissionServicing = SystemPermissionService(),
        camera: CameraControlling = CameraSessionController(),
        vision: VisionDetecting = VisionHandPoseProvider(),
        classifier: GestureClassifying = GestureClassifier(),
        eventOutput: ControlEventOutput = CGEventOutput(),
        telemetryLogger: HUDTelemetryLogging = OSLogHUDTelemetryLogger()
    ) {
        self.settingsStore = settingsStore
        self.permissions = permissions
        self.camera = camera
        self.vision = vision
        self.classifier = classifier
        self.eventOutput = eventOutput
        self.telemetryLogger = telemetryLogger

        state.settings = settingsStore.load()
        state.permissions = permissions.snapshot()
        stateMachine = GestureStateMachine(settings: state.settings)
        camera.consumer = self
    }

    func refreshPermissions() {
        let hud = withStateLock {
            state.permissions = permissions.snapshot()
            return storeHUD(.init(mode: .standby, action: .none, hud: .init(dot: .green, icon: .none, message: "Standby")))
        }
        publish(hud)
    }

    func recheckPermissionsAndPromptForAccessibilityIfNeeded() {
        let shouldPromptAccessibility = withStateLock {
            state.permissions = permissions.snapshot()
            return state.permissions.accessibility == .denied
        }

        if shouldPromptAccessibility {
            permissions.promptForAccessibility()
        }

        refreshPermissions()
    }

    func configureCameraIfPermitted() {
        let hud = withStateLock {
            state.permissions = permissions.snapshot()
            let standbyHUD = storeHUD(.init(mode: .standby, action: .none, hud: .init(dot: .green, icon: .none, message: "Standby")))
            guard state.permissions.camera == .granted else {
                return standbyHUD
            }

            do {
                try camera.configure()
                return standbyHUD
            } catch {
                return store(.init(dot: .red, icon: .alertTriangle, message: "Camera"))
            }
        }
        publish(hud)
    }

    func startRecognition() {
        let hud: HUDPresentation? = withStateLock {
            guard state.isEnabled, state.isPaused == false else {
                return storeHUD(.init(mode: .blocked, action: .none, hud: .init(dot: .red, icon: .alertTriangle, message: "Permission")))
            }

            guard state.permissions.camera == .granted else {
                return storeHUD(.init(mode: .blocked, action: .none, hud: .init(dot: .red, icon: .alertTriangle, message: "Permission")))
            }

            camera.start()
            guard state.permissions.canControl else {
                return storeHUD(.init(mode: .blocked, action: .none, hud: .init(dot: .red, icon: .alertTriangle, message: "Permission")))
            }
            return nil
        }
        if let hud {
            publish(hud)
        }
    }

    func prepareCameraAuthorizationAndStartRecognition() {
        let shouldRequestCamera = withStateLock {
            state.permissions = permissions.snapshot()
            return state.permissions.camera == .notDetermined
        }

        guard shouldRequestCamera else {
            configureCameraIfPermitted()
            startRecognition()
            return
        }

        permissions.requestCameraAccess { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                self?.refreshPermissions()
                self?.configureCameraIfPermitted()
                self?.startRecognition()
            }
        }
    }

    func attachPreview(to previewView: CameraPreviewView) {
        precondition(Thread.isMainThread, "Camera preview attachment must run on the main thread.")
        previewView.attach(session: camera.session)
    }

    func stopRecognition() {
        withStateLock {
            resetGestureStateMachine()
            camera.stop()
        }
    }

    func setEnabled(_ enabled: Bool) {
        let hud = withStateLock {
            state.isEnabled = enabled
            resetGestureStateMachine()
            return storeHUD(
                .init(
                    mode: enabled ? .standby : .disabled,
                    action: .none,
                    hud: .init(dot: enabled ? .green : .red, icon: enabled ? .unlockOnce : .lock, message: enabled ? "Enabled" : "Disabled")
                )
            )
        }
        publish(hud)
    }

    func setPaused(_ paused: Bool) {
        let hud = withStateLock {
            state.isPaused = paused
            resetGestureStateMachine()
            return storeHUD(.init(mode: .standby, action: .none, hud: .init(dot: .green, icon: .none, message: paused ? "Paused" : "Standby")))
        }
        publish(hud)
    }

    func cameraSession(_ session: CameraSessionController, didOutput sampleBuffer: CMSampleBuffer) {
        let timestamp = Date().timeIntervalSince1970
        let snapshot = try? vision.detect(sampleBuffer: sampleBuffer, timestamp: timestamp)
        let observation = classifier.classify(snapshot)
        handleObservation(observation)
    }

    func handleObservation(_ observation: GestureObservation) {
        let hud = withStateLock {
            guard state.permissions.canControl, state.isEnabled, state.isPaused == false else {
                return storeHUD(.init(mode: .blocked, action: .none, hud: .init(dot: .green, icon: .none, message: "Standby")))
            }

            let output = stateMachine.handle(observation)
            if output.action != .none {
                eventOutput.execute(output.action, scrollSettings: state.settings.scroll)
            }
            return storeHUD(output)
        }
        publish(hud)
    }

    private func storeHUD(_ output: GestureStateOutput) -> HUDPresentation {
        let hud = hudReducer.presentation(
            isEnabled: state.isEnabled,
            isPaused: state.isPaused,
            permissions: state.permissions,
            stateOutput: output
        )
        return store(hud)
    }

    private func store(_ hud: HUDPresentation) -> HUDPresentation {
        state.latestHUD = hud
        return hud
    }

    private func publish(_ hud: HUDPresentation) {
        logIfTransition(hud)
        if Thread.isMainThread {
            hudPresenter?.update(hud)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.hudPresenter?.update(hud)
            }
        }
    }

    private func logIfTransition(_ hud: HUDPresentation) {
        telemetryLock.lock()
        let shouldLog = hud != lastLoggedHUD
        if shouldLog {
            lastLoggedHUD = hud
        }
        telemetryLock.unlock()

        if shouldLog {
            telemetryLogger.log(hud)
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
