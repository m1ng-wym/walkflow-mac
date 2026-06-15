import XCTest
@testable import WalkFlowCore

final class GestureStateMachineTests: XCTestCase {
    func testGestureKindEquatableSmoke() {
        XCTAssertEqual(GestureKind.openPalm, GestureKind.openPalm)
        XCTAssertNotEqual(GestureKind.openPalm, GestureKind.fist)
    }
}
