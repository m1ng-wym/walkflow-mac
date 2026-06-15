import AppKit
import AVFoundation
import XCTest
@testable import WalkFlowMacApp

final class CameraPreviewViewTests: XCTestCase {
    func testPreviewViewUsesCaptureVideoPreviewLayer() {
        let view = CameraPreviewView(frame: NSRect(x: 0, y: 0, width: 320, height: 180))
        view.wantsLayer = true

        XCTAssertTrue(view.layer is AVCaptureVideoPreviewLayer)
        XCTAssertEqual(view.previewLayer.videoGravity, .resizeAspectFill)
    }

    func testPreviewViewAttachesCaptureSession() {
        let view = CameraPreviewView(frame: NSRect(x: 0, y: 0, width: 320, height: 180))
        view.wantsLayer = true
        let session = AVCaptureSession()

        view.attach(session: session)

        XCTAssertTrue(view.previewLayer.session === session)
    }

    func testCameraSessionControllerUsesLowResolutionPresetForLightweightRecognition() {
        let controller = CameraSessionController()

        XCTAssertEqual(controller.session.sessionPreset, .vga640x480)
    }
}
