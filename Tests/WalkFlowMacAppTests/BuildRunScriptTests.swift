import Foundation
import XCTest

final class BuildRunScriptTests: XCTestCase {
    func testLaunchExistingModeDoesNotRebuildOrRestageBeforeModeDispatch() throws {
        let script = try buildRunScript()

        XCTAssertTrue(script.contains("--launch-existing|launch-existing)"))

        let caseRange = try XCTUnwrap(script.range(of: "case \"$MODE\" in"))
        let preDispatch = script[..<caseRange.lowerBound]
        XCTAssertFalse(preDispatch.contains("build_app\nstage_bundle"))

        let launchExistingBranch = try caseBranch(named: "--launch-existing|launch-existing)", in: script)
        XCTAssertFalse(launchExistingBranch.contains("build_and_stage_app"))
        XCTAssertFalse(launchExistingBranch.contains("build_app"))
        XCTAssertFalse(launchExistingBranch.contains("stage_bundle"))
        XCTAssertTrue(launchExistingBranch.contains("launch_existing_app"))
    }

    func testRebuildModesStillBuildAndStageBeforeLaunch() throws {
        let script = try buildRunScript()

        for mode in ["run)", "--verify|verify)", "--logs|logs)", "--telemetry|telemetry)"] {
            let branch = try caseBranch(named: mode, in: script)
            XCTAssertTrue(branch.contains("build_and_stage_app"), "Expected \(mode) to build and stage before launch.")
        }
    }

    func testDebugModeStopsRunningAppBeforeBuilding() throws {
        let script = try buildRunScript()

        let debugBranch = try caseBranch(named: "--debug|debug)", in: script)

        let stopRange = try XCTUnwrap(debugBranch.range(of: "stop_app"))
        let buildRange = try XCTUnwrap(debugBranch.range(of: "build_and_stage_app"))
        XCTAssertLessThan(stopRange.lowerBound, buildRange.lowerBound)
    }

    private func buildRunScript() throws -> String {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let scriptURL = root.appendingPathComponent("script/build_and_run.sh")
        return try String(contentsOf: scriptURL, encoding: .utf8)
    }

    private func caseBranch(named label: String, in script: String) throws -> Substring {
        let branchStart = try XCTUnwrap(script.range(of: label))
        let afterBranch = script[branchStart.upperBound...]
        let nextBranch = try XCTUnwrap(afterBranch.range(of: ";;"))
        return afterBranch[..<nextBranch.lowerBound]
    }
}
