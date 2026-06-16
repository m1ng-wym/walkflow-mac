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

    init(snapshot: PermissionSnapshot) {
        snapshotValue = snapshot
    }

    func snapshot() -> PermissionSnapshot {
        snapshotValue
    }
}

private final class FakeCameraController: CameraControlling {
    let session = AVCaptureSession()
    weak var consumer: CameraFrameConsumer?
    private(set) var configureCount = 0
    private(set) var startCount = 0
    private(set) var stopCount = 0

    func configure() throws {
        configureCount += 1
    }

    func start() {
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
