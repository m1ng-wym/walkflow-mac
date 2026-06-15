import AVFoundation
import XCTest
@testable import WalkFlowCore
@testable import WalkFlowMacApp

final class SystemPermissionServiceTests: XCTestCase {
    func testSnapshotReportsGrantedCameraAndAccessibility() {
        let service = SystemPermissionService(
            cameraProvider: FakeCameraProvider(status: .authorized),
            accessibilityProvider: FakeAccessibilityProvider(trusted: true)
        )

        XCTAssertEqual(
            service.snapshot(),
            PermissionSnapshot(camera: .granted, accessibility: .granted, inputMonitoring: .notRequired)
        )
    }

    func testSnapshotBlocksWhenCameraDeniedOrAccessibilityMissing() {
        let cameraDenied = SystemPermissionService(
            cameraProvider: FakeCameraProvider(status: .denied),
            accessibilityProvider: FakeAccessibilityProvider(trusted: true)
        )
        let accessibilityDenied = SystemPermissionService(
            cameraProvider: FakeCameraProvider(status: .authorized),
            accessibilityProvider: FakeAccessibilityProvider(trusted: false)
        )

        XCTAssertFalse(cameraDenied.snapshot().canControl)
        XCTAssertFalse(accessibilityDenied.snapshot().canControl)
    }

    func testCameraStatusMapsRestrictedAndNotDetermined() {
        let restricted = SystemPermissionService(
            cameraProvider: FakeCameraProvider(status: .restricted),
            accessibilityProvider: FakeAccessibilityProvider(trusted: true)
        )
        let notDetermined = SystemPermissionService(
            cameraProvider: FakeCameraProvider(status: .notDetermined),
            accessibilityProvider: FakeAccessibilityProvider(trusted: true)
        )

        XCTAssertEqual(restricted.snapshot().camera, .denied)
        XCTAssertEqual(notDetermined.snapshot().camera, .notDetermined)
    }
}

private struct FakeCameraProvider: CameraAuthorizationProviding {
    let status: AVAuthorizationStatus

    func authorizationStatus() -> AVAuthorizationStatus {
        status
    }

    func requestAccess(completion: @escaping (Bool) -> Void) {
        completion(status == .authorized)
    }
}

private struct FakeAccessibilityProvider: AccessibilityTrustProviding {
    let trusted: Bool

    func isTrusted() -> Bool {
        trusted
    }

    func promptForTrust() {}
}
