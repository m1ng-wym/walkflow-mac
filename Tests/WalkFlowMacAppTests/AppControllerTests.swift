import AppKit
import AVFoundation
import XCTest
@testable import WalkFlowCore
@testable import WalkFlowMacApp

final class AppControllerTests: XCTestCase {
    func testStartRecognitionDoesNotStartCameraWhenPermissionsAreBlocked() {
        let camera = FakeCameraController()
        let hud = RecordingHUDPresenter()
        let controller = AppController(
            settingsStore: FakeSettingsStore(),
            permissions: FakePermissionService(snapshot: PermissionSnapshot(camera: .denied, accessibility: .granted, inputMonitoring: .notRequired)),
            camera: camera,
            eventOutput: RecordingControlEventOutput()
        )
        controller.hudPresenter = hud

        controller.startRecognition()

        XCTAssertEqual(camera.startCount, 0)
        XCTAssertEqual(hud.presentations.last?.dot, .red)
    }

    func testStartRecognitionStartsCameraWhenEnabledAndPermitted() {
        let camera = FakeCameraController()
        let controller = AppController(
            settingsStore: FakeSettingsStore(),
            permissions: FakePermissionService(snapshot: PermissionSnapshot(camera: .granted, accessibility: .granted, inputMonitoring: .notRequired)),
            camera: camera,
            eventOutput: RecordingControlEventOutput()
        )

        controller.startRecognition()

        XCTAssertEqual(camera.startCount, 1)
    }

    func testStartRecognitionStartsCameraPreviewWhenCameraGrantedButAccessibilityMissing() {
        let camera = FakeCameraController()
        let hud = RecordingHUDPresenter()
        let controller = AppController(
            settingsStore: FakeSettingsStore(),
            permissions: FakePermissionService(snapshot: PermissionSnapshot(camera: .granted, accessibility: .denied, inputMonitoring: .notRequired)),
            camera: camera,
            eventOutput: RecordingControlEventOutput()
        )
        controller.hudPresenter = hud

        controller.startRecognition()

        XCTAssertEqual(camera.startCount, 1)
        XCTAssertEqual(hud.presentations.last?.dot, .red)
        XCTAssertEqual(hud.presentations.last?.icon, .alertTriangle)
    }

    func testLaunchPreparationRequestsCameraWhenNotDeterminedThenStartsAfterGrant() {
        let camera = FakeCameraController()
        let permissions = FakePermissionService(snapshot: PermissionSnapshot(camera: .notDetermined, accessibility: .granted, inputMonitoring: .notRequired))
        let controller = AppController(
            settingsStore: FakeSettingsStore(),
            permissions: permissions,
            camera: camera,
            eventOutput: RecordingControlEventOutput()
        )

        controller.prepareCameraAuthorizationAndStartRecognition()

        XCTAssertEqual(permissions.cameraRequestCount, 1)
        XCTAssertEqual(camera.configureCount, 0)
        XCTAssertEqual(camera.startCount, 0)

        let handled = expectation(description: "camera grant handled")
        DispatchQueue.global().async {
            permissions.completeCameraRequest(
                granted: true,
                snapshot: PermissionSnapshot(camera: .granted, accessibility: .granted, inputMonitoring: .notRequired)
            )
            DispatchQueue.main.async {
                handled.fulfill()
            }
        }
        wait(for: [handled], timeout: 1.0)

        XCTAssertEqual(controller.state.permissions.camera, .granted)
        XCTAssertEqual(camera.configureCount, 1)
        XCTAssertEqual(camera.startCount, 1)
        XCTAssertEqual(camera.configureWasCalledOnMainThread, true)
        XCTAssertEqual(camera.startWasCalledOnMainThread, true)
    }

