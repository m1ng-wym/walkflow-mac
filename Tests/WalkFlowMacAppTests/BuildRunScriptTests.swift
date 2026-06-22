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

    func testBuildAndStageSignsAfterStagingWhenIdentityIsConfigured() throws {
        let script = try buildRunScript()
        let functionBody = try function(named: "build_and_stage_app", in: script)

        let buildRange = try XCTUnwrap(functionBody.range(of: "build_app"))
        let stageRange = try XCTUnwrap(functionBody.range(of: "stage_bundle"))
        let signRange = try XCTUnwrap(functionBody.range(of: "sign_staged_app_if_configured"))
        XCTAssertLessThan(buildRange.lowerBound, stageRange.lowerBound)
        XCTAssertLessThan(stageRange.lowerBound, signRange.lowerBound)

        XCTAssertTrue(script.contains("WALKFLOW_CODESIGN_IDENTITY"))
        XCTAssertTrue(script.contains("WALKFLOW_CODESIGN_KEYCHAIN"))
        XCTAssertTrue(script.contains("WalkFlowMac.debug.entitlements"))
        XCTAssertTrue(script.contains("/usr/bin/security find-identity -p codesigning -v"))
        XCTAssertTrue(script.contains("/usr/bin/codesign"))
    }

    func testDebugEntitlementsAllowLocalSelfSignedFrameworkLoading() throws {
        let entitlements = try debugEntitlements()

        XCTAssertTrue(entitlements.contains("com.apple.security.get-task-allow"))
        XCTAssertTrue(entitlements.contains("com.apple.security.cs.disable-library-validation"))
    }

    func testDebugEntitlementsAllowCameraAccessUnderHardenedRuntime() throws {
        let entitlements = try debugEntitlements()

        XCTAssertTrue(entitlements.contains("com.apple.security.device.camera"))
    }

    func testDebugEntitlementsStayMinimalForLocalDevelopment() throws {
        let entitlements = try debugEntitlementsDictionary()

        XCTAssertEqual(
            Set(entitlements.keys),
            [
                "com.apple.security.get-task-allow",
                "com.apple.security.cs.disable-library-validation",
                "com.apple.security.device.camera"
            ]
        )
    }

    func testBuildScriptLoadsLocalSigningEnvBeforeReadingCodesignVariables() throws {
        let script = try buildRunScript()

        let envRange = try XCTUnwrap(script.range(of: ".walkflow-local-signing.env"))
        let sourceRange = try XCTUnwrap(script.range(of: "source \"$LOCAL_SIGNING_ENV\""))
        let identityRange = try XCTUnwrap(script.range(of: "CODESIGN_IDENTITY=\"${WALKFLOW_CODESIGN_IDENTITY:-}\""))
        let requireRange = try XCTUnwrap(script.range(of: "REQUIRE_CERT_SIGNING=\"${WALKFLOW_REQUIRE_CERT_SIGNING:-0}\""))

        XCTAssertLessThan(envRange.lowerBound, identityRange.lowerBound)
        XCTAssertLessThan(sourceRange.lowerBound, identityRange.lowerBound)
        XCTAssertLessThan(sourceRange.lowerBound, requireRange.lowerBound)
    }

    func testCertificateSigningCanBeRequiredForVerification() throws {
        let script = try buildRunScript()
        let buildBody = try function(named: "build_and_stage_app", in: script)
        let preflightBody = try function(named: "preflight_codesign_configuration", in: script)

        XCTAssertTrue(script.contains("WALKFLOW_REQUIRE_CERT_SIGNING"))
        XCTAssertTrue(buildBody.contains("preflight_codesign_configuration"))
        XCTAssertTrue(preflightBody.contains("REQUIRE_CERT_SIGNING"))
        XCTAssertTrue(preflightBody.contains("Certificate-backed signing is required"))
    }

    func testUnsignedDebugPathRepairsAdHocSignatureAfterRpathChange() throws {
        let script = try buildRunScript()
        let signBody = try function(named: "sign_staged_app_if_configured", in: script)
        let adHocBody = try function(named: "sign_ad_hoc_debug_bundle", in: script)

        XCTAssertTrue(signBody.contains("sign_ad_hoc_debug_bundle"))
        XCTAssertTrue(adHocBody.contains("--sign -"))
        XCTAssertTrue(adHocBody.contains("verify_debug_ad_hoc_app_bundle"))
    }

    func testConfiguredSigningVerifiesNestedCodeAndRejectsCdhashOnlyRequirements() throws {
        let script = try buildRunScript()
        let signBody = try function(named: "sign_staged_app_if_configured", in: script)
        let verifyBody = try function(named: "verify_signed_app_bundle", in: script)

        let validateRange = try XCTUnwrap(signBody.range(of: "validate_codesign_identity"))
        let signNestedRange = try XCTUnwrap(signBody.range(of: "sign_nested_code"))
        let signAppRange = try XCTUnwrap(signBody.range(of: "sign_app_bundle"))
        let verifyRange = try XCTUnwrap(signBody.range(of: "verify_signed_app_bundle"))
        XCTAssertLessThan(validateRange.lowerBound, signNestedRange.lowerBound)
        XCTAssertLessThan(signNestedRange.lowerBound, signAppRange.lowerBound)
        XCTAssertLessThan(signAppRange.lowerBound, verifyRange.lowerBound)

        XCTAssertTrue(verifyBody.contains("verify_nested_code"))
        XCTAssertTrue(verifyBody.contains("designated => cdhash"))
    }

    func testIdentityValidationAvoidsSubstringMatching() throws {
        let script = try buildRunScript()
        let validationBody = try function(named: "validate_codesign_identity", in: script)

        XCTAssertFalse(validationBody.contains("grep -F -- \"$CODESIGN_IDENTITY\""))
        XCTAssertTrue(script.contains("matches_codesign_identity"))
    }

    func testMissingIdentityMessagePointsToLocalSigningSetup() throws {
        let script = try buildRunScript()
        let validationBody = try function(named: "validate_codesign_identity", in: script)

        XCTAssertTrue(validationBody.contains("./script/setup_local_signing.sh"))
        XCTAssertTrue(validationBody.contains(".walkflow-local-signing.env"))
        XCTAssertFalse(validationBody.contains("Apple Development signing identity first"))
    }

    func testStageBundleUsesStandardSignedResourceLocation() throws {
        let script = try buildRunScript()
        let stageBody = try function(named: "stage_bundle", in: script)

        XCTAssertTrue(script.contains("FRAMEWORKS_DIR=\"$BUNDLE_PATH/Contents/Frameworks\""))
        XCTAssertTrue(stageBody.contains("$FRAMEWORKS_DIR"))
        XCTAssertTrue(stageBody.contains("Contents/Resources/Lottie"))
        XCTAssertFalse(stageBody.contains("\"$BUNDLE_PATH/Contents/MacOS/\""))
        XCTAssertFalse(stageBody.contains("\"$BUNDLE_PATH/\""))
        XCTAssertTrue(script.contains("@executable_path/../Frameworks"))
        XCTAssertTrue(script.contains("$BUNDLE_PATH/Contents/Resources/Lottie/alertTriangle.json"))
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

    private func debugEntitlements() throws -> String {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let entitlementsURL = root.appendingPathComponent("script/WalkFlowMac.debug.entitlements")
        return try String(contentsOf: entitlementsURL, encoding: .utf8)
    }

    private func debugEntitlementsDictionary() throws -> [String: Any] {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let entitlementsURL = root.appendingPathComponent("script/WalkFlowMac.debug.entitlements")
        let data = try Data(contentsOf: entitlementsURL)
        let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        return try XCTUnwrap(plist as? [String: Any])
    }

    private func caseBranch(named label: String, in script: String) throws -> Substring {
        let branchStart = try XCTUnwrap(script.range(of: label))
        let afterBranch = script[branchStart.upperBound...]
        let nextBranch = try XCTUnwrap(afterBranch.range(of: ";;"))
        return afterBranch[..<nextBranch.lowerBound]
    }

    private func function(named name: String, in script: String) throws -> Substring {
        let functionStart = try XCTUnwrap(script.range(of: "\(name)() {"))
        let afterFunction = script[functionStart.upperBound...]
        let functionEnd = try XCTUnwrap(afterFunction.range(of: "\n}"))
        return afterFunction[..<functionEnd.lowerBound]
    }
}
