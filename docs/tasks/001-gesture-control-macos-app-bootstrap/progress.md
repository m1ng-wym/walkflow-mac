# macOS 远距手势控制工具进度

## 已完成

- 确认当前仓库是 `/Users/Zhuanz/Documents/Magic-tool`。
- 确认当前项目为新仓库，尚未存在 macOS App 代码。
- 用户确认正式项目名为 `WalkFlow-Mac`。
- 用户确认 GitHub 远端仓库为 `https://github.com/m1ng-wym/walkflow-mac.git`。
- 读取项目级 `AGENTS.md`。
- 启动 superpowers brainstorming visual companion。
- 用户确认第一版选择“完整远距控制”作为成功标准。
- 创建本长任务四文档。
- 按用户要求将任务目录改名为 `docs/tasks/001-gesture-control-macos-app-bootstrap/`。
- 用户确认暂停/恢复识别采用混合控制：菜单栏和全局快捷键作为硬开关，远距手势作为软开关。
- 用户确认第一版采用准备姿态模型：摊开手掌面向摄像头并短暂停顿后进入控制窗口。
- 用户确认控制窗口退出条件：约 5 秒无新动作指令、手部离开画面、停止手势。
- 用户用三张图片确认手势词汇表：五指张开手掌面向摄像头为准备姿态，一指向上且其余四指收缩为屏幕向上滚动，一指向下且其余四指收缩为屏幕向下滚动。
- 用户确认滚动节奏采用短按/长按混合：姿态稳定约 0.2 到 0.4 秒先滚一段，继续保持超过阈值后连续滚动；连续滚动中手势变化即停止。
- 用户确认停止手势采用握拳。
- 用户确认第一版快捷键触发目标为右侧 `Command` 键，用于语音输入开始/结束切换。
- 用户通过图片确认右侧 `Command` 键触发手势为 `OK` 捏合：拇指和食指形成圆形接触，其余手指张开。
- 用户确认 `OK` 手势采用稳定触发加冷却：稳定约 0.2 到 0.4 秒触发一次，约 1 秒冷却；冷却后仍保持 `OK` 不重复触发，必须松开后重做。
- 用户确认 App 外壳采用主窗口为主、菜单栏状态为辅：主窗口显示摄像头预览、手势状态、权限和设置；菜单栏做快速开关和其他配置项入口。
- 用户确认后续开发全流程必须使用 AppKit，不可以使用 SwiftUI。
- 用户确认菜单栏图标显示总状态，并提供 `Enable`、`Pause`、`Show HUD`、`Open Window`、`Settings`、`Quit`。
- 用户确认状态反馈采用可 pin 的固定浮动面板，固定浮动在屏幕右上角，不因点击其他区域而消失，并用简单图形表示上滚、下滚、触发右侧 `Command` 等状态。
- 用户确认浮动面板可拖动并记住位置：默认右上角，可拖动避开 App UI，下一次启动恢复最后位置。
- 已同步更新项目级 `AGENTS.md` 的长期项目事实和技术栈约束。
- 用户确认浮动面板同一时间只显示一个大图标，不同时显示多个小图标。
- 用户提供浮动面板草图：小巧简洁，顶部居中小箭头，左上角状态点，中心区域显示当前状态图标。
- 用户确认状态点规则：阻塞/不可控状态使用红点，`Standby` 和正常可用状态使用绿点。
- 用户确认 `Standby` 中心区域保持空白，只用绿点表示。
- 用户确认中心状态图标接入 useAnimations 动效图标，并必须保留网站原样动效。
- 用户确认图标映射：`Disabled` 使用 `Lock / Unlock`，`Permission` 使用 `Alert triangle`，`Ready` 使用 `Infinity`，`Scroll Up` 使用 `Arrow up`，`Scroll Down` 使用 `Arrow down`，`Command` 使用 `Dribbble` hover 动效。
- 用户确认 `Command` 结束后的回退规则：不回到 `Ready` 图标；手仍可识别时回 `Standby` 空白绿点，手不在画面时红点阻塞。
- 用户确认 `Hand Lost`、`Stop`、`Paused`、`Cooldown` 暂不显示中心图标；`Hand Lost` 和 `Stop` 使用红点。
- 已核验 `react-useanimations@2.10.0` npm 包存在 `lock`、`alertTriangle`、`infinity`、`arrowUp`、`arrowDown`、`dribbble` Lottie JSON 资源。
- 用户确认 Lottie 动效集成选择 `AppKit + 原生 Lottie macOS renderer`，不使用 SwiftUI，不默认使用 WebView。
- 用户确认主窗口布局为左右分栏，比例约 `1:4`：左侧配置、权限、HUD 和快捷键，右侧摄像头预览和实时识别。
- 用户确认右侧摄像头预览为主要区域，实时识别把浮动窗口样式照搬一次，固定在摄像头预览页右上角。
- 用户确认权限体验采用主窗口权限面板常驻加启动时一次性引导。
- 用户确认硬开关第一版不预设全局快捷键，但在设置中保留可配置选项。
- 用户要求手势识别技术方案进行更广泛调研，覆盖 GitHub、Reddit、X/Twitter 和相关开源项目，并满足免费、轻量两个硬约束。
- 已完成初轮调研：Apple Vision、MediaPipe、OpenCV、TensorFlow.js/Fingerpose、自训练 Core ML、商业/SDK 类方案均已纳入比较。
- 已评估 Roboflow `supervision` 项目：确认其为 MIT 开源 Python 计算机视觉工具库，适合数据/检测/标注/追踪/keypoint 结果处理，不适合作为本 AppKit 常驻手势控制工具的核心运行时依赖。
- 应用户要求重新量化 `supervision`：在本机全新 venv 中测得 23 个依赖包、wheel 下载约 87.6 MB、安装后 `site-packages` 约 331 MB、`import supervision` 最大 RSS 约 128 MB；同时量化对照 Python `mediapipe` 为 19 个依赖包、wheel 下载约 88.1 MB、安装后约 299 MB、`import mediapipe` 最大 RSS 约 78 MB，MediaPipe hand landmarker 模型约 7.5 MB。
- 用户认可技术主线：`AVFoundation + Apple Vision hand pose + 自研轻量 GestureClassifier + GestureStateMachine + CGEvent/Accessibility + AppKit`。
- 用户认可 MediaPipe 作为带进入门槛的备选验证方向，Roboflow `supervision` 不进入第一版运行时。
- 已写入设计规格：`docs/superpowers/specs/2026-06-14-gesture-control-macos-app-design.md`。
- 已完成设计规格自审，并补充默认手势时间阈值、Vision/MediaPipe 进入门槛、第一版性能门槛和规格自审结果。
- 用户确认设计规格可以进入下一步。
- 已使用 writing-plans skill 将后续实现计划重写到当前任务目录的 `plan.md`，没有另起 `docs/superpowers/plans/` 文件。
- 已完成实现计划自审：检查规格覆盖、占位词、类型/命名一致性和项目规则一致性。
- 用户确认本项目本地 commit 不需要额外同意；push、deploy 和破坏性 git 操作必须停止等待用户明确确认，破坏性 git 操作默认不做。
- 已将上述 git 权限规则同步到 `plan.md` 和本地项目级 `AGENTS.md`，避免后续执行规则冲突。
- 已确认本地当前分支为 `main`。
- 已确认 `origin` 指向 GitHub 远端仓库 `https://github.com/m1ng-wym/walkflow-mac.git`。
- 已统一文档口径：项目名 `WalkFlow-Mac`，远端仓库 `https://github.com/m1ng-wym/walkflow-mac.git`，SwiftPM 计划命名为 `WalkFlowMac` / `WalkFlowCore` / `WalkFlowMacApp`。
- 用户最新确认 `AGENTS.md` 和 Superpowers 相关文档/内容不希望由 Git 记录。
- 已调整 `.gitignore`：忽略 `AGENTS.md`、`.superpowers/` 和 `docs/superpowers/`。
- 已从 Git 索引移除 `AGENTS.md`、`.superpowers/` 和 `docs/superpowers/`，文件仍保留在本地。
- 用户确认后续开发流程必须最大化使用 Superpowers：所有开发使用 TDD，使用 Subagent/并行 agent 提升效率，每阶段结束后进行高强度 requesting-code-review 和细致测试验收，最终验收包含完整 review、Smoke 测试和端到端测试。
- 已读取并吸收 Superpowers `test-driven-development`、`subagent-driven-development`、`dispatching-parallel-agents`、`requesting-code-review`、`verification-before-completion`、`using-git-worktrees`、`finishing-a-development-branch` 技能要求。
- 已读取并分析 Build macOS Apps 相关能力：`swiftpm-macos`、`build-run-debug`、`test-triage`、`telemetry`、`signing-entitlements`、`packaging-notarization`、`window-management`、`appkit-interop`、`swiftui-patterns`、`view-refactor`、`liquid-glass`。
- 已优化 `plan.md`：新增强制 TDD gate、Subagent/并行 agent 执行模型、每阶段 acceptance gate、最终验收 gate，以及 Build macOS Apps 能力矩阵和阶段映射。
- 已修正 `plan.md` 的 Build macOS Apps run script / Codex Run action 计划，使其对齐 `script/build_and_run.sh` + `.codex/environments/environment.toml` 的 canonical 形态。
- 已完成首次本地提交：`docs: initialize WalkFlow-Mac planning docs`。
- 已完成首次 push：本地 `main` 已推送到 `origin/main`，并设置 upstream 跟踪。
- 已按用户要求对 `plan.md` 执行多轮计划审计和加固，目标是消除可预见的阶段执行漏洞、TDD 漏洞、编译断点和验收证据漏洞。
- 已强化 `plan.md` 的 TDD 覆盖矩阵，并补充 `CameraPreviewViewTests`、`VisionHandPoseProviderTests`、`MainWindowControllerTests`、`MenuBarControllerTests`、`LottieStatusIconViewTests` 等明确测试入口。
- 已修复 `plan.md` 中 Phase 9 过早装配 `AppDelegate` 导致阶段不可编译的问题，将完整 AppKit 启动装配后移到 HUD/menu 类型存在后的 Phase 10。
- 已修复 `plan.md` 中 Phase 7、Phase 12 等生产代码先于测试的问题，补充 camera preview、Vision joint mapping、preview session attach、telemetry RED 检查等红绿闭环。
- 已修复 `plan.md` 中若干实现片段风险：`CameraControlling` 暴露 `AVCaptureSession`、连续滚动手势变化时发出 `stopContinuousScroll`、`indexDown` 分类不复用向上伸直判断、菜单栏 controller 继承 `NSObject`。
- 已将资源脚本和构建脚本计划中的删除操作改成受控路径清理，并将 `.worktrees/`、`worktrees/` 加入 `.gitignore`，避免后续 subagent worktree 被误跟踪。

