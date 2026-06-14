# WalkFlow-Mac App Bootstrap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Project rule override: local `git commit` does not require additional user approval; `git push`, deploy, and destructive git operations must stop for explicit user confirmation. Destructive git operations are prohibited by default.

**Goal:** Build the first AppKit-only macOS app bootstrap for `WalkFlow-Mac`: camera preview, Vision hand-pose recognition, gesture classification, state machine, scroll/right-Command event output, menu bar controls, pinned HUD, permissions, settings, and verification hooks.

**Architecture:** Use a SwiftPM macOS GUI app with a testable `WalkFlowCore` library and an AppKit `WalkFlowMacApp` executable. `AVFoundation` feeds camera frames to Apple Vision; Vision landmarks are normalized into core hand-pose snapshots; `GestureClassifier` emits gesture candidates; `GestureStateMachine` emits actions and HUD states; AppKit controllers render the main window, menu bar, HUD, and camera preview; `CGEvent`/Accessibility executes system actions.

**Tech Stack:** SwiftPM, Swift, AppKit, AVFoundation, Vision, CoreGraphics, ApplicationServices, Carbon.HIToolbox, UserDefaults, XCTest, Airbnb Lottie via `https://github.com/airbnb/lottie-spm.git`, useAnimations Lottie JSON from `react-useanimations@2.10.0`.

---

## Execution Rules

- All paths are relative to `/Users/Zhuanz/Documents/Magic-tool`.
- Project name is `WalkFlow-Mac`.
- GitHub remote is `https://github.com/m1ng-wym/walkflow-mac.git`.
- Default branch is `main`.
- Do not use SwiftUI in source code, tests, examples, or docs snippets.
- Do not add cloud inference, paid APIs, backend services, analytics, accounts, or provider integrations.
- Do not add MediaPipe to the default runtime. Only run the MediaPipe spike if the Vision verification gate fails.
- Do not put real camera frames, screenshots, or private recordings into git.
- Local checkpoint commits are allowed without additional user approval when they only include task-scoped changes.
- Do not push or deploy without asking the user first.
- Do not run destructive git operations such as `git reset --hard`, `git clean`, force-push, force-overwrite, or rollback of unconfirmed work. If the user explicitly asks for one, stop and reconfirm exact scope before taking action.
- Prefer `rg`, `swift test`, `swift build`, and `./script/build_and_run.sh` as the working commands.

## Planned File Structure

```text
Package.swift
script/build_and_run.sh
script/fetch_useanimations_assets.sh
.codex/environments/environment.toml
Sources/WalkFlowCore/Domain/GestureTypes.swift
Sources/WalkFlowCore/Domain/HandPoseSnapshot.swift
Sources/WalkFlowCore/Domain/AppSettings.swift
Sources/WalkFlowCore/Domain/HUDTypes.swift
Sources/WalkFlowCore/Domain/PermissionTypes.swift
Sources/WalkFlowCore/Domain/EventTypes.swift
Sources/WalkFlowCore/Time/Clock.swift
Sources/WalkFlowCore/Gesture/GestureClassifier.swift
Sources/WalkFlowCore/Gesture/GestureStateMachine.swift
Sources/WalkFlowCore/HUD/HUDStateReducer.swift
Sources/WalkFlowCore/Settings/SettingsStore.swift
Sources/WalkFlowCore/Diagnostics/RecognitionMetrics.swift
Sources/WalkFlowMacApp/main.swift
Sources/WalkFlowMacApp/App/AppDelegate.swift
Sources/WalkFlowMacApp/App/AppController.swift
Sources/WalkFlowMacApp/App/AppStateStore.swift
Sources/WalkFlowMacApp/Camera/CameraPreviewView.swift
Sources/WalkFlowMacApp/Camera/CameraSessionController.swift
Sources/WalkFlowMacApp/Vision/VisionHandPoseProvider.swift
Sources/WalkFlowMacApp/Events/CGEventOutput.swift
Sources/WalkFlowMacApp/Permissions/SystemPermissionService.swift
Sources/WalkFlowMacApp/UI/MainWindowController.swift
Sources/WalkFlowMacApp/UI/ControlPanelView.swift
Sources/WalkFlowMacApp/UI/PermissionPanelView.swift
Sources/WalkFlowMacApp/UI/PreviewContainerView.swift
Sources/WalkFlowMacApp/UI/HUDView.swift
Sources/WalkFlowMacApp/UI/HUDWindowController.swift
Sources/WalkFlowMacApp/UI/MenuBarController.swift
Sources/WalkFlowMacApp/UI/LottieStatusIconView.swift
Sources/WalkFlowMacApp/Resources/Info.plist
Sources/WalkFlowMacApp/Resources/Lottie/alertTriangle.json
Sources/WalkFlowMacApp/Resources/Lottie/arrowDown.json
Sources/WalkFlowMacApp/Resources/Lottie/arrowUp.json
Sources/WalkFlowMacApp/Resources/Lottie/dribbble.json
Sources/WalkFlowMacApp/Resources/Lottie/infinity.json
Sources/WalkFlowMacApp/Resources/Lottie/lock.json
Docs/THIRD_PARTY_NOTICES.md
Tests/WalkFlowCoreTests/GestureStateMachineTests.swift
Tests/WalkFlowCoreTests/GestureClassifierTests.swift
Tests/WalkFlowCoreTests/HUDStateReducerTests.swift
Tests/WalkFlowCoreTests/SettingsStoreTests.swift
Tests/WalkFlowCoreTests/RecognitionMetricsTests.swift
```

## Phase 0: Preflight And Safety Gates

### Task 0.1: Confirm execution baseline

**Files:**
- Read: `AGENTS.md`
- Read: `docs/superpowers/specs/2026-06-14-gesture-control-macos-app-design.md`
- Read: `docs/tasks/001-gesture-control-macos-app-bootstrap/task.md`
- Read: `docs/tasks/001-gesture-control-macos-app-bootstrap/plan.md`
- Read: `docs/tasks/001-gesture-control-macos-app-bootstrap/progress.md`
- Read: `docs/tasks/001-gesture-control-macos-app-bootstrap/review.md`

- [ ] **Step 1: Verify repository state**

Run:

```bash
pwd
git status --short --branch
find . -name '*.xcworkspace' -o -name '*.xcodeproj' -o -name 'Package.swift'
```

Expected:

```text
/Users/Zhuanz/Documents/Magic-tool
Current branch: main
```

`git status --short --branch` must show the current branch as `main`. The `find` command should show no app project before app bootstrap begins. If it shows an app project, stop and inspect before creating new files.

- [ ] **Step 2: Confirm implementation mode**

Ask the user to choose execution mode after this plan is accepted:

```text
Plan is ready in docs/tasks/001-gesture-control-macos-app-bootstrap/plan.md.
Execution options:
1. Subagent-driven implementation
2. Inline implementation in this thread
Which mode should I use?
```

- [ ] **Step 3: Commit and destructive-git gate**

If a task says "checkpoint", local commit is allowed after checking the diff. Run this first:

```bash
git status --short
git diff --stat
```

Only commit task-scoped files. Do not push. Do not run destructive git operations.

## Phase 1: Bootstrap Buildable AppKit Project

### Task 1.1: Create SwiftPM package with AppKit executable and core library

**Files:**
- Create: `Package.swift`
- Create: `Sources/WalkFlowCore/Domain/GestureTypes.swift`
- Create: `Sources/WalkFlowMacApp/main.swift`
- Create: `Sources/WalkFlowMacApp/App/AppDelegate.swift`
- Create: `Sources/WalkFlowMacApp/Resources/Info.plist`
- Create: `Tests/WalkFlowCoreTests/GestureStateMachineTests.swift`

- [ ] **Step 1: Write the SwiftPM manifest**

Create `Package.swift`:

```swift
// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "WalkFlowMac",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "WalkFlowCore", targets: ["WalkFlowCore"]),
        .executable(name: "WalkFlowMac", targets: ["WalkFlowMacApp"])
    ],
    dependencies: [
        .package(url: "https://github.com/airbnb/lottie-spm.git", from: "4.6.1")
    ],
    targets: [
        .target(
            name: "WalkFlowCore"
        ),
        .executableTarget(
            name: "WalkFlowMacApp",
            dependencies: [
                "WalkFlowCore",
                .product(name: "Lottie", package: "lottie-spm")
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "WalkFlowCoreTests",
            dependencies: ["WalkFlowCore"]
        )
    ]
)
```

- [ ] **Step 2: Create the smallest core type**

Create `Sources/WalkFlowCore/Domain/GestureTypes.swift`:

```swift
import Foundation

public enum GestureKind: Equatable, Sendable {
    case none
    case openPalm
    case indexUp
    case indexDown
    case fist
    case okPinch
    case handLost
}
```

- [ ] **Step 3: Create the AppKit entry point**

Create `Sources/WalkFlowMacApp/main.swift`:

```swift
import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
```

Create `Sources/WalkFlowMacApp/App/AppDelegate.swift`:

```swift
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 960, height: 600))
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        let window = NSWindow(
            contentRect: contentView.frame,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "WalkFlow-Mac"
        window.contentView = contentView
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = window
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
```

- [ ] **Step 4: Create bundle metadata**

Create `Sources/WalkFlowMacApp/Resources/Info.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleExecutable</key>
    <string>WalkFlowMac</string>
    <key>CFBundleIdentifier</key>
    <string>com.m1ngwym.walkflowmac</string>
    <key>CFBundleName</key>
    <string>WalkFlow-Mac</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSCameraUsageDescription</key>
    <string>WalkFlow-Mac uses the camera to recognize hand gestures for remote control.</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
```

- [ ] **Step 5: Add the first compile test**

Create `Tests/WalkFlowCoreTests/GestureStateMachineTests.swift`:

```swift
import XCTest
@testable import WalkFlowCore

final class GestureStateMachineTests: XCTestCase {
    func testGestureKindEquatableSmoke() {
        XCTAssertEqual(GestureKind.openPalm, GestureKind.openPalm)
        XCTAssertNotEqual(GestureKind.openPalm, GestureKind.fist)
    }
}
```

- [ ] **Step 6: Run tests and build**

Run:

```bash
swift test
swift build
```

Expected: both commands exit successfully.

### Task 1.2: Add Build macOS Apps run script and Codex Run action

**Files:**
- Create: `script/build_and_run.sh`
- Create: `.codex/environments/environment.toml`

- [ ] **Step 1: Create the script**

Create `script/build_and_run.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

APP_NAME="WalkFlowMac"
BUNDLE_NAME="WalkFlow-Mac.app"
BUNDLE_ID="com.m1ngwym.walkflowmac"
CONFIGURATION="debug"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
BUNDLE_PATH="$DIST_DIR/$BUNDLE_NAME"
EXECUTABLE_PATH="$BUNDLE_PATH/Contents/MacOS/$APP_NAME"
INFO_PLIST_SOURCE="$ROOT_DIR/Sources/WalkFlowMacApp/Resources/Info.plist"

MODE="${1:-}"

stop_app() {
  /usr/bin/pkill -x "$APP_NAME" 2>/dev/null || true
}

stage_bundle() {
  /bin/rm -rf "$BUNDLE_PATH"
  /bin/mkdir -p "$BUNDLE_PATH/Contents/MacOS" "$BUNDLE_PATH/Contents/Resources"
  /bin/cp "$ROOT_DIR/.build/$CONFIGURATION/$APP_NAME" "$EXECUTABLE_PATH"
  /bin/cp "$INFO_PLIST_SOURCE" "$BUNDLE_PATH/Contents/Info.plist"
}

build_app() {
  cd "$ROOT_DIR"
  /usr/bin/swift build -c "$CONFIGURATION" --product "$APP_NAME"
}

launch_app() {
  /usr/bin/open -n "$BUNDLE_PATH"
}

verify_app() {
  sleep 2
  /usr/bin/pgrep -x "$APP_NAME" >/dev/null
}

stop_app
build_app
stage_bundle
launch_app

case "$MODE" in
  --verify)
    verify_app
    echo "Verified $APP_NAME is running."
    ;;
  --logs)
    /usr/bin/log stream --info --predicate 'process == "WalkFlowMac"'
    ;;
  --telemetry)
    /usr/bin/log stream --info --predicate 'subsystem == "com.m1ngwym.walkflowmac"'
    ;;
  --debug)
    echo "Attach LLDB manually with: lldb -n $APP_NAME"
    ;;
  "")
    ;;
  *)
    echo "Unknown mode: $MODE" >&2
    exit 64
    ;;
esac
```