    func testLaunchPreparationStartsPreviewWhenCameraGrantedButAccessibilityMissing() {
        let camera = FakeCameraController()
        let permissions = FakePermissionService(snapshot: PermissionSnapshot(camera: .granted, accessibility: .denied, inputMonitoring: .notRequired))
        let hud = RecordingHUDPresenter()
        let controller = AppController(
            settingsStore: FakeSettingsStore(),
            permissions: permissions,
            camera: camera,
            eventOutput: RecordingControlEventOutput()
        )
        controller.hudPresenter = hud

        controller.prepareCameraAuthorizationAndStartRecognition()

        XCTAssertEqual(permissions.cameraRequestCount, 0)
        XCTAssertEqual(camera.configureCount, 1)
        XCTAssertEqual(camera.startCount, 1)
        XCTAssertEqual(camera.configureWasCalledOnMainThread, true)
        XCTAssertEqual(camera.startWasCalledOnMainThread, true)
        XCTAssertEqual(hud.presentations.last?.dot, .red)
        XCTAssertEqual(hud.presentations.last?.icon, .alertTriangle)
    }

    func testAttachPreviewAssignsCameraSessionToPreviewLayer() {
        let camera = FakeCameraController()
        let controller = AppController(
            settingsStore: FakeSettingsStore(),
            permissions: FakePermissionService(snapshot: PermissionSnapshot(camera: .granted, accessibility: .granted, inputMonitoring: .notRequired)),
            camera: camera,
            eventOutput: RecordingControlEventOutput()
        )
        let preview = CameraPreviewView(frame: NSRect(x: 0, y: 0, width: 320, height: 180))
        preview.wantsLayer = true

        controller.attachPreview(to: preview)

        XCTAssertTrue(preview.previewLayer.session === camera.session)
    }

    func testDisablingAppPublishesLockedHUD() {
        let hud = RecordingHUDPresenter()
        let controller = AppController(
            settingsStore: FakeSettingsStore(),
            permissions: FakePermissionService(snapshot: PermissionSnapshot(camera: .granted, accessibility: .granted, inputMonitoring: .notRequired)),
            camera: FakeCameraController(),
            eventOutput: RecordingControlEventOutput()
        )
        controller.hudPresenter = hud

        controller.setEnabled(false)

        XCTAssertEqual(hud.presentations.last?.dot, .red)
        XCTAssertEqual(hud.presentations.last?.icon, .lock)
    }

    func testTelemetryLogsOnlyHUDTransitions() {
        let telemetry = RecordingHUDTelemetryLogger()
        let controller = AppController(
            settingsStore: FakeSettingsStore(),
            permissions: FakePermissionService(snapshot: PermissionSnapshot(camera: .granted, accessibility: .granted, inputMonitoring: .notRequired)),
            camera: FakeCameraController(),
            eventOutput: RecordingControlEventOutput(),
            telemetryLogger: telemetry
        )

        controller.refreshPermissions()
        controller.refreshPermissions()
        controller.setEnabled(false)
        controller.setEnabled(false)

        XCTAssertEqual(
            telemetry.presentations,
            [
                HUDPresentation(dot: .green, icon: .none, message: "Standby"),
                HUDPresentation(dot: .red, icon: .lock, message: "Disabled")
            ]
        )
    }

    func testDisabledAppDoesNotExecuteGestureActions() {
        let output = RecordingControlEventOutput()
        let controller = AppController(
            settingsStore: FakeSettingsStore(),
            permissions: FakePermissionService(snapshot: PermissionSnapshot(camera: .granted, accessibility: .granted, inputMonitoring: .notRequired)),
            camera: FakeCameraController(),
            eventOutput: output
        )

        controller.handleObservation(.init(kind: .openPalm, confidence: 1, timestamp: 0))
        controller.handleObservation(.init(kind: .openPalm, confidence: 1, timestamp: 0.31))
        controller.setEnabled(false)
        controller.handleObservation(.init(kind: .indexUp, confidence: 1, timestamp: 1.00))
        controller.handleObservation(.init(kind: .indexUp, confidence: 1, timestamp: 1.31))

        XCTAssertTrue(output.actions.isEmpty)
    }

