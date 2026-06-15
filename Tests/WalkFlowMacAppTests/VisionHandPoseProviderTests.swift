import Vision
import XCTest
@testable import WalkFlowCore
@testable import WalkFlowMacApp

final class VisionHandPoseProviderTests: XCTestCase {
    func testVisionJointMapCoversAllCoreHandJoints() {
        XCTAssertEqual(VisionHandPoseProvider.jointMap.count, HandJointName.allCases.count)
        XCTAssertEqual(Set(VisionHandPoseProvider.jointMap.values), Set(HandJointName.allCases))
        XCTAssertEqual(VisionHandPoseProvider.jointMap[.wrist], .wrist)
        XCTAssertEqual(VisionHandPoseProvider.jointMap[.thumbTip], .thumbTip)
        XCTAssertEqual(VisionHandPoseProvider.jointMap[.indexTip], .indexTip)
        XCTAssertEqual(VisionHandPoseProvider.jointMap[.middleTip], .middleTip)
        XCTAssertEqual(VisionHandPoseProvider.jointMap[.ringTip], .ringTip)
        XCTAssertEqual(VisionHandPoseProvider.jointMap[.littleTip], .littleTip)
    }
}