## 当前状态

Git 远端关联、首次 commit 和首次 push 已完成。当前分支为 `main`，跟踪 `origin/main`。最新规则下，`AGENTS.md`、`.superpowers/` 和 `docs/superpowers/` 只保留本地，不再由 Git 跟踪。`plan.md` 已完成第二轮高强度加固，后续实现必须按其中的 Superpowers TDD/Subagent/Review gate、Build macOS Apps 能力映射和每阶段自动化/人工验收门槛执行。

### 2026-06-15 Phase 0 执行基线

- 已恢复执行冻结计划 `plan.md`，当前 `plan.md` 仅作为执行合同，不做修改。
- 已确认当前工作目录：`/Users/Zhuanz/Documents/Magic-tool`。
- 已确认当前分支状态：`main`，本地相对 `origin/main` ahead 2，未 push。
- 已确认执行前不存在 `Package.swift`、`.xcodeproj` 或 `.xcworkspace`。
- 已确认执行前 `git status --short` 和 `git diff --stat` 均为空。
- 已确认 `AGENTS.md`、`.superpowers/`、`docs/superpowers/`、`.worktrees/`、`worktrees/` 均由 `.gitignore` 忽略。
- 已确认 `git ls-files AGENTS.md .superpowers docs/superpowers` 无输出，local-only agent artifacts 未被 Git 跟踪。
- 已确认本轮已读取并采用必需 Superpowers / Build macOS Apps skills；并已读取 Build macOS Apps `run-button-bootstrap.md` 作为本地 run script 参考。
- 已尝试启动并行 subagent 进行 Phase 0/1 风险复核，但 subagent 因账户额度限制报错，未能完成只读复核；该问题已记录到 `review.md`，当前继续推进主线，后续如额度恢复需再次执行并行 review。
- 实现基线：`WALKFLOW_IMPL_BASE_SHA=c779ffd6fb158d6ef14874a5c504e5ebd2dc28c2`。

