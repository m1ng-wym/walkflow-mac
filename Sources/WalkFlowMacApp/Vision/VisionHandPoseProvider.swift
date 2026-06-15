import AVFoundation
import Foundation
import Vision
import WalkFlowCore

final class VisionHandPoseProvider {
    private let request: VNDetectHumanHandPoseRequest = {
        let request = VNDetectHumanHandPoseRequest()
        request.maximumHandCount = 1
        return request
    }()

    func detect(sampleBuffer: CMSampleBuffer, timestamp: TimeInterval) throws -> HandPoseSnapshot? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        try handler.perform([request])
        guard let observation = request.results?.first else {
            return nil
        }

        let recognizedPoints = try observation.recognizedPoints(.all)
        var points: [HandJointName: HandPoint] = [:]
        for (visionName, jointName) in Self.jointMap {
            guard let point = recognizedPoints[visionName] else {
                continue
            }
            points[jointName] = HandPoint(
                x: Double(point.location.x),
                y: Double(point.location.y),
                confidence: Double(point.confidence)
            )
        }

        return HandPoseSnapshot(
            points: points,
            handedness: .unknown,
            timestamp: timestamp
        )
    }

    static let jointMap: [VNHumanHandPoseObservation.JointName: HandJointName] = [
        .wrist: .wrist,
        .thumbCMC: .thumbCMC,
        .thumbMP: .thumbMP,
        .thumbIP: .thumbIP,
        .thumbTip: .thumbTip,
        .indexMCP: .indexMCP,
        .indexPIP: .indexPIP,
        .indexDIP: .indexDIP,
        .indexTip: .indexTip,
        .middleMCP: .middleMCP,
        .middlePIP: .middlePIP,
        .middleDIP: .middleDIP,
        .middleTip: .middleTip,
        .ringMCP: .ringMCP,
        .ringPIP: .ringPIP,
        .ringDIP: .ringDIP,
        .ringTip: .ringTip,
        .littleMCP: .littleMCP,
        .littlePIP: .littlePIP,
        .littleDIP: .littleDIP,
        .littleTip: .littleTip
    ]
}
