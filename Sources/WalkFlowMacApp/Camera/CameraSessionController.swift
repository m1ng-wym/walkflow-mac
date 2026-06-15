import AVFoundation
import Foundation

protocol CameraFrameConsumer: AnyObject {
    func cameraSession(_ session: CameraSessionController, didOutput sampleBuffer: CMSampleBuffer)
}

final class CameraSessionController: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session: AVCaptureSession
    weak var consumer: CameraFrameConsumer?

    private let queue = DispatchQueue(label: "com.m1ngwym.walkflowmac.camera")

    override init() {
        session = AVCaptureSession()
        session.sessionPreset = .vga640x480
        super.init()
    }

    func configure() throws {
        session.beginConfiguration()
        session.sessionPreset = .vga640x480
        defer { session.commitConfiguration() }

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .unspecified) else {
            throw CameraError.noCamera
        }

        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else {
            throw CameraError.cannotAddInput
        }
        session.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: queue)
        guard session.canAddOutput(output) else {
            throw CameraError.cannotAddOutput
        }
        session.addOutput(output)
    }

    func start() {
        queue.async { [session] in
            if session.isRunning == false {
                session.startRunning()
            }
        }
    }

    func stop() {
        queue.async { [session] in
            if session.isRunning {
                session.stopRunning()
            }
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        consumer?.cameraSession(self, didOutput: sampleBuffer)
    }
}

enum CameraError: Error {
    case noCamera
    case cannotAddInput
    case cannotAddOutput
}