### 2026-06-15 Phase 1 Bootstrap 进度

- 用户已明确确认允许只改 `Package.swift`，移除 `WalkFlowMacApp` target 的 `.process("Resources")`，保留 `Info.plist` 给 run script 使用，并继续执行。
- 已按批准范围修复 `Package.swift`：移除 `resources: [.process("Resources")]`，并显式 `exclude: ["Resources/Info.plist"]`，避免 SwiftPM 把 App bundle metadata 当 target resource。
- 已创建 SwiftPM package、`WalkFlowCore` library、`WalkFlowMacApp` executable、`WalkFlowCoreTests` 和 `WalkFlowMacAppTests`。
- 已完成 `GestureKind` 第一个 TDD 红绿循环：focused test 先因 `GestureKind` 不存在失败，再以最小 enum 实现通过。
- 已创建 AppKit-only entrypoint：`Sources/WalkFlowMacApp/main.swift` 和 `Sources/WalkFlowMacApp/App/AppDelegate.swift`。
- 已创建 bundle metadata：`Sources/WalkFlowMacApp/Resources/Info.plist`，包含 `NSCameraUsageDescription`。
- 已创建 Build macOS Apps run script：`script/build_and_run.sh`，并创建 Codex Run action：`.codex/environments/environment.toml`。
- 已修复 run script staging：当前 SwiftPM + Lottie binary framework 需要把 `Lottie.framework` 一并复制进 `.app`，否则 dyld 启动失败；脚本现在使用 `swift build --show-bin-path` 获取真实 build products 目录，并复制其中的 `.framework`。
- 已完成并行 subagent 只读复核：复核结论认为 `Package.swift` 最小修复合理，未发现 `plan.md` dirty diff、SwiftUI 引入或 local-only artifact 跟踪问题；提醒后续 Phase 11 添加 Lottie JSON 时不要恢复 broad `.process("Resources")`。
- 已完成 Phase 1 code review gate：reviewer 未发现 Critical；发现 1 个 Important 文档陈旧问题，已修正；Minor 中 `Info.plist` development region 字面量问题也已修正为 `en`。
- 已执行 `swift test`、`swift build`、`./script/build_and_run.sh --verify`、`plutil`、`codesign`、SwiftUI 禁用检查、local-only 跟踪检查和 `plan.md` hash 检查，结果已记录到 `review.md`。