    func testDisabledAppDoesNotPrimeGestureStateForLaterEnable() {
        let output = RecordingControlEventOutput()
        let controller = AppController(
            settingsStore: FakeSettingsStore(),
            permissions: FakePermissionService(snapshot: PermissionSnapshot(camera: .granted, accessibility: .granted, inputMonitoring: .notRequired)),
            camera: FakeCameraController(),
            eventOutput: output
        )

        controller.setEnabled(false)
        controller.handleObservation(.init(kind: .openPalm, confidence: 1, timestamp: 0))
        controller.handleObservation(.init(kind: .openPalm, confidence: 1, timestamp: 0.31))
        controller.setEnabled(true)
        controller.handleObservation(.init(kind: .indexUp, confidence: 1, timestamp: 1.00))
        controller.handleObservation(.init(kind: .indexUp, confidence: 1, timestamp: 1.31))

        XCTAssertTrue(output.actions.isEmpty)
    }

    func testDisablingAppClearsAlreadyPrimedGestureState() {
        let output = RecordingControlEventOutput()
        let controller = AppController(
            settingsStore: FakeSettingsStore(),
            permissions: FakePermissionService(snapshot: PermissionSnapshot(camera: .granted, accessibility: .granted, inputMonitoring: .notRequired)),
            camera: FakeCameraController(),
            eventOutput: output
        )

        controller.handleObservation(.init(kind: .openPalm, confidence: 1, timestamp: 0))
        controller.handleObservation(.init(kind: .openPalm, confidence: 1, timestamp: 0.31))
        controller.setEnabled(false)
        controller.setEnabled(true)
        controller.handleObservation(.init(kind: .indexUp, confidence: 1, timestamp: 1.00))
        controller.handleObservation(.init(kind: .indexUp, confidence: 1, timestamp: 1.31))

        XCTAssertTrue(output.actions.isEmpty)
    }

    func testPausedAppDoesNotExecuteGestureActions() {
        let output = RecordingControlEventOutput()
        let controller = AppController(
            settingsStore: FakeSettingsStore(),
            permissions: FakePermissionService(snapshot: PermissionSnapshot(camera: .granted, accessibility: .granted, inputMonitoring: .notRequired)),
            camera: FakeCameraController(),
            eventOutput: output
        )

        controller.setPaused(true)
        controller.handleObservation(.init(kind: .openPalm, confidence: 1, timestamp: 0))
        controller.handleObservation(.init(kind: .openPalm, confidence: 1, timestamp: 0.31))
        controller.handleObservation(.init(kind: .indexUp, confidence: 1, timestamp: 1.00))
        controller.handleObservation(.init(kind: .indexUp, confidence: 1, timestamp: 1.31))

        XCTAssertTrue(output.actions.isEmpty)
    }

    func testPausingAppClearsAlreadyPrimedGestureState() {
        let output = RecordingControlEventOutput()
        let controller = AppController(
            settingsStore: FakeSettingsStore(),
            permissions: FakePermissionService(snapshot: PermissionSnapshot(camera: .granted, accessibility: .granted, inputMonitoring: .notRequired)),
            camera: FakeCameraController(),
            eventOutput: output
        )

        controller.handleObservation(.init(kind: .openPalm, confidence: 1, timestamp: 0))
        controller.handleObservation(.init(kind: .openPalm, confidence: 1, timestamp: 0.31))
        controller.setPaused(true)
        controller.setPaused(false)
        controller.handleObservation(.init(kind: .indexUp, confidence: 1, timestamp: 1.00))
        controller.handleObservation(.init(kind: .indexUp, confidence: 1, timestamp: 1.31))

        XCTAssertTrue(output.actions.isEmpty)
    }

