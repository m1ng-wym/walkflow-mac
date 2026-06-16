import XCTest
import Lottie
@testable import WalkFlowCore
@testable import WalkFlowMacApp

final class LottieStatusIconViewTests: XCTestCase {
    func testResourceNamesMatchBundledUseAnimationsFiles() {
        XCTAssertNil(LottieStatusIconView.resourceName(for: .none))
        XCTAssertEqual(LottieStatusIconView.resourceName(for: .alertTriangle), "alertTriangle")
        XCTAssertEqual(LottieStatusIconView.resourceName(for: .infinity), "infinity")
        XCTAssertEqual(LottieStatusIconView.resourceName(for: .arrowUp), "arrowUp")
        XCTAssertEqual(LottieStatusIconView.resourceName(for: .arrowDown), "arrowDown")
        XCTAssertEqual(LottieStatusIconView.resourceName(for: .dribbble), "dribbble")
        XCTAssertEqual(LottieStatusIconView.resourceName(for: .lock), "lock")
        XCTAssertEqual(LottieStatusIconView.resourceName(for: .unlockOnce), "lock")
    }

    func testBundledResourcesExistForMappedIcons() throws {
        let icons: [HUDIcon] = [
            .alertTriangle,
            .infinity,
            .arrowUp,
            .arrowDown,
            .dribbble,
            .lock,
            .unlockOnce
        ]

        for icon in icons {
            let resourceName = try XCTUnwrap(LottieStatusIconView.resourceName(for: icon))
            let url = try XCTUnwrap(
                LottieStatusIconView.resourceURL(for: icon),
                "Missing bundled Lottie resource for \(resourceName)"
            )

            XCTAssertEqual(url.pathExtension, "json")
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        }
    }

    func testInitialViewStartsEmptyAndHidden() {
        let view = LottieStatusIconView(frame: NSRect(x: 0, y: 0, width: 64, height: 64))

        XCTAssertEqual(view.currentIcon, .none)
        XCTAssertFalse(view.hasLoadedAnimation)
        XCTAssertFalse(view.isAnimationVisible)
    }

    func testShowConfiguresLoopingAndOneShotAnimations() {
        let view = LottieStatusIconView(frame: NSRect(x: 0, y: 0, width: 64, height: 64))

        view.show(icon: .arrowUp)

        XCTAssertEqual(view.currentIcon, .arrowUp)
        XCTAssertTrue(view.hasLoadedAnimation)
        XCTAssertTrue(view.isAnimationVisible)
        XCTAssertEqual(view.currentLoopMode, .loop)

        view.show(icon: .unlockOnce)

        XCTAssertEqual(view.currentIcon, .unlockOnce)
        XCTAssertTrue(view.hasLoadedAnimation)
        XCTAssertTrue(view.isAnimationVisible)
        XCTAssertEqual(view.currentLoopMode, .playOnce)

        view.show(icon: .none)

        XCTAssertEqual(view.currentIcon, .none)
        XCTAssertFalse(view.hasLoadedAnimation)
        XCTAssertFalse(view.isAnimationVisible)
    }

    func testAllMappedIconsLoadThroughNativeRenderer() {
        let view = LottieStatusIconView(frame: NSRect(x: 0, y: 0, width: 64, height: 64))
        let icons: [HUDIcon] = [.alertTriangle, .infinity, .arrowUp, .arrowDown, .dribbble, .lock, .unlockOnce]

        for icon in icons {
            view.show(icon: icon)

            XCTAssertEqual(view.currentIcon, icon)
            XCTAssertTrue(view.hasLoadedAnimation, "Expected native Lottie renderer to parse \(icon)")
            XCTAssertTrue(view.isAnimationVisible)
        }
    }

    func testFailedAnimationParseClearsAndAllowsRetryForSameIcon() {
        var shouldLoad = false
        let view = LottieStatusIconView(
            frame: NSRect(x: 0, y: 0, width: 64, height: 64),
            animationLoader: { url in
                shouldLoad ? LottieAnimation.filepath(url.path) : nil
            }
        )

        view.show(icon: .arrowUp)

        XCTAssertEqual(view.currentIcon, .none)
        XCTAssertFalse(view.hasLoadedAnimation)
        XCTAssertFalse(view.isAnimationVisible)

        shouldLoad = true
        view.show(icon: .arrowUp)

        XCTAssertEqual(view.currentIcon, .arrowUp)
        XCTAssertTrue(view.hasLoadedAnimation)
        XCTAssertTrue(view.isAnimationVisible)
    }
}
