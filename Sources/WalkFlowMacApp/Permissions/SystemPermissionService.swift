import ApplicationServices
import AVFoundation
import Foundation
import WalkFlowCore

protocol CameraAuthorizationProviding {
    func authorizationStatus() -> AVAuthorizationStatus
    func requestAccess(completion: @escaping (Bool) -> Void)
}

struct AVFoundationCameraAuthorizationProvider: CameraAuthorizationProviding {
    func authorizationStatus() -> AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }

    func requestAccess(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: completion)
    }
}

protocol AccessibilityTrustProviding {
    func isTrusted() -> Bool
    func promptForTrust()
}

struct AXAccessibilityTrustProvider: AccessibilityTrustProviding {
    func isTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    func promptForTrust() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}

final class SystemPermissionService {
    private let cameraProvider: CameraAuthorizationProviding
    private let accessibilityProvider: AccessibilityTrustProviding

    init(
        cameraProvider: CameraAuthorizationProviding = AVFoundationCameraAuthorizationProvider(),
        accessibilityProvider: AccessibilityTrustProviding = AXAccessibilityTrustProvider()
    ) {
        self.cameraProvider = cameraProvider
        self.accessibilityProvider = accessibilityProvider
    }

    func snapshot() -> PermissionSnapshot {
        PermissionSnapshot(
            camera: cameraStatus(),
            accessibility: accessibilityStatus(),
            inputMonitoring: .notRequired
        )
    }

    func requestCameraAccess(completion: @escaping (Bool) -> Void) {
        cameraProvider.requestAccess(completion: completion)
    }

    func promptForAccessibility() {
        accessibilityProvider.promptForTrust()
    }

    private func cameraStatus() -> PermissionStatus {
        switch cameraProvider.authorizationStatus() {
        case .authorized:
            return .granted
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }

    private func accessibilityStatus() -> PermissionStatus {
        accessibilityProvider.isTrusted() ? .granted : .denied
    }
}