- [ ] **Step 2: Make the script executable**

Run:

```bash
chmod +x script/build_and_run.sh
```

Expected: no output.

- [ ] **Step 3: Create Codex Run action**

Create `.codex/environments/environment.toml`:

```toml
[[actions]]
name = "Run"
command = "./script/build_and_run.sh --verify"
```

- [ ] **Step 4: Verify launch**

Run:

```bash
./script/build_and_run.sh --verify
```

Expected:

```text
Verified WalkFlowMac is running.
```

- [ ] **Step 5: Check local signing metadata**

Run:

```bash
plutil -p "dist/WalkFlow-Mac.app/Contents/Info.plist"
codesign -dvvv --entitlements :- "dist/WalkFlow-Mac.app" 2>&1 | sed -n '1,80p'
```

Expected: `Info.plist` contains `NSCameraUsageDescription`; local signing can be absent or ad hoc at this stage. Record exact signing output in `review.md`.

- [ ] **Step 6: Checkpoint**

Commit the task-scoped bootstrap files after reviewing `git status --short`:

```bash
git add Package.swift script/build_and_run.sh .codex/environments/environment.toml Sources Tests
git commit -m "chore: bootstrap AppKit macOS app"
```

## Phase 2: Core Domain, Settings, And State Reducers

### Task 2.1: Define stable domain types

**Files:**
- Create: `Sources/WalkFlowCore/Domain/HandPoseSnapshot.swift`
- Create: `Sources/WalkFlowCore/Domain/AppSettings.swift`
- Create: `Sources/WalkFlowCore/Domain/HUDTypes.swift`
- Create: `Sources/WalkFlowCore/Domain/PermissionTypes.swift`
- Create: `Sources/WalkFlowCore/Domain/EventTypes.swift`
- Modify: `Sources/WalkFlowCore/Domain/GestureTypes.swift`

- [ ] **Step 1: Add hand-pose value types**

Create `Sources/WalkFlowCore/Domain/HandPoseSnapshot.swift`:

```swift
import Foundation

public enum HandJointName: String, CaseIterable, Sendable {
    case wrist
    case thumbCMC
    case thumbMP
    case thumbIP
    case thumbTip
    case indexMCP
    case indexPIP
    case indexDIP
    case indexTip
    case middleMCP
    case middlePIP
    case middleDIP
    case middleTip
    case ringMCP
    case ringPIP
    case ringDIP
    case ringTip
    case littleMCP
    case littlePIP
    case littleDIP
    case littleTip
}

public struct HandPoint: Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var confidence: Double

    public init(x: Double, y: Double, confidence: Double) {
        self.x = x
        self.y = y
        self.confidence = confidence
    }
}

public enum Handedness: Equatable, Sendable {
    case left
    case right
    case unknown
}

public struct HandPoseSnapshot: Equatable, Sendable {
    public var points: [HandJointName: HandPoint]
    public var handedness: Handedness
    public var timestamp: TimeInterval

    public init(points: [HandJointName: HandPoint], handedness: Handedness, timestamp: TimeInterval) {
        self.points = points
        self.handedness = handedness
        self.timestamp = timestamp
    }

    public subscript(_ joint: HandJointName) -> HandPoint? {
        points[joint]
    }
}
```

- [ ] **Step 2: Add settings defaults**

Create `Sources/WalkFlowCore/Domain/AppSettings.swift`:

```swift
import Foundation

public struct GestureTimingSettings: Equatable, Sendable {
    public var readyHoldMilliseconds: Int
    public var scrollHoldMilliseconds: Int
    public var continuousScrollHoldMilliseconds: Int
    public var commandHoldMilliseconds: Int
    public var commandCooldownMilliseconds: Int
    public var controlWindowSeconds: Double

    public static let defaults = GestureTimingSettings(
        readyHoldMilliseconds: 300,
        scrollHoldMilliseconds: 300,
        continuousScrollHoldMilliseconds: 700,
        commandHoldMilliseconds: 300,
        commandCooldownMilliseconds: 1000,
        controlWindowSeconds: 5.0
    )
}

public struct ScrollSettings: Equatable, Sendable {
    public var singleStepDeltaY: Int32
    public var continuousDeltaY: Int32
    public var continuousIntervalMilliseconds: Int

    public static let defaults = ScrollSettings(
        singleStepDeltaY: 6,
        continuousDeltaY: 3,
        continuousIntervalMilliseconds: 80
    )
}

public struct HUDSettings: Equatable, Sendable {
    public var isPinned: Bool
    public var isVisible: Bool
    public var savedOriginX: Double?
    public var savedOriginY: Double?

    public static let defaults = HUDSettings(
        isPinned: true,
        isVisible: true,
        savedOriginX: nil,
        savedOriginY: nil
    )
}

public struct AppSettings: Equatable, Sendable {
    public var gestureTiming: GestureTimingSettings
    public var scroll: ScrollSettings
    public var hud: HUDSettings

    public static let defaults = AppSettings(
        gestureTiming: .defaults,
        scroll: .defaults,
        hud: .defaults
    )
}
```

- [ ] **Step 3: Add HUD and permission types**

Create `Sources/WalkFlowCore/Domain/HUDTypes.swift`:

```swift
import Foundation

public enum HUDDot: Equatable, Sendable {
    case red
    case green
}

public enum HUDIcon: Equatable, Sendable {
    case none
    case lock
    case unlockOnce
    case alertTriangle
    case infinity
    case arrowUp
    case arrowDown
    case dribbble
}

public struct HUDPresentation: Equatable, Sendable {
    public var dot: HUDDot
    public var icon: HUDIcon
    public var message: String

    public init(dot: HUDDot, icon: HUDIcon, message: String) {
        self.dot = dot
        self.icon = icon
        self.message = message
    }
}
```

Create `Sources/WalkFlowCore/Domain/PermissionTypes.swift`:

```swift
import Foundation

public enum PermissionKind: String, CaseIterable, Sendable {
    case camera
    case accessibility
    case inputMonitoring
}

public enum PermissionStatus: Equatable, Sendable {
    case granted
    case denied
    case notDetermined
    case notRequired
}

public struct PermissionSnapshot: Equatable, Sendable {
    public var camera: PermissionStatus
    public var accessibility: PermissionStatus
    public var inputMonitoring: PermissionStatus

    public init(camera: PermissionStatus, accessibility: PermissionStatus, inputMonitoring: PermissionStatus) {
        self.camera = camera
        self.accessibility = accessibility
        self.inputMonitoring = inputMonitoring
    }

    public var canControl: Bool {
        camera == .granted && accessibility == .granted
    }
}
```

Create `Sources/WalkFlowCore/Domain/EventTypes.swift`:

```swift
import Foundation

public enum ControlAction: Equatable, Sendable {
    case none
    case scrollUp(step: ScrollStep)
    case scrollDown(step: ScrollStep)
    case pressRightCommand
    case stopContinuousScroll
}

public enum ScrollStep: Equatable, Sendable {
    case single
    case continuous
}
```

- [ ] **Step 4: Expand gesture observation type**

Modify `Sources/WalkFlowCore/Domain/GestureTypes.swift`:

```swift
import Foundation

public enum GestureKind: Equatable, Sendable {
    case none
    case openPalm
    case indexUp
    case indexDown
    case fist
    case okPinch
    case handLost
}

public struct GestureObservation: Equatable, Sendable {
    public var kind: GestureKind
    public var confidence: Double
    public var timestamp: TimeInterval

    public init(kind: GestureKind, confidence: Double, timestamp: TimeInterval) {
        self.kind = kind
        self.confidence = confidence
        self.timestamp = timestamp
    }
}
```

- [ ] **Step 5: Build**

Run:

```bash
swift test
```

Expected: tests pass.

### Task 2.2: Implement settings persistence

**Files:**
- Create: `Sources/WalkFlowCore/Settings/SettingsStore.swift`
- Create: `Tests/WalkFlowCoreTests/SettingsStoreTests.swift`

- [ ] **Step 1: Write settings tests**

Create `Tests/WalkFlowCoreTests/SettingsStoreTests.swift`:

```swift
import XCTest
@testable import WalkFlowCore

final class SettingsStoreTests: XCTestCase {
    func testDefaultSettingsAreLoadedWhenStoreIsEmpty() {
        let defaults = UserDefaults(suiteName: "SettingsStoreTests.empty")!
        defaults.removePersistentDomain(forName: "SettingsStoreTests.empty")

        let store = SettingsStore(defaults: defaults)

        XCTAssertEqual(store.load(), .defaults)
    }

    func testSavedHUDPositionRoundTrips() {
        let defaults = UserDefaults(suiteName: "SettingsStoreTests.roundtrip")!
        defaults.removePersistentDomain(forName: "SettingsStoreTests.roundtrip")
        let store = SettingsStore(defaults: defaults)

        var settings = AppSettings.defaults
        settings.hud.savedOriginX = 1440
        settings.hud.savedOriginY = 24
        store.save(settings)

        XCTAssertEqual(store.load().hud.savedOriginX, 1440)
        XCTAssertEqual(store.load().hud.savedOriginY, 24)
    }
}
```

- [ ] **Step 2: Run the failing tests**

Run:

```bash
swift test --filter SettingsStoreTests
```

Expected: fails because `SettingsStore` does not exist.

- [ ] **Step 3: Implement settings store**

Create `Sources/WalkFlowCore/Settings/SettingsStore.swift`:

```swift
import Foundation

public final class SettingsStore {
    private enum Key {
        static let readyHoldMilliseconds = "gesture.readyHoldMilliseconds"
        static let scrollHoldMilliseconds = "gesture.scrollHoldMilliseconds"
        static let continuousScrollHoldMilliseconds = "gesture.continuousScrollHoldMilliseconds"
        static let commandHoldMilliseconds = "gesture.commandHoldMilliseconds"
        static let commandCooldownMilliseconds = "gesture.commandCooldownMilliseconds"
        static let controlWindowSeconds = "gesture.controlWindowSeconds"
        static let singleStepDeltaY = "scroll.singleStepDeltaY"
        static let continuousDeltaY = "scroll.continuousDeltaY"
        static let continuousIntervalMilliseconds = "scroll.continuousIntervalMilliseconds"
        static let hudPinned = "hud.isPinned"
        static let hudVisible = "hud.isVisible"
        static let hudSavedOriginX = "hud.savedOriginX"
        static let hudSavedOriginY = "hud.savedOriginY"
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> AppSettings {
        var settings = AppSettings.defaults
        settings.gestureTiming.readyHoldMilliseconds = int(for: Key.readyHoldMilliseconds, default: settings.gestureTiming.readyHoldMilliseconds)
        settings.gestureTiming.scrollHoldMilliseconds = int(for: Key.scrollHoldMilliseconds, default: settings.gestureTiming.scrollHoldMilliseconds)
        settings.gestureTiming.continuousScrollHoldMilliseconds = int(for: Key.continuousScrollHoldMilliseconds, default: settings.gestureTiming.continuousScrollHoldMilliseconds)
        settings.gestureTiming.commandHoldMilliseconds = int(for: Key.commandHoldMilliseconds, default: settings.gestureTiming.commandHoldMilliseconds)
        settings.gestureTiming.commandCooldownMilliseconds = int(for: Key.commandCooldownMilliseconds, default: settings.gestureTiming.commandCooldownMilliseconds)
        settings.gestureTiming.controlWindowSeconds = double(for: Key.controlWindowSeconds, default: settings.gestureTiming.controlWindowSeconds)
        settings.scroll.singleStepDeltaY = Int32(int(for: Key.singleStepDeltaY, default: Int(settings.scroll.singleStepDeltaY)))
        settings.scroll.continuousDeltaY = Int32(int(for: Key.continuousDeltaY, default: Int(settings.scroll.continuousDeltaY)))
        settings.scroll.continuousIntervalMilliseconds = int(for: Key.continuousIntervalMilliseconds, default: settings.scroll.continuousIntervalMilliseconds)
        settings.hud.isPinned = bool(for: Key.hudPinned, default: settings.hud.isPinned)
        settings.hud.isVisible = bool(for: Key.hudVisible, default: settings.hud.isVisible)
        settings.hud.savedOriginX = optionalDouble(for: Key.hudSavedOriginX)
        settings.hud.savedOriginY = optionalDouble(for: Key.hudSavedOriginY)
        return settings
    }

    public func save(_ settings: AppSettings) {
        defaults.set(settings.gestureTiming.readyHoldMilliseconds, forKey: Key.readyHoldMilliseconds)
        defaults.set(settings.gestureTiming.scrollHoldMilliseconds, forKey: Key.scrollHoldMilliseconds)
        defaults.set(settings.gestureTiming.continuousScrollHoldMilliseconds, forKey: Key.continuousScrollHoldMilliseconds)
        defaults.set(settings.gestureTiming.commandHoldMilliseconds, forKey: Key.commandHoldMilliseconds)
        defaults.set(settings.gestureTiming.commandCooldownMilliseconds, forKey: Key.commandCooldownMilliseconds)
        defaults.set(settings.gestureTiming.controlWindowSeconds, forKey: Key.controlWindowSeconds)
        defaults.set(Int(settings.scroll.singleStepDeltaY), forKey: Key.singleStepDeltaY)
        defaults.set(Int(settings.scroll.continuousDeltaY), forKey: Key.continuousDeltaY)
        defaults.set(settings.scroll.continuousIntervalMilliseconds, forKey: Key.continuousIntervalMilliseconds)
        defaults.set(settings.hud.isPinned, forKey: Key.hudPinned)
        defaults.set(settings.hud.isVisible, forKey: Key.hudVisible)
        defaults.set(settings.hud.savedOriginX, forKey: Key.hudSavedOriginX)
        defaults.set(settings.hud.savedOriginY, forKey: Key.hudSavedOriginY)
    }

    private func int(for key: String, default defaultValue: Int) -> Int {
        defaults.object(forKey: key) == nil ? defaultValue : defaults.integer(forKey: key)
    }

    private func double(for key: String, default defaultValue: Double) -> Double {
        defaults.object(forKey: key) == nil ? defaultValue : defaults.double(forKey: key)
    }

    private func optionalDouble(for key: String) -> Double? {
        defaults.object(forKey: key) == nil ? nil : defaults.double(forKey: key)
    }

    private func bool(for key: String, default defaultValue: Bool) -> Bool {
        defaults.object(forKey: key) == nil ? defaultValue : defaults.bool(forKey: key)
    }
}
```

- [ ] **Step 4: Verify tests**

Run:

```bash
swift test --filter SettingsStoreTests
swift test
```

Expected: tests pass.

## Phase 3: Gesture State Machine

### Task 3.1: Implement deterministic clock and state machine

**Files:**
- Create: `Sources/WalkFlowCore/Time/Clock.swift`
- Create: `Sources/WalkFlowCore/Gesture/GestureStateMachine.swift`
- Replace: `Tests/WalkFlowCoreTests/GestureStateMachineTests.swift`

- [ ] **Step 1: Add clock abstraction**

Create `Sources/WalkFlowCore/Time/Clock.swift`:

```swift
import Foundation

public protocol Clock {
    var now: TimeInterval { get }
}

public struct SystemClock: Clock {
    public init() {}
    public var now: TimeInterval { Date().timeIntervalSince1970 }
}
```

- [ ] **Step 2: Write state machine tests**

Replace `Tests/WalkFlowCoreTests/GestureStateMachineTests.swift` with tests covering every committed behavior:

```swift
import XCTest
@testable import WalkFlowCore

final class GestureStateMachineTests: XCTestCase {
    func testOpenPalmHeldForReadyThresholdEntersReady() {
        var clock = TestClock(now: 0)
        var machine = GestureStateMachine(settings: .defaults)

        XCTAssertEqual(machine.handle(.init(kind: .openPalm, confidence: 1, timestamp: clock.now)).hud.icon, .none)
        clock.now = 0.31
        let result = machine.handle(.init(kind: .openPalm, confidence: 1, timestamp: clock.now))

        XCTAssertEqual(result.mode, .ready)
        XCTAssertEqual(result.hud.icon, .infinity)
    }

    func testReadyExpiresAfterFiveSecondsWithoutAction() {
        var machine = GestureStateMachine(settings: .defaults)
        _ = machine.handle(.init(kind: .openPalm, confidence: 1, timestamp: 0))
        _ = machine.handle(.init(kind: .openPalm, confidence: 1, timestamp: 0.31))

        let result = machine.handle(.init(kind: .none, confidence: 0, timestamp: 5.32))

        XCTAssertEqual(result.mode, .standby)
        XCTAssertEqual(result.hud.icon, .none)
        XCTAssertEqual(result.hud.dot, .green)
    }

    func testIndexUpTriggersSingleThenContinuousScroll() {
        var machine = readyMachine()

        _ = machine.handle(.init(kind: .indexUp, confidence: 1, timestamp: 1.00))
        let single = machine.handle(.init(kind: .indexUp, confidence: 1, timestamp: 1.31))
        let continuous = machine.handle(.init(kind: .indexUp, confidence: 1, timestamp: 1.72))

        XCTAssertEqual(single.action, .scrollUp(step: .single))
        XCTAssertEqual(continuous.action, .scrollUp(step: .continuous))
        XCTAssertEqual(continuous.hud.icon, .arrowUp)
    }

    func testGestureChangeStopsContinuousScroll() {
        var machine = readyMachine()
        _ = machine.handle(.init(kind: .indexDown, confidence: 1, timestamp: 1.00))
        _ = machine.handle(.init(kind: .indexDown, confidence: 1, timestamp: 1.72))

        let result = machine.handle(.init(kind: .openPalm, confidence: 1, timestamp: 1.80))

        XCTAssertEqual(result.action, .stopContinuousScroll)
    }

    func testOKPinchTriggersRightCommandOnceUntilReleased() {
        var machine = readyMachine()

        _ = machine.handle(.init(kind: .okPinch, confidence: 1, timestamp: 1.00))
        let first = machine.handle(.init(kind: .okPinch, confidence: 1, timestamp: 1.31))
        let heldAfterCooldown = machine.handle(.init(kind: .okPinch, confidence: 1, timestamp: 2.50))
        _ = machine.handle(.init(kind: .openPalm, confidence: 1, timestamp: 2.60))
        _ = machine.handle(.init(kind: .okPinch, confidence: 1, timestamp: 2.70))
        let second = machine.handle(.init(kind: .okPinch, confidence: 1, timestamp: 3.01))

        XCTAssertEqual(first.action, .pressRightCommand)
        XCTAssertEqual(first.hud.icon, .dribbble)
        XCTAssertEqual(heldAfterCooldown.action, .none)
        XCTAssertEqual(second.action, .pressRightCommand)
        XCTAssertEqual(second.hud.icon, .none)
    }

    func testFistExitsControlWindowWithRedDot() {
        var machine = readyMachine()

        let result = machine.handle(.init(kind: .fist, confidence: 1, timestamp: 1.00))

        XCTAssertEqual(result.mode, .standby)
        XCTAssertEqual(result.action, .stopContinuousScroll)
        XCTAssertEqual(result.hud.dot, .red)
        XCTAssertEqual(result.hud.icon, .none)
    }

    func testHandLostShowsRedDotAndExitsReady() {
        var machine = readyMachine()

        let result = machine.handle(.init(kind: .handLost, confidence: 1, timestamp: 1.00))

        XCTAssertEqual(result.mode, .standby)
        XCTAssertEqual(result.hud.dot, .red)
        XCTAssertEqual(result.hud.icon, .none)
    }

    private func readyMachine() -> GestureStateMachine {
        var machine = GestureStateMachine(settings: .defaults)
        _ = machine.handle(.init(kind: .openPalm, confidence: 1, timestamp: 0))
        _ = machine.handle(.init(kind: .openPalm, confidence: 1, timestamp: 0.31))
        return machine
    }
}

private struct TestClock: Clock {
    var now: TimeInterval
}
```

- [ ] **Step 3: Run failing tests**

Run:

```bash
swift test --filter GestureStateMachineTests
```

Expected: fails because `GestureStateMachine`, `GestureMode`, and output types do not exist.

- [ ] **Step 4: Implement state machine**

Create `Sources/WalkFlowCore/Gesture/GestureStateMachine.swift` with these public types and behavior:

```swift
import Foundation

public enum GestureMode: Equatable, Sendable {
    case disabled
    case blocked
    case standby
    case ready
}

public struct GestureStateOutput: Equatable, Sendable {
    public var mode: GestureMode
    public var action: ControlAction
    public var hud: HUDPresentation
}

public struct GestureStateMachine {
    private let settings: AppSettings
    private var mode: GestureMode = .standby
    private var currentGesture: GestureKind = .none
    private var currentGestureStartedAt: TimeInterval?
    private var lastActionAt: TimeInterval?
    private var isContinuousScrolling = false
    private var okPinchLatched = false
    private var okCooldownUntil: TimeInterval = 0
    private var isVoiceInputActive = false

    public init(settings: AppSettings) {
        self.settings = settings
    }

    public mutating func handle(_ observation: GestureObservation) -> GestureStateOutput {
        updateGestureTracking(with: observation)

        if mode == .ready,
           let lastActionAt,
           observation.timestamp - lastActionAt > settings.gestureTiming.controlWindowSeconds {
            mode = .standby
            isContinuousScrolling = false
            return output(action: .none, hud: .init(dot: .green, icon: .none, message: "Standby"))
        }

        switch observation.kind {
        case .handLost:
            mode = .standby
            isContinuousScrolling = false
            return output(action: .stopContinuousScroll, hud: .init(dot: .red, icon: .none, message: "Hand Lost"))
        case .fist:
            mode = .standby
            isContinuousScrolling = false
            return output(action: .stopContinuousScroll, hud: .init(dot: .red, icon: .none, message: "Stop"))
        case .openPalm:
            okPinchLatched = false
            if heldMilliseconds(at: observation.timestamp) >= settings.gestureTiming.readyHoldMilliseconds {
                mode = .ready
                lastActionAt = observation.timestamp
                return output(action: .none, hud: .init(dot: .green, icon: .infinity, message: "Ready"))
            }
            return output(action: .none, hud: defaultHUD())
        case .indexUp:
            return scrollOutput(direction: .up, timestamp: observation.timestamp)
        case .indexDown:
            return scrollOutput(direction: .down, timestamp: observation.timestamp)
        case .okPinch:
            return commandOutput(timestamp: observation.timestamp)
        case .none:
            okPinchLatched = false
            if isContinuousScrolling {
                isContinuousScrolling = false
                return output(action: .stopContinuousScroll, hud: defaultHUD())
            }
            return output(action: .none, hud: defaultHUD())
        }
    }

    private mutating func updateGestureTracking(with observation: GestureObservation) {
        if observation.kind != currentGesture {
            if isContinuousScrolling {
                isContinuousScrolling = false
            }
            currentGesture = observation.kind
            currentGestureStartedAt = observation.timestamp
        }
    }

    private func heldMilliseconds(at timestamp: TimeInterval) -> Int {
        guard let currentGestureStartedAt else { return 0 }
        return Int((timestamp - currentGestureStartedAt) * 1000)
    }

    private enum ScrollDirection {
        case up
        case down
    }

    private mutating func scrollOutput(direction: ScrollDirection, timestamp: TimeInterval) -> GestureStateOutput {
        guard mode == .ready else {
            return output(action: .none, hud: defaultHUD())
        }

        let held = heldMilliseconds(at: timestamp)
        let icon: HUDIcon = direction == .up ? .arrowUp : .arrowDown

        if held >= settings.gestureTiming.continuousScrollHoldMilliseconds {
            isContinuousScrolling = true
            lastActionAt = timestamp
            return output(
                action: direction == .up ? .scrollUp(step: .continuous) : .scrollDown(step: .continuous),
                hud: .init(dot: .green, icon: icon, message: direction == .up ? "Scroll Up" : "Scroll Down")
            )
        }

        if held >= settings.gestureTiming.scrollHoldMilliseconds, isContinuousScrolling == false {
            lastActionAt = timestamp
            return output(
                action: direction == .up ? .scrollUp(step: .single) : .scrollDown(step: .single),
                hud: .init(dot: .green, icon: icon, message: direction == .up ? "Scroll Up" : "Scroll Down")
            )
        }

        return output(action: .none, hud: .init(dot: .green, icon: icon, message: direction == .up ? "Scroll Up" : "Scroll Down"))
    }

    private mutating func commandOutput(timestamp: TimeInterval) -> GestureStateOutput {
        guard mode == .ready else {
            return output(action: .none, hud: defaultHUD())
        }

        guard timestamp >= okCooldownUntil else {
            return output(action: .none, hud: .init(dot: .green, icon: .none, message: "Cooldown"))
        }

        guard okPinchLatched == false else {
            return output(action: .none, hud: isVoiceInputActive ? .init(dot: .green, icon: .dribbble, message: "Command") : defaultHUD())
        }

        if heldMilliseconds(at: timestamp) >= settings.gestureTiming.commandHoldMilliseconds {
            okPinchLatched = true
            okCooldownUntil = timestamp + Double(settings.gestureTiming.commandCooldownMilliseconds) / 1000.0
            lastActionAt = timestamp
            isVoiceInputActive.toggle()
            return output(
                action: .pressRightCommand,
                hud: isVoiceInputActive
                    ? .init(dot: .green, icon: .dribbble, message: "Command")
                    : .init(dot: .green, icon: .none, message: "Standby")
            )
        }

        return output(action: .none, hud: .init(dot: .green, icon: .none, message: "Command Pending"))
    }

    private func defaultHUD() -> HUDPresentation {
        switch mode {
        case .disabled:
            .init(dot: .red, icon: .lock, message: "Disabled")
        case .blocked:
            .init(dot: .red, icon: .alertTriangle, message: "Permission")
        case .ready:
            .init(dot: .green, icon: .infinity, message: "Ready")
        case .standby:
            .init(dot: .green, icon: .none, message: "Standby")
        }
    }

    private func output(action: ControlAction, hud: HUDPresentation) -> GestureStateOutput {
        GestureStateOutput(mode: mode, action: action, hud: hud)
    }
}
```

- [ ] **Step 5: Verify state machine**

Run:

```bash
swift test --filter GestureStateMachineTests
swift test
```

Expected: tests pass. If the `OK` release behavior fails, fix only `okPinchLatched` reset logic and re-run the same commands.

## Phase 4: Gesture Classifier

### Task 4.1: Build geometry classifier with synthetic tests

**Files:**
- Create: `Sources/WalkFlowCore/Gesture/GestureClassifier.swift`
- Create: `Tests/WalkFlowCoreTests/GestureClassifierTests.swift`

- [ ] **Step 1: Write synthetic classifier tests**

Create `Tests/WalkFlowCoreTests/GestureClassifierTests.swift`:

```swift
import XCTest
@testable import WalkFlowCore

final class GestureClassifierTests: XCTestCase {
    func testOpenPalmClassifiesFiveExtendedFingers() {
        let classifier = GestureClassifier()
        let result = classifier.classify(.openPalm(timestamp: 1))
        XCTAssertEqual(result.kind, .openPalm)
    }

    func testIndexUpRequiresOnlyIndexExtendedUpward() {
        let classifier = GestureClassifier()
        let result = classifier.classify(.indexUp(timestamp: 1))
        XCTAssertEqual(result.kind, .indexUp)
    }

    func testIndexDownRequiresOnlyIndexExtendedDownward() {
        let classifier = GestureClassifier()
        let result = classifier.classify(.indexDown(timestamp: 1))
        XCTAssertEqual(result.kind, .indexDown)
    }

    func testFistRequiresAllFingersCurled() {
        let classifier = GestureClassifier()
        let result = classifier.classify(.fist(timestamp: 1))
        XCTAssertEqual(result.kind, .fist)
    }

    func testOKPinchRequiresThumbIndexContactAndOtherFingersExtended() {
        let classifier = GestureClassifier()
        let result = classifier.classify(.okPinch(timestamp: 1))
        XCTAssertEqual(result.kind, .okPinch)
    }

    func testLowConfidenceReturnsHandLost() {
        let classifier = GestureClassifier(minimumJointConfidence: 0.8)
        let result = classifier.classify(.openPalm(timestamp: 1, confidence: 0.2))
        XCTAssertEqual(result.kind, .handLost)
    }
}
```

Also add test-only fixture helpers in the same file:

```swift
private extension HandPoseSnapshot {
    static func openPalm(timestamp: TimeInterval, confidence: Double = 1) -> HandPoseSnapshot {
        fixture(timestamp: timestamp, confidence: confidence, tips: [
            .thumbTip: HandPoint(x: 0.20, y: 0.62, confidence: confidence),
            .indexTip: HandPoint(x: 0.38, y: 0.90, confidence: confidence),
            .middleTip: HandPoint(x: 0.50, y: 0.94, confidence: confidence),
            .ringTip: HandPoint(x: 0.62, y: 0.90, confidence: confidence),
            .littleTip: HandPoint(x: 0.76, y: 0.80, confidence: confidence)
        ])
    }

    static func indexUp(timestamp: TimeInterval, confidence: Double = 1) -> HandPoseSnapshot {
        fixture(timestamp: timestamp, confidence: confidence, tips: [
            .thumbTip: HandPoint(x: 0.34, y: 0.46, confidence: confidence),
            .indexTip: HandPoint(x: 0.50, y: 0.92, confidence: confidence),
            .middleTip: HandPoint(x: 0.55, y: 0.45, confidence: confidence),
            .ringTip: HandPoint(x: 0.62, y: 0.43, confidence: confidence),
            .littleTip: HandPoint(x: 0.69, y: 0.41, confidence: confidence)
        ])
    }

    static func indexDown(timestamp: TimeInterval, confidence: Double = 1) -> HandPoseSnapshot {
        fixture(timestamp: timestamp, confidence: confidence, tips: [
            .thumbTip: HandPoint(x: 0.34, y: 0.46, confidence: confidence),
            .indexTip: HandPoint(x: 0.50, y: 0.08, confidence: confidence),
            .middleTip: HandPoint(x: 0.55, y: 0.45, confidence: confidence),
            .ringTip: HandPoint(x: 0.62, y: 0.43, confidence: confidence),
            .littleTip: HandPoint(x: 0.69, y: 0.41, confidence: confidence)
        ])
    }

    static func fist(timestamp: TimeInterval, confidence: Double = 1) -> HandPoseSnapshot {
        fixture(timestamp: timestamp, confidence: confidence, tips: [
            .thumbTip: HandPoint(x: 0.39, y: 0.47, confidence: confidence),
            .indexTip: HandPoint(x: 0.45, y: 0.45, confidence: confidence),
            .middleTip: HandPoint(x: 0.52, y: 0.44, confidence: confidence),
            .ringTip: HandPoint(x: 0.59, y: 0.44, confidence: confidence),
            .littleTip: HandPoint(x: 0.66, y: 0.43, confidence: confidence)
        ])
    }

    static func okPinch(timestamp: TimeInterval, confidence: Double = 1) -> HandPoseSnapshot {
        fixture(timestamp: timestamp, confidence: confidence, tips: [
            .thumbTip: HandPoint(x: 0.38, y: 0.63, confidence: confidence),
            .indexTip: HandPoint(x: 0.41, y: 0.64, confidence: confidence),
            .middleTip: HandPoint(x: 0.53, y: 0.91, confidence: confidence),
            .ringTip: HandPoint(x: 0.64, y: 0.88, confidence: confidence),
            .littleTip: HandPoint(x: 0.76, y: 0.80, confidence: confidence)
        ])
    }

    static func fixture(timestamp: TimeInterval, confidence: Double, tips: [HandJointName: HandPoint]) -> HandPoseSnapshot {
        var points: [HandJointName: HandPoint] = [
            .wrist: HandPoint(x: 0.50, y: 0.10, confidence: confidence),
            .thumbCMC: HandPoint(x: 0.38, y: 0.28, confidence: confidence),
            .thumbMP: HandPoint(x: 0.34, y: 0.38, confidence: confidence),
            .thumbIP: HandPoint(x: 0.30, y: 0.48, confidence: confidence),
            .indexMCP: HandPoint(x: 0.44, y: 0.40, confidence: confidence),
            .indexPIP: HandPoint(x: 0.47, y: 0.58, confidence: confidence),
            .indexDIP: HandPoint(x: 0.49, y: 0.72, confidence: confidence),
            .middleMCP: HandPoint(x: 0.52, y: 0.40, confidence: confidence),
            .middlePIP: HandPoint(x: 0.52, y: 0.60, confidence: confidence),
            .middleDIP: HandPoint(x: 0.52, y: 0.74, confidence: confidence),
            .ringMCP: HandPoint(x: 0.60, y: 0.38, confidence: confidence),
            .ringPIP: HandPoint(x: 0.62, y: 0.58, confidence: confidence),
            .ringDIP: HandPoint(x: 0.63, y: 0.70, confidence: confidence),
            .littleMCP: HandPoint(x: 0.68, y: 0.34, confidence: confidence),
            .littlePIP: HandPoint(x: 0.72, y: 0.52, confidence: confidence),
            .littleDIP: HandPoint(x: 0.74, y: 0.66, confidence: confidence)
        ]
        for (joint, point) in tips {
            points[joint] = point
        }
        return HandPoseSnapshot(points: points, handedness: .right, timestamp: timestamp)
    }
}
```

- [ ] **Step 2: Run failing classifier tests**

Run:

```bash
swift test --filter GestureClassifierTests
```

Expected: fails because `GestureClassifier` does not exist.

- [ ] **Step 3: Implement classifier**

Create `Sources/WalkFlowCore/Gesture/GestureClassifier.swift`:

```swift
import Foundation

public struct GestureClassifier {
    private let minimumJointConfidence: Double
    private let pinchDistanceThreshold: Double

    public init(minimumJointConfidence: Double = 0.45, pinchDistanceThreshold: Double = 0.08) {
        self.minimumJointConfidence = minimumJointConfidence
        self.pinchDistanceThreshold = pinchDistanceThreshold
    }

    public func classify(_ snapshot: HandPoseSnapshot?) -> GestureObservation {
        guard let snapshot else {
            return .init(kind: .handLost, confidence: 0, timestamp: 0)
        }

        guard hasRequiredConfidence(snapshot) else {
            return .init(kind: .handLost, confidence: 0, timestamp: snapshot.timestamp)
        }

        if isOKPinch(snapshot) {
            return .init(kind: .okPinch, confidence: 1, timestamp: snapshot.timestamp)
        }
        if isOpenPalm(snapshot) {
            return .init(kind: .openPalm, confidence: 1, timestamp: snapshot.timestamp)
        }
        if isIndexDirection(snapshot, up: true) {
            return .init(kind: .indexUp, confidence: 1, timestamp: snapshot.timestamp)
        }
        if isIndexDirection(snapshot, up: false) {
            return .init(kind: .indexDown, confidence: 1, timestamp: snapshot.timestamp)
        }
        if isFist(snapshot) {
            return .init(kind: .fist, confidence: 1, timestamp: snapshot.timestamp)
        }
        return .init(kind: .none, confidence: 0.5, timestamp: snapshot.timestamp)
    }

    private func hasRequiredConfidence(_ snapshot: HandPoseSnapshot) -> Bool {
        let required: [HandJointName] = [
            .wrist, .thumbTip, .indexMCP, .indexPIP, .indexTip,
            .middleMCP, .middlePIP, .middleTip,
            .ringMCP, .ringPIP, .ringTip,
            .littleMCP, .littlePIP, .littleTip
        ]
        return required.allSatisfy { snapshot[$0]?.confidence ?? 0 >= minimumJointConfidence }
    }

    private func isOpenPalm(_ snapshot: HandPoseSnapshot) -> Bool {
        isExtended(snapshot, tip: .indexTip, pip: .indexPIP, mcp: .indexMCP)
            && isExtended(snapshot, tip: .middleTip, pip: .middlePIP, mcp: .middleMCP)
            && isExtended(snapshot, tip: .ringTip, pip: .ringPIP, mcp: .ringMCP)
            && isExtended(snapshot, tip: .littleTip, pip: .littlePIP, mcp: .littleMCP)
            && thumbIsAwayFromPalm(snapshot)
    }

    private func isIndexDirection(_ snapshot: HandPoseSnapshot, up: Bool) -> Bool {
        guard isExtended(snapshot, tip: .indexTip, pip: .indexPIP, mcp: .indexMCP),
              isCurled(snapshot, tip: .middleTip, pip: .middlePIP, mcp: .middleMCP),
              isCurled(snapshot, tip: .ringTip, pip: .ringPIP, mcp: .ringMCP),
              isCurled(snapshot, tip: .littleTip, pip: .littlePIP, mcp: .littleMCP),
              let tip = snapshot[.indexTip],
              let mcp = snapshot[.indexMCP] else {
            return false
        }
        return up ? tip.y > mcp.y + 0.25 : tip.y < mcp.y - 0.25
    }

    private func isFist(_ snapshot: HandPoseSnapshot) -> Bool {
        isCurled(snapshot, tip: .indexTip, pip: .indexPIP, mcp: .indexMCP)
            && isCurled(snapshot, tip: .middleTip, pip: .middlePIP, mcp: .middleMCP)
            && isCurled(snapshot, tip: .ringTip, pip: .ringPIP, mcp: .ringMCP)
            && isCurled(snapshot, tip: .littleTip, pip: .littlePIP, mcp: .littleMCP)
    }

    private func isOKPinch(_ snapshot: HandPoseSnapshot) -> Bool {
        guard let thumbTip = snapshot[.thumbTip],
              let indexTip = snapshot[.indexTip] else {
            return false
        }
        let pinched = distance(thumbTip, indexTip) <= pinchDistanceThreshold
        return pinched
            && isExtended(snapshot, tip: .middleTip, pip: .middlePIP, mcp: .middleMCP)
            && isExtended(snapshot, tip: .ringTip, pip: .ringPIP, mcp: .ringMCP)
            && isExtended(snapshot, tip: .littleTip, pip: .littlePIP, mcp: .littleMCP)
    }

    private func isExtended(_ snapshot: HandPoseSnapshot, tip: HandJointName, pip: HandJointName, mcp: HandJointName) -> Bool {
        guard let tip = snapshot[tip], let pip = snapshot[pip], let mcp = snapshot[mcp] else {
            return false
        }
        return tip.y > pip.y && pip.y > mcp.y
    }

    private func isCurled(_ snapshot: HandPoseSnapshot, tip: HandJointName, pip: HandJointName, mcp: HandJointName) -> Bool {
        guard let tip = snapshot[tip], let pip = snapshot[pip], let mcp = snapshot[mcp] else {
            return false
        }
        return tip.y <= pip.y || distance(tip, mcp) < distance(pip, mcp)
    }

    private func thumbIsAwayFromPalm(_ snapshot: HandPoseSnapshot) -> Bool {
        guard let thumbTip = snapshot[.thumbTip], let indexMCP = snapshot[.indexMCP] else {
            return false
        }
        return distance(thumbTip, indexMCP) > 0.12
    }

    private func distance(_ a: HandPoint, _ b: HandPoint) -> Double {
        hypot(a.x - b.x, a.y - b.y)
    }
}
```

- [ ] **Step 4: Verify classifier**

Run:

```bash
swift test --filter GestureClassifierTests
swift test
```

Expected: tests pass.

## Phase 5: HUD State Mapping

### Task 5.1: Implement HUD reducer and priority rules

**Files:**
- Create: `Sources/WalkFlowCore/HUD/HUDStateReducer.swift`
- Create: `Tests/WalkFlowCoreTests/HUDStateReducerTests.swift`

- [ ] **Step 1: Write HUD reducer tests**

Create `Tests/WalkFlowCoreTests/HUDStateReducerTests.swift`:

```swift
import XCTest
@testable import WalkFlowCore

final class HUDStateReducerTests: XCTestCase {
    func testPermissionBlockShowsRedAlert() {
        let reducer = HUDStateReducer()
        let hud = reducer.presentation(
            isEnabled: true,
            isPaused: false,
            permissions: .init(camera: .denied, accessibility: .granted, inputMonitoring: .notRequired),
            stateOutput: .init(mode: .standby, action: .none, hud: .init(dot: .green, icon: .none, message: "Standby"))
        )
        XCTAssertEqual(hud.dot, .red)
        XCTAssertEqual(hud.icon, .alertTriangle)
    }

    func testDisabledShowsLock() {
        let reducer = HUDStateReducer()
        let hud = reducer.presentation(
            isEnabled: false,
            isPaused: false,
            permissions: .init(camera: .granted, accessibility: .granted, inputMonitoring: .notRequired),
            stateOutput: .init(mode: .standby, action: .none, hud: .init(dot: .green, icon: .none, message: "Standby"))
        )
        XCTAssertEqual(hud.dot, .red)
        XCTAssertEqual(hud.icon, .lock)
    }

    func testStandbyStaysEmptyGreen() {
        let reducer = HUDStateReducer()
        let hud = reducer.presentation(
            isEnabled: true,
            isPaused: false,
            permissions: .init(camera: .granted, accessibility: .granted, inputMonitoring: .notRequired),
            stateOutput: .init(mode: .standby, action: .none, hud: .init(dot: .green, icon: .none, message: "Standby"))
        )
        XCTAssertEqual(hud.dot, .green)
        XCTAssertEqual(hud.icon, .none)
    }
}
```

- [ ] **Step 2: Implement reducer**

Create `Sources/WalkFlowCore/HUD/HUDStateReducer.swift`:

```swift
import Foundation

public struct HUDStateReducer {
    public init() {}

    public func presentation(
        isEnabled: Bool,
        isPaused: Bool,
        permissions: PermissionSnapshot,
        stateOutput: GestureStateOutput
    ) -> HUDPresentation {
        if isEnabled == false {
            return .init(dot: .red, icon: .lock, message: "Disabled")
        }

        if permissions.canControl == false {
            return .init(dot: .red, icon: .alertTriangle, message: "Permission")
        }

        if isPaused {
            return .init(dot: .green, icon: .none, message: "Paused")
        }

        return stateOutput.hud
    }
}
```

- [ ] **Step 3: Verify reducer**

Run:

```bash
swift test --filter HUDStateReducerTests
swift test
```

Expected: tests pass.

## Phase 6: System Permissions And Event Output

### Task 6.1: Add permission service

**Files:**
- Create: `Sources/WalkFlowMacApp/Permissions/SystemPermissionService.swift`
- Modify: `Sources/WalkFlowMacApp/Resources/Info.plist`
- Modify: `Sources/WalkFlowMacApp/App/AppDelegate.swift`

- [ ] **Step 1: Implement system permission checks**

Create `Sources/WalkFlowMacApp/Permissions/SystemPermissionService.swift`:

```swift
import AVFoundation
import ApplicationServices
import Foundation
import WalkFlowCore

final class SystemPermissionService {
    func snapshot() -> PermissionSnapshot {
        PermissionSnapshot(
            camera: cameraStatus(),
            accessibility: accessibilityStatus(),
            inputMonitoring: .notRequired
        )
    }

    func requestCameraAccess(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: completion)
    }

    func promptForAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    private func cameraStatus() -> PermissionStatus {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return .granted
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }

    private func accessibilityStatus() -> PermissionStatus {
        AXIsProcessTrusted() ? .granted : .denied
    }
}
```

- [ ] **Step 2: Verify Info.plist camera purpose string**

Run:

```bash
plutil -extract NSCameraUsageDescription raw Sources/WalkFlowMacApp/Resources/Info.plist
```

Expected:

```text
WalkFlow-Mac uses the camera to recognize hand gestures for remote control.
```

- [ ] **Step 3: Build**

Run:

```bash
swift build
```

Expected: build succeeds.

### Task 6.2: Implement event output layer

**Files:**
- Create: `Sources/WalkFlowMacApp/Events/CGEventOutput.swift`

- [ ] **Step 1: Implement CGEvent output**

Create `Sources/WalkFlowMacApp/Events/CGEventOutput.swift`:

```swift
import Carbon.HIToolbox
import CoreGraphics
import Foundation
import WalkFlowCore

protocol ControlEventOutput {
    func execute(_ action: ControlAction, scrollSettings: ScrollSettings)
}

final class CGEventOutput: ControlEventOutput {
    func execute(_ action: ControlAction, scrollSettings: ScrollSettings) {
        switch action {
        case .none:
            return
        case .stopContinuousScroll:
            return
        case .scrollUp(let step):
            postScroll(deltaY: delta(for: step, settings: scrollSettings))
        case .scrollDown(let step):
            postScroll(deltaY: -delta(for: step, settings: scrollSettings))
        case .pressRightCommand:
            postRightCommand()
        }
    }

    private func delta(for step: ScrollStep, settings: ScrollSettings) -> Int32 {
        switch step {
        case .single:
            return settings.singleStepDeltaY
        case .continuous:
            return settings.continuousDeltaY
        }
    }

    private func postScroll(deltaY: Int32) {
        guard let event = CGEvent(
            scrollWheelEvent2Source: nil,
            units: .line,
            wheelCount: 1,
            wheel1: deltaY,
            wheel2: 0,
            wheel3: 0
        ) else {
            return
        }
        event.post(tap: .cghidEventTap)
    }

    private func postRightCommand() {
        let keyCode = CGKeyCode(kVK_RightCommand)
        let down = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)
        let up = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
        down?.flags = .maskCommand
        up?.flags = []
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }
}
```

