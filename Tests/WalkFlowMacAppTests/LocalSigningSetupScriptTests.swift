import Foundation
import XCTest

final class LocalSigningSetupScriptTests: XCTestCase {
    func testSetupScriptCreatesAndPersistsLocalCodeSigningIdentityConfiguration() throws {
        let script = try localSigningScript()

        XCTAssertTrue(script.contains("WalkFlow Local Development"))
        XCTAssertTrue(script.contains("extendedKeyUsage = codeSigning"))
        XCTAssertTrue(script.contains("pkcs12"))
        XCTAssertTrue(script.contains("-legacy"))
        XCTAssertTrue(script.contains("-export"))
        XCTAssertTrue(script.contains("/usr/bin/security import"))
        XCTAssertTrue(script.contains("/usr/bin/security add-trusted-cert -r trustRoot -p codeSign"))
        XCTAssertTrue(script.contains("/usr/bin/security find-identity -p codesigning -v"))
        XCTAssertTrue(script.contains("identity_exists"))
        XCTAssertTrue(script.contains("exists but is not a valid code signing identity"))
        XCTAssertTrue(script.contains(".walkflow-local-signing.env"))
        XCTAssertTrue(script.contains("WALKFLOW_REQUIRE_CERT_SIGNING=1"))
        XCTAssertTrue(script.contains("WALKFLOW_CODESIGN_IDENTITY"))
    }

    func testSetupScriptWritesLocalEnvOnlyAfterNewIdentityIsValid() throws {
        let script = try localSigningScript()
        let createBranch = try substring(
            in: script,
            from: "echo \"Creating local self-signed Code Signing identity:",
            to: "print_next_steps"
        )

        let createRange = try XCTUnwrap(createBranch.range(of: "create_identity"))
        let verifyRange = try XCTUnwrap(createBranch.range(of: "verify_identity"))
        let writeRange = try XCTUnwrap(createBranch.range(of: "write_local_env"))

        XCTAssertLessThan(createRange.lowerBound, verifyRange.lowerBound)
        XCTAssertLessThan(verifyRange.lowerBound, writeRange.lowerBound)
    }

    func testSetupScriptSuccessOutputStatesLocalDevelopmentOnly() throws {
        let script = try localSigningScript()

        XCTAssertTrue(script.contains("local development only"))
        XCTAssertTrue(script.contains("not for distribution"))
        XCTAssertTrue(script.contains("notarization"))
    }

    func testSetupScriptUsesRestrictiveUmaskForGeneratedSigningMaterial() throws {
        let script = try localSigningScript()
        let createIdentity = try substring(in: script, from: "create_identity() {", to: "\n}")

        let umaskRange = try XCTUnwrap(createIdentity.range(of: "umask 077"))
        let opensslRange = try XCTUnwrap(createIdentity.range(of: "openssl req"))
        XCTAssertLessThan(umaskRange.lowerBound, opensslRange.lowerBound)
    }

    func testSetupScriptHelpAndSyntaxAreExecutableWithoutKeychainMutation() throws {
        try runCommand(["/bin/bash", "-n", "script/setup_local_signing.sh"])
        try runCommand(["/bin/bash", "-n", "script/build_and_run.sh"])

        let helpOutput = try runCommand(["./script/setup_local_signing.sh", "--help"])
        XCTAssertTrue(helpOutput.contains("usage:"))
        XCTAssertTrue(helpOutput.contains("WALKFLOW_LOCAL_SIGNING_IDENTITY"))
    }

    func testLocalSigningEnvIsIgnoredByGit() throws {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let gitignoreURL = root.appendingPathComponent(".gitignore")
        let gitignore = try String(contentsOf: gitignoreURL, encoding: .utf8)

        XCTAssertTrue(gitignore.contains(".walkflow-local-signing.env"))
    }

    func testLocalSigningDocumentationStatesDevelopmentOnlyBoundary() throws {
        let document = try localSigningDocument()

        XCTAssertTrue(document.contains("本地开发"))
        XCTAssertTrue(document.contains("分发"))
        XCTAssertTrue(document.contains("notarization"))
    }

    func testRepositoryReadmeLinksLocalSigningQuickStart() throws {
        let readme = try repositoryReadme()

        XCTAssertTrue(readme.contains("./script/setup_local_signing.sh"))
        XCTAssertTrue(readme.contains("./script/build_and_run.sh --verify"))
        XCTAssertTrue(readme.contains("docs/LOCAL_SIGNING.md"))
    }

    private func localSigningScript() throws -> String {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let scriptURL = root.appendingPathComponent("script/setup_local_signing.sh")
        return try String(contentsOf: scriptURL, encoding: .utf8)
    }

    private func localSigningDocument() throws -> String {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let documentURL = root.appendingPathComponent("docs/LOCAL_SIGNING.md")
        return try String(contentsOf: documentURL, encoding: .utf8)
    }

    private func repositoryReadme() throws -> String {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let readmeURL = root.appendingPathComponent("README.md")
        return try String(contentsOf: readmeURL, encoding: .utf8)
    }

    private func substring(in string: String, from start: String, to end: String) throws -> Substring {
        let startRange = try XCTUnwrap(string.range(of: start))
        let afterStart = string[startRange.lowerBound...]
        let endRange = try XCTUnwrap(afterStart.range(of: end))
        return afterStart[..<endRange.upperBound]
    }

    @discardableResult
    private func runCommand(_ arguments: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: arguments[0])
        process.arguments = Array(arguments.dropFirst())
        process.currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        XCTAssertEqual(process.terminationStatus, 0, output)
        return output
    }
}