    func testStopRecognitionClearsAlreadyPrimedGestureState() {
        let output = RecordingControlEventOutput()
        let camera = FakeCameraController()
        let controller = AppController(
            settingsStore: FakeSettingsStore(),
            permissions: FakePermissionService(snapshot: PermissionSnapshot(camera: .granted, accessibility: .granted, inputMonitoring: .notRequired)),
            camera: camera,
            eventOutput: output
        )

        controller.handleObservation(.init(kind: .openPalm, confidence: 1, timestamp: 0))
        controller.handleObservation(.init(kind: .openPalm, confidence: 1, timestamp: 0.31))
        controller.stopRecognition()
        controller.handleObservation(.init(kind: .indexUp, confidence: 1, timestamp: 1.00))
        controller.handleObservation(.init(kind: .indexUp, confidence: 1, timestamp: 1.31))

        XCTAssertEqual(camera.stopCount, 1)
        XCTAssertTrue(output.actions.isEmpty)
    }

    func testPermissionBlockedObservationDoesNotExecuteOrPrimeGestureState() {
        let output = RecordingControlEventOutput()
        let permissions = FakePermissionService(snapshot: PermissionSnapshot(camera: .denied, accessibility: .granted, inputMonitoring: .notRequired))
        let controller = AppController(
            settingsStore: FakeSettingsStore(),
            permissions: permissions,
            camera: FakeCameraController(),
            eventOutput: output
        )

        controller.handleObservation(.init(kind: .openPalm, confidence: 1, timestamp: 0))
        controller.handleObservation(.init(kind: .openPalm, confidence: 1, timestamp: 0.31))
        permissions.snapshotValue = PermissionSnapshot(camera: .granted, accessibility: .granted, inputMonitoring: .notRequired)
        controller.refreshPermissions()
        controller.handleObservation(.init(kind: .indexUp, confidence: 1, timestamp: 1.00))
        controller.handleObservation(.init(kind: .indexUp, confidence: 1, timestamp: 1.31))

        XCTAssertTrue(output.actions.isEmpty)
    }

    func testAccessibilityBlockedObservationDoesNotExecuteOrPrimeGestureStateWhilePreviewRuns() {
        let output = RecordingControlEventOutput()
        let camera = FakeCameraController()
        let permissions = FakePermissionService(snapshot: PermissionSnapshot(camera: .granted, accessibility: .denied, inputMonitoring: .notRequired))
        let controller = AppController(
            settingsStore: FakeSettingsStore(),
            permissions: permissions,
            camera: camera,
            eventOutput: output
        )

        controller.startRecognition()
        controller.handleObservation(.init(kind: .openPalm, confidence: 1, timestamp: 0))
        controller.handleObservation(.init(kind: .openPalm, confidence: 1, timestamp: 0.31))
        permissions.snapshotValue = PermissionSnapshot(camera: .granted, accessibility: .granted, inputMonitoring: .notRequired)
        controller.refreshPermissions()
        controller.handleObservation(.init(kind: .indexUp, confidence: 1, timestamp: 1.00))
        controller.handleObservation(.init(kind: .indexUp, confidence: 1, timestamp: 1.31))

        XCTAssertEqual(camera.startCount, 1)
        XCTAssertTrue(output.actions.isEmpty)
    }

    func testPermittedArmedGestureExecutesScrollAction() {
        let output = RecordingControlEventOutput()
        let controller = AppController(
            settingsStore: FakeSettingsStore(),
            permissions: FakePermissionService(snapshot: PermissionSnapshot(camera: .granted, accessibility: .granted, inputMonitoring: .notRequired)),
            camera: FakeCameraController(),
            eventOutput: output
        )

        controller.handleObservation(.init(kind: .openPalm, confidence: 1, timestamp: 0))
        controller.handleObservation(.init(kind: .openPalm, confidence: 1, timestamp: 0.31))
        controller.handleObservation(.init(kind: .indexUp, confidence: 1, timestamp: 1.00))
        controller.handleObservation(.init(kind: .indexUp, confidence: 1, timestamp: 1.31))

        XCTAssertEqual(output.actions, [.scrollUp(step: .single)])
    }