### 2026-06-15 Phase 2 Core Domain / Settings 进度

- 已完成 Task 2.1 domain types TDD：
  - RED：`DomainTypesTests` 因 `AppSettings`、`PermissionSnapshot`、`HUDPresentation` 等不存在失败。
  - GREEN：新增 `HandPoseSnapshot`、`AppSettings`、`HUDTypes`、`PermissionTypes`、`EventTypes`，并扩展 `GestureObservation`。
- 已完成 Task 2.2 settings persistence TDD：
  - RED：`SettingsStoreTests` 因 `SettingsStore` 不存在失败。
  - GREEN：新增 `SettingsStore`，支持默认值加载和 HUD 位置持久化 round trip。
- 已执行 Phase 2 focused tests、`swift test` 和 `swift build`，结果写入 `review.md`。
- 已完成 Phase 2 code review gate：reviewer 未发现 Critical/Important；指出验证证据可更完整，已补跑 `swift test --filter DomainTypesTests` 和 `swift test --filter WalkFlowCoreTests` 并记录。

### 2026-06-15 Phase 3 Gesture State Machine 进度

- 已完成 Task 3.1 state machine TDD：
  - RED：替换 `GestureStateMachineTests` 后，focused test 因 `GestureStateMachine` / 项目 `Clock` 类型不存在失败。
  - GREEN：新增 `Clock` / `SystemClock` 和 `GestureStateMachine`，覆盖 ready 进入/过期、单次/连续滚动、连续滚动手势变化停止、OK 捏合右侧 Command latch/cooldown、握拳停止和 hand lost 红点退出。
