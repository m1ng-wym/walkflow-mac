import AppKit
import AVFoundation

final class CameraPreviewView: NSView {
    override func makeBackingLayer() -> CALayer {
        let layer = AVCaptureVideoPreviewLayer()
        layer.videoGravity = .resizeAspectFill
        return layer
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        wantsLayer = true
    }

    func attach(session: AVCaptureSession) {
        wantsLayer = true
        previewLayer.session = session
    }
}