    func testNilVisionFramesUseCurrentFrameTimestampToExitReadyAfterCommand() {
        let clock = MutableTestClock(now: 0)
        let vision = NilVisionDetector()
        let hud = RecordingHUDPresenter()
        let controller = AppController(
            settingsStore: FakeSettingsStore(),
            permissions: FakePermissionService(snapshot: PermissionSnapshot(camera: .granted, accessibility: .granted, inputMonitoring: .notRequired)),
            camera: FakeCameraController(),
            vision: vision,
            eventOutput: RecordingControlEventOutput(),
            clock: clock
        )
        controller.hudPresenter = hud

        controller.handleObservation(.init(kind: .openPalm, confidence: 1, timestamp: 0))
        controller.handleObservation(.init(kind: .openPalm, confidence: 1, timestamp: 0.31))
        controller.handleObservation(.init(kind: .okPinch, confidence: 1, timestamp: 1.00))
        controller.handleObservation(.init(kind: .okPinch, confidence: 1, timestamp: 1.31))
        XCTAssertEqual(hud.presentations.last?.icon, .dribbble)

        clock.now = 1.50
        controller.cameraSession(CameraSessionController(), didOutput: makeSampleBuffer())
        XCTAssertEqual(hud.presentations.last?.icon, .infinity)

        clock.now = 1.72
        controller.cameraSession(CameraSessionController(), didOutput: makeSampleBuffer())
        XCTAssertEqual(hud.presentations.last?.dot, .red)
        XCTAssertEqual(hud.presentations.last?.icon, HUDIcon.none)
        XCTAssertEqual(hud.presentations.last?.message, "Hand Lost")
        XCTAssertEqual(vision.timestamps, [1.50, 1.72])
    }

    func testPauseCannotInterleaveBetweenGestureDecisionAndEventOutput() {
        let output = InterleavingControlEventOutput()
        let controller = AppController(
            settingsStore: FakeSettingsStore(),
            permissions: FakePermissionService(snapshot: PermissionSnapshot(camera: .granted, accessibility: .granted, inputMonitoring: .notRequired)),
            camera: FakeCameraController(),
            eventOutput: output
        )
        output.controller = controller

        controller.handleObservation(.init(kind: .openPalm, confidence: 1, timestamp: 0))
        controller.handleObservation(.init(kind: .openPalm, confidence: 1, timestamp: 0.31))
        controller.handleObservation(.init(kind: .indexUp, confidence: 1, timestamp: 1.00))

        let gestureDone = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            controller.handleObservation(.init(kind: .indexUp, confidence: 1, timestamp: 1.31))
            gestureDone.signal()
        }

        XCTAssertEqual(output.entered.wait(timeout: .now() + .seconds(2)), .success)

        let pauseDone = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            controller.setPaused(true)
            pauseDone.signal()
        }

        Thread.sleep(forTimeInterval: 0.05)
        output.release.signal()

        XCTAssertEqual(gestureDone.wait(timeout: .now() + .seconds(2)), .success)
        XCTAssertEqual(pauseDone.wait(timeout: .now() + .seconds(2)), .success)
        XCTAssertFalse(output.observedPausedAtPost)
    }
}

private final class FakeSettingsStore: SettingsStoring {
    func load() -> AppSettings { .defaults }
    func save(_ settings: AppSettings) {}
}

private final class FakePermissionService: PermissionServicing {
    var snapshotValue: PermissionSnapshot
    private var cameraRequestCompletion: ((Bool) -> Void)?
    private(set) var cameraRequestCount = 0

    init(snapshot: PermissionSnapshot) {
        snapshotValue = snapshot
    }

    func snapshot() -> PermissionSnapshot {
        snapshotValue
    }