- [ ] **Step 2: Build**

Run:

```bash
swift build
```

Expected: build succeeds. If `kVK_RightCommand` is unavailable, import `Carbon.HIToolbox` exactly as shown and re-run.

- [ ] **Step 3: Manual right Command verification gate**

After the app is integrated enough to trigger `pressRightCommand`, use macOS Keyboard Viewer or the user's dictation configuration to verify the event is interpreted as the right-side Command key. Record the result in `review.md`. If macOS reports only generic Command, keep the feature blocked and investigate lower-level HID posting before claiming this requirement is complete.

## Phase 7: Camera And Vision Pipeline

### Task 7.1: Add AppKit camera preview

**Files:**
- Create: `Sources/WalkFlowMacApp/Camera/CameraPreviewView.swift`
- Create: `Sources/WalkFlowMacApp/Camera/CameraSessionController.swift`

- [ ] **Step 1: Create preview view**

Create `Sources/WalkFlowMacApp/Camera/CameraPreviewView.swift`:

```swift
import AppKit
import AVFoundation

final class CameraPreviewView: NSView {
    override func makeBackingLayer() -> CALayer {
        AVCaptureVideoPreviewLayer()
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        wantsLayer = true
        previewLayer.videoGravity = .resizeAspectFill
    }
}
```

- [ ] **Step 2: Create capture session controller**

Create `Sources/WalkFlowMacApp/Camera/CameraSessionController.swift`:

```swift
import AVFoundation
import Foundation

protocol CameraFrameConsumer: AnyObject {
    func cameraSession(_ session: CameraSessionController, didOutput sampleBuffer: CMSampleBuffer)
}

final class CameraSessionController: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    weak var consumer: CameraFrameConsumer?
    private let queue = DispatchQueue(label: "com.m1ngwym.walkflowmac.camera")

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
```

- [ ] **Step 3: Build**

Run:

```bash
swift build
```

Expected: build succeeds.

### Task 7.2: Add Vision hand-pose provider

**Files:**
- Create: `Sources/WalkFlowMacApp/Vision/VisionHandPoseProvider.swift`

- [ ] **Step 1: Implement Vision adapter**

Create `Sources/WalkFlowMacApp/Vision/VisionHandPoseProvider.swift`:

```swift
import AVFoundation
import Foundation
import WalkFlowCore
import Vision

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

        let recognized = try observation.recognizedPoints(.all)
        var points: [HandJointName: HandPoint] = [:]
        for (visionName, jointName) in Self.jointMap {
            guard let point = recognized[visionName] else {
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

    private static let jointMap: [VNHumanHandPoseObservation.JointName: HandJointName] = [
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
```

- [ ] **Step 2: Build**

Run:

```bash
swift build
```

Expected: build succeeds. If Vision API names differ on the installed SDK, inspect compiler errors and adjust only the Vision adapter, not core domain types.

## Phase 8: App Orchestration

### Task 8.1: Add app state store and controller

**Files:**
- Create: `Sources/WalkFlowMacApp/App/AppStateStore.swift`
- Create: `Sources/WalkFlowMacApp/App/AppController.swift`
- Modify: `Sources/WalkFlowMacApp/App/AppDelegate.swift`

- [ ] **Step 1: Create state store**

Create `Sources/WalkFlowMacApp/App/AppStateStore.swift`:

```swift
import Foundation
import WalkFlowCore

final class AppStateStore {
    var isEnabled = true
    var isPaused = false
    var settings = AppSettings.defaults
    var permissions = PermissionSnapshot(camera: .notDetermined, accessibility: .denied, inputMonitoring: .notRequired)
    var latestHUD = HUDPresentation(dot: .green, icon: .none, message: "Standby")
}
```

- [ ] **Step 2: Create controller**

Create `Sources/WalkFlowMacApp/App/AppController.swift`:

```swift
import AVFoundation
import Foundation
import WalkFlowCore

protocol HUDPresenting: AnyObject {
    func update(_ presentation: HUDPresentation)
}

final class AppController: CameraFrameConsumer {
    let state = AppStateStore()
    private let settingsStore = SettingsStore()
    private let permissions = SystemPermissionService()
    private let camera = CameraSessionController()
    private let vision = VisionHandPoseProvider()
    private let classifier = GestureClassifier()
    private var stateMachine = GestureStateMachine(settings: .defaults)
    private let hudReducer = HUDStateReducer()
    private let eventOutput: ControlEventOutput = CGEventOutput()
    weak var hudPresenter: HUDPresenting?

    init() {
        state.settings = settingsStore.load()
        stateMachine = GestureStateMachine(settings: state.settings)
        camera.consumer = self
    }

    func refreshPermissions() {
        state.permissions = permissions.snapshot()
        publishHUD(.init(mode: .standby, action: .none, hud: .init(dot: .green, icon: .none, message: "Standby")))
    }

    func configureCameraIfPermitted() {
        refreshPermissions()
        guard state.permissions.camera == .granted else {
            return
        }
        do {
            try camera.configure()
        } catch {
            state.latestHUD = .init(dot: .red, icon: .alertTriangle, message: "Camera")
        }
    }

    func startRecognition() {
        guard state.isEnabled, state.isPaused == false, state.permissions.canControl else {
            publishHUD(.init(mode: .blocked, action: .none, hud: .init(dot: .red, icon: .alertTriangle, message: "Permission")))
            return
        }
        camera.start()
    }

    func stopRecognition() {
        camera.stop()
    }

    func setEnabled(_ enabled: Bool) {
        state.isEnabled = enabled
        publishHUD(.init(mode: enabled ? .standby : .disabled, action: .none, hud: .init(dot: enabled ? .green : .red, icon: enabled ? .unlockOnce : .lock, message: enabled ? "Enabled" : "Disabled")))
    }

    func setPaused(_ paused: Bool) {
        state.isPaused = paused
        publishHUD(.init(mode: .standby, action: .none, hud: .init(dot: .green, icon: .none, message: paused ? "Paused" : "Standby")))
    }

    func cameraSession(_ session: CameraSessionController, didOutput sampleBuffer: CMSampleBuffer) {
        let timestamp = Date().timeIntervalSince1970
        let snapshot = try? vision.detect(sampleBuffer: sampleBuffer, timestamp: timestamp)
        let observation = classifier.classify(snapshot)
        var output = stateMachine.handle(observation)
        if state.permissions.canControl == false || state.isEnabled == false || state.isPaused {
            output = .init(mode: .blocked, action: .none, hud: output.hud)
        } else {
            eventOutput.execute(output.action, scrollSettings: state.settings.scroll)
        }
        publishHUD(output)
    }

    private func publishHUD(_ output: GestureStateOutput) {
        let hud = hudReducer.presentation(
            isEnabled: state.isEnabled,
            isPaused: state.isPaused,
            permissions: state.permissions,
            stateOutput: output
        )
        state.latestHUD = hud
        DispatchQueue.main.async { [weak self] in
            self?.hudPresenter?.update(hud)
        }
    }
}
```

- [ ] **Step 3: Build**

Run:

```bash
swift build
```

Expected: build succeeds.

## Phase 9: Main Window AppKit UI

### Task 9.1: Build split main window and permission panel

**Files:**
- Create: `Sources/WalkFlowMacApp/UI/MainWindowController.swift`
- Create: `Sources/WalkFlowMacApp/UI/ControlPanelView.swift`
- Create: `Sources/WalkFlowMacApp/UI/PermissionPanelView.swift`
- Create: `Sources/WalkFlowMacApp/UI/PreviewContainerView.swift`
- Modify: `Sources/WalkFlowMacApp/App/AppDelegate.swift`

- [ ] **Step 1: Create main window controller**

Create `Sources/WalkFlowMacApp/UI/MainWindowController.swift`:

```swift
import AppKit

final class MainWindowController: NSWindowController {
    private let appController: AppController
    private let previewView = CameraPreviewView(frame: .zero)

    init(appController: AppController) {
        self.appController = appController
        let root = NSSplitView()
        root.isVertical = true
        root.dividerStyle = .thin

        let controlPanel = ControlPanelView(appController: appController)
        let preview = PreviewContainerView(previewView: previewView)
        root.addArrangedSubview(controlPanel)
        root.addArrangedSubview(preview)
        controlPanel.widthAnchor.constraint(equalToConstant: 220).isActive = true

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1100, height: 680),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "WalkFlow-Mac"
        window.contentView = root
        window.center()
        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        nil
    }
}
```

- [ ] **Step 2: Create control panel**

Create `Sources/WalkFlowMacApp/UI/ControlPanelView.swift`:

```swift
import AppKit

final class ControlPanelView: NSView {
    private let appController: AppController

    init(appController: AppController) {
        self.appController = appController
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        build()
    }

    required init?(coder: NSCoder) {
        nil
    }

    private func build() {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        let enable = NSButton(checkboxWithTitle: "Enable", target: self, action: #selector(toggleEnable(_:)))
        enable.state = .on
        let pause = NSButton(checkboxWithTitle: "Pause", target: self, action: #selector(togglePause(_:)))
        let permissions = PermissionPanelView(appController: appController)

        stack.addArrangedSubview(permissions)
        stack.addArrangedSubview(enable)
        stack.addArrangedSubview(pause)
        stack.addArrangedSubview(NSTextField(labelWithString: "HUD: pinned, draggable, upper-right"))
        stack.addArrangedSubview(NSTextField(labelWithString: "Shortcut: configurable later"))

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 16)
        ])
    }

    @objc private func toggleEnable(_ sender: NSButton) {
        appController.setEnabled(sender.state == .on)
    }

    @objc private func togglePause(_ sender: NSButton) {
        appController.setPaused(sender.state == .on)
    }
}
```

- [ ] **Step 3: Create permission panel**

Create `Sources/WalkFlowMacApp/UI/PermissionPanelView.swift`:

```swift
import AppKit

final class PermissionPanelView: NSView {
    private let appController: AppController

    init(appController: AppController) {
        self.appController = appController
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        build()
    }

    required init?(coder: NSCoder) {
        nil
    }

    private func build() {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(NSTextField(labelWithString: "Permissions"))
        stack.addArrangedSubview(NSTextField(labelWithString: "Camera"))
        stack.addArrangedSubview(NSTextField(labelWithString: "Accessibility"))
        let refresh = NSButton(title: "Recheck", target: self, action: #selector(recheck))
        stack.addArrangedSubview(refresh)
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @objc private func recheck() {
        appController.refreshPermissions()
    }
}
```

- [ ] **Step 4: Create preview container**

Create `Sources/WalkFlowMacApp/UI/PreviewContainerView.swift`:

```swift
import AppKit

final class PreviewContainerView: NSView {
    init(previewView: CameraPreviewView) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        previewView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(previewView)
        NSLayoutConstraint.activate([
            previewView.leadingAnchor.constraint(equalTo: leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: trailingAnchor),
            previewView.topAnchor.constraint(equalTo: topAnchor),
            previewView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        nil
    }
}
```

- [ ] **Step 5: Wire AppDelegate**

Replace the launch window construction in `Sources/WalkFlowMacApp/App/AppDelegate.swift` with:

```swift
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let appController = AppController()
    private var mainWindowController: MainWindowController?
    private var hudWindowController: HUDWindowController?
    private var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let main = MainWindowController(appController: appController)
        main.showWindow(nil)
        main.window?.makeKeyAndOrderFront(nil)
        mainWindowController = main

        let hud = HUDWindowController(settingsStore: SettingsStore())
        hud.show()
        hudWindowController = hud
        appController.hudPresenter = hud

        menuBarController = MenuBarController(appController: appController, mainWindowController: main, hudWindowController: hud)

        appController.refreshPermissions()
        appController.configureCameraIfPermitted()
        appController.startRecognition()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
```

