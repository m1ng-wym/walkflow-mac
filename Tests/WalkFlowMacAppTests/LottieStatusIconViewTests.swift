import XCTest
import Lottie
@testable import WalkFlowCore
@testable import WalkFlowMacApp

final class LottieStatusIconViewTests: XCTestCase {
    func testResourceLocatorPrefersStandardMainBundleResourcePath() throws {
        let tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("WalkFlowLottieResourceLocatorTests")
            .appendingPathComponent(UUID().uuidString)
        let mainBundleURL = tempRoot.appendingPathComponent("Main.bundle")
        let moduleBundleURL = tempRoot.appendingPathComponent("Module.bundle")
        let mainLottieDirectory = mainBundleURL.appendingPathComponent("Lottie")
        let moduleLottieDirectory = moduleBundleURL.appendingPathComponent("Lottie")

        try FileManager.default.createDirectory(at: mainLottieDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: moduleLottieDirectory, withIntermediateDirectories: true)
        let mainResource = mainLottieDirectory.appendingPathComponent("alertTriangle.json")
        let moduleResource = moduleLottieDirectory.appendingPathComponent("alertTriangle.json")
        try "{}".write(to: mainResource, atomically: true, encoding: .utf8)
        try "{}".write(to: moduleResource, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempRoot) }

        let url = try XCTUnwrap(
            LottieResourceLocator.resourceURL(
                forResourceName: "alertTriangle",
                mainBundle: try XCTUnwrap(Bundle(url: mainBundleURL)),
                moduleBundle: try XCTUnwrap(Bundle(url: moduleBundleURL))
            )
        )

        XCTAssertEqual(url.standardizedFileURL, mainResource.standardizedFileURL)
    }

    func testResourceLocatorFallsBackToSwiftPMModuleBundle() throws {
        let tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("WalkFlowLottieResourceLocatorTests")
            .appendingPathComponent(UUID().uuidString)
        let mainBundleURL = tempRoot.appendingPathComponent("Main.bundle")
        let moduleBundleURL = tempRoot.appendingPathComponent("Module.bundle")
        let moduleLottieDirectory = moduleBundleURL.appendingPathComponent("Lottie")

        try FileManager.default.createDirectory(at: mainBundleURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: moduleLottieDirectory, withIntermediateDirectories: true)
        let moduleResource = moduleLottieDirectory.appendingPathComponent("alertTriangle.json")
        try "{}".write(to: moduleResource, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempRoot) }

        let url = try XCTUnwrap(
            LottieResourceLocator.resourceURL(
                forResourceName: "alertTriangle",
                mainBundle: try XCTUnwrap(Bundle(url: mainBundleURL)),
                moduleBundle: try XCTUnwrap(Bundle(url: moduleBundleURL))
            )
        )

        XCTAssertEqual(url.standardizedFileURL, moduleResource.standardizedFileURL)
    }

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