    func requestCameraAccess(completion: @escaping (Bool) -> Void) {
        cameraRequestCount += 1
        cameraRequestCompletion = completion
    }

    func promptForAccessibility() {}

    func completeCameraRequest(granted: Bool, snapshot: PermissionSnapshot) {
        snapshotValue = snapshot
        cameraRequestCompletion?(granted)
    }
}

private final class FakeCameraController: CameraControlling {
    let session = AVCaptureSession()
    weak var consumer: CameraFrameConsumer?
    private(set) var configureCount = 0
    private(set) var startCount = 0
    private(set) var stopCount = 0
    private(set) var configureWasCalledOnMainThread: Bool?
    private(set) var startWasCalledOnMainThread: Bool?

    func configure() throws {
        configureWasCalledOnMainThread = Thread.isMainThread
        configureCount += 1
    }

    func start() {
        startWasCalledOnMainThread = Thread.isMainThread
        startCount += 1
    }

    func stop() {
        stopCount += 1
    }
}

private final class RecordingControlEventOutput: ControlEventOutput {
    private(set) var actions: [ControlAction] = []

    func execute(_ action: ControlAction, scrollSettings: ScrollSettings) {
        actions.append(action)
    }
}

private final class RecordingHUDPresenter: HUDPresenting {
    private(set) var presentations: [HUDPresentation] = []

    func update(_ presentation: HUDPresentation) {
        presentations.append(presentation)
    }
}

private final class RecordingHUDTelemetryLogger: HUDTelemetryLogging {
    private(set) var presentations: [HUDPresentation] = []

    func log(_ presentation: HUDPresentation) {
        presentations.append(presentation)
    }
}

private final class NilVisionDetector: VisionDetecting {
    private(set) var timestamps: [TimeInterval] = []

    func detect(sampleBuffer: CMSampleBuffer, timestamp: TimeInterval) throws -> HandPoseSnapshot? {
        timestamps.append(timestamp)
        return nil
    }
}

private final class MutableTestClock: Clock {
    var now: TimeInterval

    init(now: TimeInterval) {
        self.now = now
    }
}

private final class InterleavingControlEventOutput: ControlEventOutput {
    weak var controller: AppController?
    let entered = DispatchSemaphore(value: 0)
    let release = DispatchSemaphore(value: 0)
    private(set) var observedPausedAtPost = false

    func execute(_ action: ControlAction, scrollSettings: ScrollSettings) {
        entered.signal()
        _ = release.wait(timeout: .now() + .seconds(2))
        observedPausedAtPost = controller?.state.isPaused ?? false
    }
}

private func makeSampleBuffer() -> CMSampleBuffer {
    var pixelBuffer: CVPixelBuffer?
    let pixelBufferStatus = CVPixelBufferCreate(
        kCFAllocatorDefault,
        1,
        1,
        kCVPixelFormatType_32BGRA,
        nil,
        &pixelBuffer
    )
    XCTAssertEqual(pixelBufferStatus, kCVReturnSuccess)

    var formatDescription: CMVideoFormatDescription?
    let formatStatus = CMVideoFormatDescriptionCreateForImageBuffer(
        allocator: kCFAllocatorDefault,
        imageBuffer: pixelBuffer!,
        formatDescriptionOut: &formatDescription
    )
    XCTAssertEqual(formatStatus, noErr)

    var timing = CMSampleTimingInfo(
        duration: .invalid,
        presentationTimeStamp: CMTime(value: 1, timescale: 30),
        decodeTimeStamp: .invalid
    )
    var sampleBuffer: CMSampleBuffer?
    let sampleStatus = CMSampleBufferCreateReadyWithImageBuffer(
        allocator: kCFAllocatorDefault,
        imageBuffer: pixelBuffer!,
        formatDescription: formatDescription!,
        sampleTiming: &timing,
        sampleBufferOut: &sampleBuffer
    )
    XCTAssertEqual(sampleStatus, noErr)
    return sampleBuffer!
}