This will not compile until HUD and menu bar files are added in Phase 10. Keep this step in the same branch and continue directly to Phase 10 before running full build.

## Phase 10: HUD Floating Panel And Menu Bar

### Task 10.1: Implement HUD view and floating panel

**Files:**
- Create: `Sources/WalkFlowMacApp/UI/HUDView.swift`
- Create: `Sources/WalkFlowMacApp/UI/HUDWindowController.swift`

- [ ] **Step 1: Create HUD view**

Create `Sources/WalkFlowMacApp/UI/HUDView.swift`:

```swift
import AppKit
import WalkFlowCore

final class HUDView: NSView {
    private var presentation = HUDPresentation(dot: .green, icon: .none, message: "Standby")
    private let iconView = LottieStatusIconView(frame: NSRect(x: 48, y: 28, width: 64, height: 64))

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        addSubview(iconView)
    }

    required init?(coder: NSCoder) {
        nil
    }

    func update(_ presentation: HUDPresentation) {
        self.presentation = presentation
        iconView.show(icon: presentation.icon)
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.setFill()
        dirtyRect.fill()

        let panel = NSBezierPath(roundedRect: bounds.insetBy(dx: 2, dy: 2), xRadius: 10, yRadius: 10)
        NSColor.windowBackgroundColor.withAlphaComponent(0.92).setFill()
        panel.fill()

        let arrow = NSBezierPath()
        let midX = bounds.midX
        arrow.move(to: NSPoint(x: midX - 8, y: bounds.maxY - 2))
        arrow.line(to: NSPoint(x: midX, y: bounds.maxY + 8))
        arrow.line(to: NSPoint(x: midX + 8, y: bounds.maxY - 2))
        arrow.close()
        NSColor.windowBackgroundColor.withAlphaComponent(0.92).setFill()
        arrow.fill()

        let dotColor: NSColor = presentation.dot == .green ? .systemGreen : .systemRed
        dotColor.setFill()
        NSBezierPath(ovalIn: NSRect(x: 18, y: bounds.height - 34, width: 10, height: 10)).fill()
    }
}
```

- [ ] **Step 2: Create HUD window controller**

Create `Sources/WalkFlowMacApp/UI/HUDWindowController.swift`:

```swift
import AppKit
import WalkFlowCore

final class HUDWindowController: NSWindowController, HUDPresenting {
    private let hudView = HUDView(frame: NSRect(x: 0, y: 0, width: 160, height: 110))
    private let settingsStore: SettingsStore

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 160, height: 110),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = hudView
        super.init(window: panel)
        restorePosition()
    }

    required init?(coder: NSCoder) {
        nil
    }

    func show() {
        window?.orderFrontRegardless()
    }

    func update(_ presentation: HUDPresentation) {
        hudView.update(presentation)
    }

    private func restorePosition() {
        guard let window else { return }
        let settings = settingsStore.load()
        if let x = settings.hud.savedOriginX, let y = settings.hud.savedOriginY {
            window.setFrameOrigin(NSPoint(x: x, y: y))
            if NSScreen.screens.contains(where: { $0.visibleFrame.intersects(window.frame) }) {
                return
            }
        }
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        window.setFrameOrigin(NSPoint(x: screen.maxX - 180, y: screen.maxY - 130))
    }
}
```

- [ ] **Step 3: Add position persistence after drag**

Add a window delegate or `windowDidMove` observer in `HUDWindowController` that saves `window.frame.origin` into `SettingsStore`. Verify by moving the HUD, quitting, relaunching, and checking that it restores.

### Task 10.2: Implement menu bar controller

**Files:**
- Create: `Sources/WalkFlowMacApp/UI/MenuBarController.swift`

- [ ] **Step 1: Create menu bar controller**

Create `Sources/WalkFlowMacApp/UI/MenuBarController.swift`:

```swift
import AppKit

final class MenuBarController {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private weak var appController: AppController?
    private weak var mainWindowController: MainWindowController?
    private weak var hudWindowController: HUDWindowController?

    init(appController: AppController, mainWindowController: MainWindowController, hudWindowController: HUDWindowController) {
        self.appController = appController
        self.mainWindowController = mainWindowController
        self.hudWindowController = hudWindowController
        configure()
    }

    private func configure() {
        statusItem.button?.title = "✋"
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Enable", action: #selector(enable), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Pause", action: #selector(pause), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Show HUD", action: #selector(showHUD), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Open Window", action: #selector(openWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        for item in menu.items {
            item.target = self
        }
        statusItem.menu = menu
    }

    @objc private func enable() {
        appController?.setEnabled(true)
    }

    @objc private func pause() {
        appController?.setPaused(true)
    }

    @objc private func showHUD() {
        hudWindowController?.show()
    }

    @objc private func openWindow() {
        mainWindowController?.showWindow(nil)
        mainWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func openSettings() {
        openWindow()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
```

- [ ] **Step 2: Build and run**

Run:

```bash
swift build
./script/build_and_run.sh --verify
```

Expected: app launches with main window, HUD, and menu bar item.

## Phase 11: Lottie And useAnimations Assets

### Task 11.1: Fetch useAnimations JSON and third-party notices

**Files:**
- Create: `script/fetch_useanimations_assets.sh`
- Create: `Sources/WalkFlowMacApp/Resources/Lottie/alertTriangle.json`
- Create: `Sources/WalkFlowMacApp/Resources/Lottie/arrowDown.json`
- Create: `Sources/WalkFlowMacApp/Resources/Lottie/arrowUp.json`
- Create: `Sources/WalkFlowMacApp/Resources/Lottie/dribbble.json`
- Create: `Sources/WalkFlowMacApp/Resources/Lottie/infinity.json`
- Create: `Sources/WalkFlowMacApp/Resources/Lottie/lock.json`
- Create: `Docs/THIRD_PARTY_NOTICES.md`

- [ ] **Step 1: Create fetch script**

Create `script/fetch_useanimations_assets.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$ROOT_DIR/.codex-artifacts/useanimations"
TARGET_DIR="$ROOT_DIR/Sources/WalkFlowMacApp/Resources/Lottie"
PACKAGE_VERSION="2.10.0"

/bin/rm -rf "$WORK_DIR"
/bin/mkdir -p "$WORK_DIR" "$TARGET_DIR"
cd "$WORK_DIR"
npm pack "react-useanimations@$PACKAGE_VERSION" --silent
tar -xzf "react-useanimations-$PACKAGE_VERSION.tgz"

/bin/cp package/lib/alertTriangle/alertTriangle.json "$TARGET_DIR/alertTriangle.json"
/bin/cp package/lib/arrowDown/arrowDown.json "$TARGET_DIR/arrowDown.json"
/bin/cp package/lib/arrowUp/arrowUp.json "$TARGET_DIR/arrowUp.json"
/bin/cp package/lib/dribbble/dribbble.json "$TARGET_DIR/dribbble.json"
/bin/cp package/lib/infinity/infinity.json "$TARGET_DIR/infinity.json"
/bin/cp package/lib/lock/lock.json "$TARGET_DIR/lock.json"

cat > "$ROOT_DIR/Docs/THIRD_PARTY_NOTICES.md" <<'NOTICE'
# Third Party Notices

## react-useanimations

- Package: react-useanimations
- Version: 2.10.0
- Source: https://github.com/useAnimations/react-useanimations
- License declared in package.json: MIT
- Bundled files: Lottie JSON resources for alertTriangle, arrowDown, arrowUp, dribbble, infinity, and lock.

## Lottie

- Package: Lottie via https://github.com/airbnb/lottie-spm.git
- Version constraint: from 4.6.1
- Source: https://github.com/airbnb/lottie-ios
- License: Apache-2.0
NOTICE
```

- [ ] **Step 2: Run fetch script**

Run:

```bash
chmod +x script/fetch_useanimations_assets.sh
./script/fetch_useanimations_assets.sh
ls Sources/WalkFlowMacApp/Resources/Lottie
```

Expected:

```text
alertTriangle.json
arrowDown.json
arrowUp.json
dribbble.json
infinity.json
lock.json
```

- [ ] **Step 3: Verify licenses**

Run:

```bash
npm view react-useanimations@2.10.0 license repository.url
rg -n "react-useanimations|Lottie|MIT|Apache-2.0" Docs/THIRD_PARTY_NOTICES.md
```

Expected: npm prints `MIT` and the GitHub repository; notice file contains both packages.

### Task 11.2: Implement native Lottie status icon view

**Files:**
- Create: `Sources/WalkFlowMacApp/UI/LottieStatusIconView.swift`

- [ ] **Step 1: Create Lottie wrapper**

Create `Sources/WalkFlowMacApp/UI/LottieStatusIconView.swift`:

```swift
import AppKit
import Lottie
import WalkFlowCore

final class LottieStatusIconView: NSView {
    private let animationView = LottieAnimationView()
    private var currentIcon: HUDIcon = .none

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: trailingAnchor),
            animationView.topAnchor.constraint(equalTo: topAnchor),
            animationView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        animationView.contentMode = .scaleAspectFit
    }

    required init?(coder: NSCoder) {
        nil
    }

    func show(icon: HUDIcon) {
        guard icon != currentIcon else {
            return
        }
        currentIcon = icon

        guard let resource = resourceName(for: icon) else {
            animationView.stop()
            animationView.animation = nil
            animationView.isHidden = true
            return
        }

        animationView.isHidden = false
        animationView.animation = LottieAnimation.named(resource, subdirectory: "Lottie")

        switch icon {
        case .alertTriangle, .infinity, .arrowUp, .arrowDown, .dribbble:
            animationView.loopMode = .loop
            animationView.play()
        case .unlockOnce:
            animationView.loopMode = .playOnce
            animationView.play(fromProgress: 0, toProgress: 1)
        case .lock:
            animationView.loopMode = .playOnce
            animationView.currentProgress = 0
        case .none:
            animationView.stop()
        }
    }

    private func resourceName(for icon: HUDIcon) -> String? {
        switch icon {
        case .none:
            return nil
        case .lock, .unlockOnce:
            return "lock"
        case .alertTriangle:
            return "alertTriangle"
        case .infinity:
            return "infinity"
        case .arrowUp:
            return "arrowUp"
        case .arrowDown:
            return "arrowDown"
        case .dribbble:
            return "dribbble"
        }
    }
}
```

- [ ] **Step 2: Build and run**

Run:

```bash
swift build
./script/build_and_run.sh --verify
```

Expected: app launches and HUD renders without Lottie resource errors.

- [ ] **Step 3: Visual animation verification**

Open `https://useanimations.com/#explore` in a browser and compare these app states against original lottie-web behavior:

```text
Permission -> alertTriangle loop
Ready -> infinity loop
Scroll Up -> arrowUp loop
Scroll Down -> arrowDown loop
Command -> dribbble hover-like loop
Disabled -> lock
Enable transition -> unlock once, then empty Standby
```

Record findings in `docs/tasks/001-gesture-control-macos-app-bootstrap/review.md`. If native Lottie differs, adjust only playback mode, progress range, direction, or speed.

## Phase 12: Main Integration Verification

### Task 12.1: Wire preview layer and camera session

**Files:**
- Modify: `Sources/WalkFlowMacApp/UI/MainWindowController.swift`
- Modify: `Sources/WalkFlowMacApp/App/AppController.swift`

- [ ] **Step 1: Expose camera session for preview**

Add this method to `AppController`:

```swift
func attachPreview(to previewView: CameraPreviewView) {
    previewView.previewLayer.session = camera.session
}
```

- [ ] **Step 2: Attach preview in main window**

In `MainWindowController.init`, after `previewView` is created, add:

```swift
appController.attachPreview(to: previewView)
```

- [ ] **Step 3: Run app and grant camera permission**

Run:

```bash
./script/build_and_run.sh --verify
```

Expected: macOS prompts for Camera permission on first run. After permission is granted and the app is relaunched, the camera preview appears in the right pane.

### Task 12.2: Verify gesture-to-action loop with logs

**Files:**
- Modify: `Sources/WalkFlowMacApp/App/AppController.swift`
- Modify: `script/build_and_run.sh`

- [ ] **Step 1: Add unified logging**

Add logger to `AppController`:

```swift
import OSLog

private let logger = Logger(subsystem: "com.m1ngwym.walkflowmac", category: "Gesture")
```

When publishing output, log:

```swift
logger.info("gestureHUD=\(hud.message, privacy: .public) icon=\(String(describing: hud.icon), privacy: .public)")
```

- [ ] **Step 2: Run telemetry**

Run:

```bash
./script/build_and_run.sh --telemetry
```

Expected: logs show gesture HUD transitions while the app runs.

- [ ] **Step 3: Manual behavior checks**

Perform these in front of the camera:

```text
Open palm for 300 ms -> Ready HUD shows infinity
Index up for 300 ms -> one scroll-up action
Index up for 700 ms -> continuous scroll-up action until gesture changes
Index down for 300 ms -> one scroll-down action
Fist -> red dot, no center icon, exits control window
OK pinch for 300 ms -> right Command once, dribbble loops
Hold OK after cooldown -> no repeated right Command
Release and pinch again -> second right Command, dribbble clears
Move hand out of frame -> red dot, no center icon
```

Record pass/fail and exact failures in `review.md`.

## Phase 13: Recognition Metrics And Performance Gates

### Task 13.1: Add recognition metrics collector

**Files:**
- Create: `Sources/WalkFlowCore/Diagnostics/RecognitionMetrics.swift`
- Create: `Tests/WalkFlowCoreTests/RecognitionMetricsTests.swift`

- [ ] **Step 1: Write metrics tests**

Create `Tests/WalkFlowCoreTests/RecognitionMetricsTests.swift`:

```swift
import XCTest
@testable import WalkFlowCore

final class RecognitionMetricsTests: XCTestCase {
    func testAccuracyComputesCorrectly() {
        var metrics = RecognitionMetrics()
        metrics.record(expected: .openPalm, actual: .openPalm)
        metrics.record(expected: .openPalm, actual: .none)
        XCTAssertEqual(metrics.accuracy(for: .openPalm), 0.5)
    }

    func testFalseTriggerCountIncrementsForActionableGestureWhenExpectedNone() {
        var metrics = RecognitionMetrics()
        metrics.record(expected: .none, actual: .okPinch)
        XCTAssertEqual(metrics.falseTriggerCount, 1)
    }
}
```

- [ ] **Step 2: Implement metrics**

Create `Sources/WalkFlowCore/Diagnostics/RecognitionMetrics.swift`:

```swift
import Foundation

public struct RecognitionMetrics: Equatable, Sendable {
    private var totalByGesture: [GestureKind: Int] = [:]
    private var correctByGesture: [GestureKind: Int] = [:]
    public private(set) var falseTriggerCount = 0

    public init() {}

    public mutating func record(expected: GestureKind, actual: GestureKind) {
        totalByGesture[expected, default: 0] += 1
        if expected == actual {
            correctByGesture[expected, default: 0] += 1
        }
        if expected == .none, [.indexUp, .indexDown, .okPinch].contains(actual) {
            falseTriggerCount += 1
        }
    }

    public func accuracy(for gesture: GestureKind) -> Double {
        guard let total = totalByGesture[gesture], total > 0 else {
            return 0
        }
        return Double(correctByGesture[gesture, default: 0]) / Double(total)
    }
}
```

- [ ] **Step 3: Verify metrics**

Run:

```bash
swift test --filter RecognitionMetricsTests
swift test
```

Expected: tests pass.

### Task 13.2: Manual Vision gate

**Files:**
- Modify: `docs/tasks/001-gesture-control-macos-app-bootstrap/review.md`

- [ ] **Step 1: Run gesture matrix**

Run app and evaluate:

```text
Gestures: Open Palm, Index Up, Index Down, Fist, OK Pinch
Distances: 1 m, 1.5 m, 2 m
Lighting: normal indoor, dim, backlit
Hands: left, right
Angles: palm facing camera, slight rotation
```

Pass gate:

```text
Each key gesture per distance: accuracy >= 95%
Standby false system-triggering actions for 10 minutes: 0
Voice input session for 10 minutes: no accidental interruption
Gesture-stable-to-action median latency: <= 250 ms
```

- [ ] **Step 2: Decide MediaPipe spike**

If any pass gate fails because Vision landmarks are unstable, stop default implementation and write a MediaPipe spike plan section before adding the dependency. If gates pass, record:

```text
Vision gate passed. MediaPipe not included in runtime.
```

## Phase 14: Performance, Windowing, And System Behavior Validation

### Task 14.1: Run build and signing checks

**Files:**
- Modify: `docs/tasks/001-gesture-control-macos-app-bootstrap/review.md`

- [ ] **Step 1: Build and test**

Run:

```bash
swift test
swift build
./script/build_and_run.sh --verify
```

Expected: all pass.

- [ ] **Step 2: Inspect bundle metadata**

Run:

```bash
plutil -p "dist/WalkFlow-Mac.app/Contents/Info.plist"
codesign -dvvv --entitlements :- "dist/WalkFlow-Mac.app" 2>&1 | sed -n '1,120p'
```

Record camera usage string, bundle identifier, and signing state in `review.md`.

### Task 14.2: Run performance gates

**Files:**
- Modify: `docs/tasks/001-gesture-control-macos-app-bootstrap/review.md`

- [ ] **Step 1: CPU and memory while recognition is enabled**

Run app for 10 minutes with camera recognition enabled, then run:

```bash
ps -o pid,pcpu,rss,comm -c -x | rg '^ *[0-9]+ +[0-9.]+' | rg 'WalkFlowMac|COMMAND'
```

Pass gate:

```text
CPU 10-minute average <= 15%
RSS <= 300 MB
```

- [ ] **Step 2: HUD Lottie CPU increment**

Compare CPU with HUD hidden and HUD showing each loop icon:

```text
alertTriangle
infinity
arrowUp
arrowDown
dribbble
```

Pass gate:

```text
HUD-only Lottie CPU increment <= 3%
```

- [ ] **Step 3: Window behavior matrix**

Verify and record:

```text
HUD remains visible when pinned and another app is clicked
HUD can be dragged
HUD restores saved position after relaunch
HUD falls back to current main screen upper-right if saved position is off-screen
HUD works in full-screen space
HUD works with multiple displays
HUD works when menu bar auto-hide is enabled
Mission Control does not leave a stuck or duplicated HUD
```

## Phase 15: Documentation And Final Review

### Task 15.1: Update task docs and project facts

**Files:**
- Modify: `AGENTS.md`
- Modify: `docs/tasks/001-gesture-control-macos-app-bootstrap/progress.md`
- Modify: `docs/tasks/001-gesture-control-macos-app-bootstrap/review.md`

- [ ] **Step 1: Update `AGENTS.md` only for long-lived facts**

After implementation actually creates SwiftPM/package/build commands, update `AGENTS.md` with only durable project facts:

```text
- 包管理器：Swift Package Manager。
- 本地测试命令：swift test。
- 本地构建命令：swift build。
- 本地运行命令：./script/build_and_run.sh --verify。
```

Do not add transient test results to `AGENTS.md`.

- [ ] **Step 2: Update progress**

Append implementation phase completions to `progress.md`, including:

```text
- 已创建 SwiftPM AppKit macOS App bootstrap。
- 已实现核心手势状态机、几何分类器、HUD reducer、设置持久化。
- 已实现 AppKit 主窗口、菜单栏、HUD、摄像头预览、Vision pipeline、CGEvent 输出。
- 已完成 Vision gate 和性能 gate 的结果记录。
```

- [ ] **Step 3: Update review**

Record:

```text
Build/test commands and results
Camera permission result
Accessibility permission result
Right Command verification result
Vision gate result
Performance gate result
Lottie visual comparison result
Known residual risk
Skipped checks with reasons
```

### Task 15.2: Final verification before completion

**Files:**
- Read: all modified files

- [ ] **Step 1: Full command set**

Run:

```bash
swift test
swift build
./script/build_and_run.sh --verify
UNFINISHED_PATTERN="$(printf '%s|%s|%s %s|%s %s %s' 'TO''DO' 'T''BD' 'implement' 'later' 'fill' 'in' 'details')"
rg -n "SwiftUI|$UNFINISHED_PATTERN" Package.swift Sources Tests docs/tasks/001-gesture-control-macos-app-bootstrap docs/superpowers/specs
```

Expected:

```text
swift test passes
swift build passes
Run verify passes
rg finds no SwiftUI usage and no unfinished placeholders
```

The `rg` command may find historic text that says "不使用 SwiftUI" in docs. That is acceptable. Any Swift source import or usage of SwiftUI is a blocker.

- [ ] **Step 2: Review uncommitted diff**

Run:

```bash
git status --short
git diff --stat
git diff -- Package.swift Sources Tests script .codex Docs docs/tasks/001-gesture-control-macos-app-bootstrap AGENTS.md
```

Expected: only files in this plan changed.

- [ ] **Step 3: Checkpoint**

Commit the task-scoped implementation files after reviewing `git status --short`:

```bash
git add Package.swift Sources Tests script .codex Docs docs/tasks/001-gesture-control-macos-app-bootstrap AGENTS.md
git commit -m "feat: bootstrap gesture control macOS app"
```

## Conditional Phase: MediaPipe Native Spike

Only execute this phase if Phase 13 fails because Apple Vision cannot meet the accuracy or false-trigger gate.

### Task M.1: Write a separate MediaPipe spike plan before adding dependencies

**Files:**
- Modify: `docs/tasks/001-gesture-control-macos-app-bootstrap/plan.md`
- Modify: `docs/tasks/001-gesture-control-macos-app-bootstrap/review.md`

- [ ] **Step 1: Record Vision failure evidence**

Add exact failure data to `review.md`:

```text
Gesture:
Distance:
Lighting:
Observed accuracy:
False trigger count:
Latency:
Why this blocks first-version quality:
```

- [ ] **Step 2: Pause for user approval before dependency change**

Ask:

```text
Apple Vision failed the agreed gate. Do you approve a MediaPipe native spike that may add model/runtime dependency cost?
```

Do not add MediaPipe files until the user approves.

## Plan Self-Review

- Spec coverage: covered AppKit-only, SwiftPM bootstrap, AVFoundation camera, Apple Vision, gesture classifier, state machine, CGEvent/Accessibility output, permissions, main window, menu bar, pinned HUD, useAnimations Lottie, Vision gate, performance gate, and MediaPipe conditional path.
- Placeholder scan: plan avoids unfinished placeholders and defines exact files, commands, and pass gates.
- Type consistency: `GestureKind`, `GestureObservation`, `GestureStateMachine`, `GestureStateOutput`, `HUDPresentation`, `PermissionSnapshot`, `ControlAction`, and settings names are consistent across tasks.
- Project-rule consistency: local commit commands are allowed without additional user approval; push, deploy, and destructive git operations require explicit user confirmation; SwiftUI is excluded; no backend, cloud provider, analytics, or paid SDK is introduced.