- Phase 3 code review 发现 1 个 Critical 和 3 个 Important：openPalm 会刷新 ready 窗口、单次滚动未 latch、第二次 OK 后未退出 ready、语音输入期间释放 OK 后 Dribbble 状态丢失。
- 已按 TDD 补充失败测试并修复状态机：openPalm 持续不刷新 5 秒窗口，单次滚动只触发一次，第二次 OK 后 mode 回 `standby`，语音输入期间释放成 openPalm 仍保持 Dribbble。
- Phase 3 re-review 发现 1 个 Important：语音输入期间超过 5 秒 ready window 后，Dribbble 状态会被普通超时清空，且无法再用第二次 `OK` 结束语音输入。已按 TDD 补充 `testCommandHUDPersistsPastReadyTimeoutUntilSecondCommand` 并修复：语音输入会话期间不应用普通 ready timeout，直到第二次 `OK` 触发右侧 `Command` 后回到 `standby`。
- Phase 3 第二次 re-review 发现 1 个 Important：语音输入 active 后，普通 `indexUp` / `indexDown` 仍会触发滚动并覆盖 Dribbble HUD。已按 TDD 补充 `testVoiceInputActiveSuppressesScrollAndKeepsCommandHUD` 并修复：语音输入会话期间，除第二次 `OK`、`handLost`、`fist` 外，普通手势不发控制 action，HUD 保持 Dribbble。
- Phase 3 第三次 re-review 发现 1 个 Important：第二次 `OK` 起手但未稳定到 300ms、或第一次 `OK` 后仍在 cooldown 内时，HUD 会短暂清成空白。已按 TDD 补充 `testVoiceInputActiveKeepsCommandHUDDuringSecondOKPendingAndCooldown` 并修复：语音输入会话期间的 `OK` cooldown / pending 帧也保持 Dribbble，直到第二次 `OK` 成功触发后回到 `standby`。
- Phase 3 最终 re-review 已通过：reviewer 确认无 Critical / Important / Minor，之前所有 Critical / Important 均已关闭。
- 已重新执行 `swift test --filter GestureStateMachineTests`、`swift test` 和 `swift build`，结果写入 `review.md`。
- 已完成 Phase 3 checkpoint commit：`d2984f2 feat: add gesture state machine`。

### 2026-06-15 Phase 4 Gesture Classifier 进度

- 已完成 Task 4.1 classifier TDD：
  - RED：新增 `GestureClassifierTests` 后，focused test 因 `GestureClassifier` 不存在失败。
  - GREEN：新增 `GestureClassifier`，基于手部关键点几何规则识别 open palm、index up、index down、fist、OK pinch，并在低置信度或缺失快照时返回 `handLost`。
- 已补充左右手覆盖：`testOpenPalmClassifiesLeftAndRightHands` 证明当前几何分类不依赖左右手枚举，满足 Phase 4 left/right hand 验收要求。
- Phase 4 code review gate 未发现 Critical / Important；Minor 指出缺少 `classify(nil)` 显式测试，已补充 `testNilSnapshotReturnsHandLost`。
- 已执行 `swift test --filter GestureClassifierTests`、`swift test`、`swift build`、`git diff --check`、SwiftUI 禁用检查和 `plan.md` hash 检查，结果写入 `review.md`。
- 已完成 Phase 4 checkpoint commit：`e08ae59 feat: add gesture classifier`。

### 2026-06-16 Phase 5 HUD State Mapping 进度

