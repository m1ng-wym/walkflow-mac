import AppKit
import XCTest
@testable import WalkFlowMacApp

final class HUDViewTests: XCTestCase {
    func testArrowLayoutStaysInsideViewBounds() {
        let bounds = NSRect(x: 0, y: 0, width: 160, height: 110)

        for point in HUDView.arrowPoints(in: bounds) {
            XCTAssertTrue(bounds.contains(point), "Expected \(point) to stay inside \(bounds)")
        }
    }

    func testPanelBodyLeavesRoomForArrow() {
        let bounds = NSRect(x: 0, y: 0, width: 160, height: 110)

        XCTAssertLessThan(HUDView.panelRect(in: bounds).maxY, bounds.maxY)
    }
}