- 已完成 Task 5.1 HUD reducer TDD：
  - RED：新增 `HUDStateReducerTests` 后，focused test 因 `HUDStateReducer` 不存在失败。
  - GREEN：新增 `HUDStateReducer`，实现 HUD 优先级：disabled 红点 lock、permission blocked 红点 alertTriangle、paused 绿点空图标、否则透传状态机 HUD。
- Phase 5 code review 发现 1 个 Important：测试覆盖未满足冻结计划绑定矩阵，缺少 paused、ready、scroll、command、hand lost、stop reducer 层测试。已补齐对应测试，focused tests 从 3 个扩展到 9 个。
- Phase 5 re-review 已通过：reviewer 确认无 Critical / Important / Minor，之前的 Important 已关闭。
- 已执行 `swift test --filter HUDStateReducerTests`、`swift test`、`swift build`、`git diff --check` 和 `plan.md` hash 检查，结果写入 `review.md`。
- 已完成 Phase 5 checkpoint commit：`3aa5fa5 feat: add HUD state reducer`。

### 2026-06-16 Phase 6 System Permissions And Event Output 进度

- 已完成 Task 6.1 permission service TDD：
  - RED：新增 `SystemPermissionServiceTests` 后，focused test 因 `SystemPermissionService`、`CameraAuthorizationProviding`、`AccessibilityTrustProviding` 不存在失败。
  - GREEN：新增 `SystemPermissionService`，通过可注入 camera/accessibility provider 生成 `PermissionSnapshot`，支持 camera request 和 accessibility prompt。测试使用 fake provider，不触发真实权限弹窗。
  - 已验证 `Info.plist` 的 `NSCameraUsageDescription` 为 `WalkFlow-Mac uses the camera to recognize hand gestures for remote control.`。
- 已完成 Task 6.2 CGEvent output TDD：
  - RED：新增 `CGEventOutputTests` 后，focused test 因 `CGEventOutput` / `CGEventPosting` 不存在失败。
  - GREEN：新增 dry-run 可注入 `CGEventOutput`，映射 scroll up/down delta，并用 `kVK_RightCommand` 生成右侧 Command down/up 事件。测试只记录 fake poster events，不发送真实滚动或按键。
- 已执行 `swift test --filter SystemPermissionServiceTests`、`swift test --filter CGEventOutputTests`、`swift test`、`swift build` 和 `git diff --check`，结果写入 `review.md`。
- Phase 6 code review 初审发现 1 个 Important 和 2 个 Minor：
  - Important：冻结计划要求触碰 permissions/event output 时也要补 `./script/build_and_run.sh --verify` 验收证据，初审时文档尚未记录该证据。
  - Minor：permission tests 缺少 camera `.restricted` / `.notDetermined` 映射覆盖；event output tests 缺少 `.none` / `.stopContinuousScroll` no-op 覆盖。
- 已补充 `SystemPermissionServiceTests.testCameraStatusMapsRestrictedAndNotDetermined` 和 `CGEventOutputTests.testNoOpActionsDoNotPostEvents`，并重新执行 focused tests、全量 `swift test`、`swift build`、`./script/build_and_run.sh --verify`、`git diff --check`、冻结 `plan.md` hash 检查和 SwiftUI 禁用检查。
- Phase 6 re-review 已通过：reviewer 确认之前 1 个 Important 和 2 个 Minor 均已关闭，未发现新的 Critical / Important / Minor，并批准 Phase 6 从 code-review 角度进入 checkpoint commit。
- Phase 6 人工 right-Command 验证仍按冻结计划后移：当前仅完成 dry-run event mapping；必须等后续 app integration 能从真实手势路径触发 `pressRightCommand` 后，再用 Keyboard Viewer 或用户 dictation 配置验证右侧 `Command` 是否被系统按预期识别。

## 下一步

完成 Phase 6 code review gate 和 checkpoint commit；随后继续进入 Phase 7 Camera / Vision。

## 阻塞

暂无阻塞。上一阻塞已由用户确认后解除：`Package.swift` 采用代码侧最小修复，冻结的 `plan.md` 不修改。
