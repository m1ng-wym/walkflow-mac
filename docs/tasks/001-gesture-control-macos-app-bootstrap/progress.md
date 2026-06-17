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
- 已完成 Phase 6 checkpoint commit：`3906c53 feat: add permissions and event output`。

### 2026-06-16 Phase 7 Camera And Vision Pipeline 进度

- 已完成 Task 7.1 camera preview TDD：
  - RED：新增 `CameraPreviewViewTests` 后，focused test 因 `CameraPreviewView` 和 `CameraSessionController` 不存在失败。
  - TDD 调整：为避免未测试地创建 `CameraSessionController`，在计划原有 preview layer 测试基础上补充 preview session attach 测试和 lightweight recognition preset 测试，再写生产代码。
  - GREEN：新增 `CameraPreviewView`，使用 `AVCaptureVideoPreviewLayer`，默认 `.resizeAspectFill`，并支持 attach `AVCaptureSession`；新增 `CameraSessionController`，持有 `.vga640x480` session、可配置 camera input/video data output，并通过 `CameraFrameConsumer` 转发 sample buffer。
  - 已执行 `swift test --filter CameraPreviewViewTests`、`swift test` 和 `swift build`。
- 已完成 Task 7.2 Vision hand-pose provider TDD：
  - RED：新增 `VisionHandPoseProviderTests` 后，focused test 因 `VisionHandPoseProvider` 不存在失败。
  - GREEN：新增 `VisionHandPoseProvider`，使用 `VNDetectHumanHandPoseRequest(maximumHandCount: 1)`，将 Vision 21 个手部关键点映射到 `HandPoseSnapshot` 的 `HandJointName`。
  - 已执行 `swift test --filter VisionHandPoseProviderTests`、`swift test`、`swift build`、`./script/build_and_run.sh --verify`、`git diff --check`、冻结 `plan.md` hash 检查和 SwiftUI 禁用检查。
- Phase 7 spec/code review 均已完成，未发现 Critical / Important；reviewer 提出的 Vision joint map 测试覆盖 Minor 已补充为 `Set(jointMap.values) == Set(HandJointName.allCases)` 并重新跑通 focused test。
- Phase 7 仍保留一个非阻塞残余风险：`CameraSessionController.configure()` 和真实 frame delivery 不在自动化测试中触发，避免测试请求真实摄像头权限；后续 Phase 8/12 app integration 和 manual smoke gate 必须验证。
- 已完成 Phase 7 checkpoint commit：`ebefc5f feat: add camera and vision pipeline`。

### 2026-06-16 Phase 8 App Orchestration 进度

- 已完成 Task 8.1 AppController TDD：
  - RED：新增 `AppControllerTests` 后，focused test 因 `AppController`、`SettingsStoring`、`PermissionServicing`、`CameraControlling`、`HUDPresenting` 等不存在失败。
  - GREEN：新增 `AppStateStore` 和 `AppController`，提供 settings、permissions、camera、Vision、classifier、event output、HUD presenter 注入边界；连接 `CameraFrameConsumer`、`GestureClassifier`、`GestureStateMachine`、`HUDStateReducer` 和 `ControlEventOutput`。
  - AppController 测试覆盖：权限阻塞不启动 camera；权限允许时启动 camera；disabled 显示 lock HUD；disabled/paused 不执行 gesture actions；disabled 状态不会暗中预热状态机并在重新启用后直接触发滚动。
  - RED/GREEN 中发现 `GestureStateOutput` initializer 仍是 internal，App target 无法构造阶段需要的 blocked/standby output；已在 `WalkFlowCore` 中补充 public initializer，未改变状态机行为。
  - RED/GREEN 中发现 AppController 会把 `.none` action 也下发给 event output；已修正为只下发非 `.none` action。
  - RED/GREEN 中发现 disabled/paused/permission-blocked 时仍会先喂状态机，可能形成隐藏 ready 状态；已补充失败测试并修正为阻塞状态不推进状态机。
- 已执行 `swift test --filter AppControllerTests`、`swift test`、`swift build`、`./script/build_and_run.sh --verify`、`git diff --check`、冻结 `plan.md` hash 检查和 SwiftUI 禁用检查。
- Phase 8 初轮 spec/code review 未发现 Critical，但共发现 5 个 Important：
  - permission-blocked `handleObservation(_:)` 缺少不发事件/不预热状态机的自动化证明。
  - `setEnabled(_:)`、`setPaused(_:)`、`stopRecognition()` 未 reset `stateMachine`，会遗留已 ready / continuous-scroll 状态。
  - camera frame callback 与 AppKit/main-thread 操作之间存在共享 mutable state 竞态风险。
  - 缺少 permission-blocked observation path 的测试。
  - 缺少允许状态下手势动作确实进入 `eventOutput.execute` 的正向测试。
- 已按 TDD 修复上述 review findings：
  - 新增并跑通 permission-blocked observation 不执行、不预热状态机测试。
  - 新增并跑通 permitted armed gesture 正向 scroll action 测试。
  - 新增并先观察 RED，再修复 disable/pause/stop 清空已 ready 状态机的 lifecycle tests。
  - `AppController` 增加 `NSRecursiveLock` 保护 `state` / `stateMachine` / event output 边界，并在 disable/pause/stop 时 reset state machine。
- Important 修复后已重新执行 `swift test --filter AppControllerTests`、`swift test`、`swift build`、`./script/build_and_run.sh --verify`、`git diff --check`、冻结 `plan.md` hash 检查和 SwiftUI 禁用检查；正在等待 Phase 8 re-review。
- Phase 8 re-review 已通过：spec reviewer 确认上一轮 Important 已关闭；code-quality reviewer 确认 4 个 Important 均已关闭，未发现新的 Critical / Important / Minor，并批准 Phase 8 从 code-quality 角度进入 checkpoint commit。

### 2026-06-16 Phase 9 Main Window AppKit UI 进度

- 已进入 Task 9.1 主窗口 AppKit UI。
- 已完成 `MainWindowControllerTests` TDD：
  - RED：新增主窗口测试后，focused test 因 `MainWindowController` / `PreviewContainerView` 等 AppKit UI 类型不存在而失败；测试闭包的类型推断问题已在 RED 阶段修正为显式 `constraint` 参数，不改变验收目标。
  - GREEN：新增 `MainWindowController`、`ControlPanelView`、`PermissionPanelView`、`PreviewContainerView`，实现左右 split layout、左侧 220 pt 配置/权限区域、右侧摄像头预览容器。
  - 在 plan 指定的主窗口布局测试基础上，补充 `testPreviewPaneContainsCameraPreviewView`，证明右侧 preview pane 确实持有 `CameraPreviewView`。
- Phase 9 code-quality review 提出 1 个 Minor：缺少 `ControlPanelView` / `PermissionPanelView` 按钮 target-action 点击路径测试。已补充 `testControlPanelButtonsDriveAppControllerState` 和 `testPermissionPanelRecheckRefreshesPermissionSnapshot`，并修正测试 helper 以递归遍历 `NSStackView.arrangedSubviews`。
- Phase 9 code-quality re-review 已通过：reviewer 确认上一轮 Minor 已关闭，未发现新的 Critical / Important / Minor。
- 已执行 `swift test --filter MainWindowControllerTests`、`swift test`、`swift build`、`./script/build_and_run.sh --verify`、`git diff --check`、冻结 `plan.md` hash 检查和 SwiftUI 禁用检查。
- 当前 Phase 9 基础实现未装配 `AppDelegate`、HUD 或 menu bar，符合冻结计划要求；完整启动装配后移到 Phase 10。

### 2026-06-16 Phase 10 HUD Floating Panel And Menu Bar 进度

- 已完成 Task 10.1 HUD floating panel TDD：
  - RED：新增 `HUDWindowControllerTests` 后，focused test 因 `HUDWindowController` 不存在失败。
  - GREEN：新增 `LottieStatusIconView` placeholder、`HUDView`、`HUDWindowController`，实现右上角 fallback origin、offscreen saved origin fallback、浮动 `NSPanel`、HUD presenter update 和拖动后位置保存。
  - 为满足项目 TDD gate，额外补充 `testWindowDidMovePersistsHUDOrigin`，用 isolated `UserDefaults` suite 验证 `windowDidMove` 写回 `SettingsStore`。
- 已完成 Task 10.2 menu bar controller TDD：
  - RED：新增 `MenuBarControllerTests` 后，focused test 因 `MenuBarController` 不存在失败。
  - GREEN：新增 `MenuBarController`，提供 `Enable`、`Pause`、`Show HUD`、`Open Window`、`Settings`、`Quit` 菜单项，菜单栏按钮使用手势占位图标；测试覆盖静态菜单标题、实际安装菜单项和 `Enable` / `Pause` target-action。
  - 已替换 Phase 1 临时 `AppDelegate` 窗口，装配 `AppController`、`MainWindowController`、`HUDWindowController` 和 `MenuBarController`，启动时刷新权限、按权限配置 camera 并启动识别。
- 已执行 `swift test --filter HUDWindowControllerTests`、`swift test --filter MenuBarControllerTests`、`swift test`、`swift build`、`./script/build_and_run.sh --verify`、`git diff --check`、冻结 `plan.md` hash 检查和 SwiftUI 禁用检查。
- Phase 10 review gate 初审发现 5 个 Important：HUD 拖动恢复验收未完成、HUD panel pin-state 自动化不足、HUD 顶部箭头越界可能被裁剪、saved origin 只要求 intersects 会接受部分越界位置、Enable/Pause 菜单项是单向命令而不是硬开关 toggle。
- 已按 TDD 补充并修复：
  - `HUDWindowControllerTests.testPanelIsConfiguredAsPinnedFloatingHUD` 覆盖 floating/pinned panel state。
  - `HUDViewTests` 覆盖箭头点位在 view bounds 内、panel body 为箭头预留空间。
  - `HUDWindowControllerTests.testSavedOriginIsRejectedWhenPanelWouldBePartiallyOffScreen` 覆盖部分越界保存位置 fallback。
  - `MenuBarControllerTests.testEnableMenuItemTogglesHardSwitch` 和 `testPauseMenuItemTogglesPauseAndResume` 覆盖菜单栏硬开关可关闭/恢复。
- 运行态验收更新：
  - `System Events` 对临时 SwiftPM app 的 AX window count 返回 0，Computer Use 也无法绑定窗口，因此没有使用这些路径作为视觉证据。
  - CoreGraphics 能看到主窗口和 HUD panel；通过写入 `hud.savedOriginX=1000`、`hud.savedOriginY=650` 后重启，CGWindow 检查 HUD bounds 为 `X=1000 Y=196 W=160 H=110`，与当前 956px 高屏幕坐标换算一致，证明保存位置会在真实 app 启动时恢复。
  - 验证后已恢复原先 HUD 保存位置 `X=1290`、`Y=789` 并重启，CGWindow 检查 HUD bounds 回到 `X=1290 Y=57 W=160 H=110`。
- Phase 10 re-review 已通过：spec reviewer 确认 HUD pin-state 和保存位置恢复验收证据足以关闭 Important；code-quality reviewer 确认 HUD 箭头、保存位置部分越界和菜单硬开关 toggle 的 Important 均已关闭，未发现新的 Critical / Important / Minor。

### 2026-06-16 Phase 11 Lottie And useAnimations Assets 进度

- 已完成 Task 11.1 useAnimations 资源抓取：
  - 新增 `script/fetch_useanimations_assets.sh`，从 `react-useanimations@2.10.0` 抽取 `alertTriangle`、`arrowDown`、`arrowUp`、`dribbble`、`infinity`、`lock` 六个 Lottie JSON。
  - 新增 `docs/THIRD_PARTY_NOTICES.md`，记录 `react-useanimations` MIT license 和 `lottie-spm` / Lottie Apache-2.0 license。
  - 已执行资源脚本和 `npm view react-useanimations@2.10.0 license repository.url`，确认资源存在且 license 口径正确；`tar: Failed to set default locale` 是本机 locale warning，命令 exit 0。
- 已完成 Task 11.2 原生 Lottie renderer TDD：
  - RED：新增 `LottieStatusIconViewTests` 后，focused test 因 placeholder `LottieStatusIconView` 缺少 `resourceName` / `resourceURL` 失败，同时 SwiftPM 警告 6 个 JSON 未声明为 resources。
  - GREEN：`Package.swift` 为 `WalkFlowMacApp` target 增加 `.copy("Resources/Lottie")`；`LottieStatusIconView` 改为 AppKit 原生 `LottieAnimationView`，通过 `Bundle.module` 加载 JSON，loop 状态使用 `.loop`，`unlockOnce` / `lock` 使用 `.playOnce`。
  - 追加 RED/GREEN：补充 `testShowConfiguresLoopingAndOneShotAnimations`，先证明缺少 renderer 可观察状态，再补内部只读状态，验证 `.arrowUp` loop、`.unlockOnce` playOnce、`.none` 清空动画。
  - 本地自审追加 RED/GREEN：补充 `testInitialViewStartsEmptyAndHidden`，先证明初始 `.none` 时内部 Lottie view 未隐藏，再用 `clearAnimation()` 修复 init / `.none` 路径，确保 `Standby` 空白状态不显示中心动画。
  - Phase 11 code-quality review 发现 1 个 Important：`LottieAnimation.filepath(...)` 可能返回 `nil`，旧实现会显示空白并把 `currentIcon` 锁到目标 icon，导致同一 icon 不能重试；已补充 `testFailedAnimationParseClearsAndAllowsRetryForSameIcon` 的 RED/GREEN，改为解析成功后才更新 `currentIcon` 和显示动画，并补充 `testAllMappedIconsLoadThroughNativeRenderer` 覆盖所有映射 icon 的原生 Lottie 解析。
  - Phase 11 code-quality review 发现 1 个 Minor：第三方 notice 缺少完整 license / 作者信息，且脚本重跑会覆盖补充内容；已增强 `script/fetch_useanimations_assets.sh`，生成 useAnimations 作者、MIT 文本、Lottie Apache-2.0 文本，并在本地 `lottie-spm` checkout 存在时追加上游 `LICENSE` 原文。
  - 子代理只读检查发现 SwiftPM `Bundle.module` 在 staged `.app` 中查找 `.app/WalkFlowMac_WalkFlowMacApp.bundle`，不是 `Contents/Resources/...`；已先用 `test -s dist/WalkFlow-Mac.app/WalkFlowMac_WalkFlowMacApp.bundle/Lottie/alertTriangle.json` 证明旧 staging 失败，再修复 `script/build_and_run.sh` 将 resource bundle 复制到 `.app` 根目录，并让 `--verify` 同时检查 Lottie JSON。
- useAnimations 视觉/行为对比：
  - 已打开 `https://useanimations.com/` 并核验页面文案：`Alert triangle`、`Infinity`、`Arrow down`、`Arrow up` 标注为 `Loop`，`Lock / Unlock` 标注为 `Click me`，`Dribbble` 标注为 `Hover me`。
  - 当前实现按上述交互类型映射为 loop 或 playOnce；真实手势状态逐项触发的视觉 E2E 仍需等 Phase 12 之后可以稳定注入/触发状态时继续验证。
- 已执行 Phase 11 focused tests、全量 `swift test`、`swift build`、`./script/build_and_run.sh --verify`、`git diff --check`、冻结 `plan.md` hash 检查和 SwiftUI 禁用检查；最新 focused `LottieStatusIconViewTests` 为 6 个 XCTest 通过，全量 `swift test` 为 78 个 XCTest 通过，结果写入 `review.md`。
- Phase 11 spec review 初审发现 1 个 Important：文档仍记录追加自审前的 3/75 测试数量，缺少 `testInitialViewStartsEmptyAndHidden` 的 RED/GREEN 证据。已补充本段和 `review.md`，轻量复审已关闭该 Important。
- Phase 11 spec re-review 已关闭上一轮 Important，未发现新的 Critical / Important / Minor。Phase 11 code-quality re-review 已关闭上一轮 Important 和 Minor，未发现新的 Critical / Important / Minor，并批准 checkpoint commit。

### 2026-06-16 Phase 12 Main Integration Verification 进度

- 已完成 Task 12.1 preview layer / camera session 接线 TDD：
  - RED：新增 `AppControllerTests.testAttachPreviewAssignsCameraSessionToPreviewLayer` 后，focused test 因 `AppController` 缺少 `attachPreview(to:)` 失败。
  - GREEN：`AppController.attachPreview(to:)` 调用 `CameraPreviewView.attach(session:)`，`MainWindowController` 初始化时把右侧 camera preview 连接到 `AppController` 持有的 camera session。
  - focused test 通过：1 个 XCTest，0 failures；随后 `AppControllerTests` 为 12 个 XCTest 通过。
- 已完成 Task 12.2 telemetry logging RED/GREEN：
  - RED：在添加日志前运行 `./script/build_and_run.sh --telemetry 2>&1 | rg 'gestureHUD='`，5 秒内无 `gestureHUD=` 输出，随后中断流。
  - GREEN：`AppController` 增加 `OSLog.Logger(subsystem: "com.m1ngwym.walkflowmac", category: "Gesture")`，每次 `publishLatestHUD()` 输出 `gestureHUD=<message> icon=<icon>`。
  - telemetry GREEN：运行 `./script/build_and_run.sh --telemetry 2>&1 | rg -m 1 'gestureHUD='` 捕获 `gestureHUD=Permission icon=alertTriangle`。
- Phase 12 spec review 已通过：未发现 Critical / Important / Minor；确认 manual behavior matrix 未执行不阻塞本阶段自动化 checkpoint，但阻塞最终真实 E2E 完成声明。
- Phase 12 code-quality review 发现 2 个 Important 和 1 个 Minor：
  - Important：HUD telemetry 原先每次发布都写日志，可能在 camera frame path 中产生高噪声，并且日志位于 `stateLock` 持有区内。
  - Important：`attachPreview(to:)` 触碰 AppKit / `AVCaptureVideoPreviewLayer`，但缺少主线程边界。
  - Minor：`MainWindowControllerTests` 缺少主窗口实际接入 fake camera session 的集成断言。
- 已按 TDD 修复 review findings：
  - RED：新增 `AppControllerTests.testTelemetryLogsOnlyHUDTransitions` 后，先因 `HUDTelemetryLogging` / `telemetryLogger` 注入点不存在失败。
  - GREEN：新增可注入 `HUDTelemetryLogging` / `OSLogHUDTelemetryLogger`，HUD 存储和 HUD 发布拆分为锁内 `store`、锁外 `publish`，并通过 `lastLoggedHUD` 只记录 transition。
  - 为 `attachPreview(to:)` 增加主线程 precondition，明确 AppKit 线程边界。
  - 补充 `MainWindowControllerTests.testPreviewPaneAttachesAppControllerCameraSession`，证明主窗口右侧 preview 的 session 来自注入的 camera controller。
- Phase 12 code-quality re-review 发现新的 1 个 Important：`handleObservation()` 在锁内决定 action 后释放 `stateLock`，再在锁外执行 `eventOutput.execute`，可能允许 `setPaused(true)` / `setEnabled(false)` 插入并仍发出一次系统事件。
- 已按 TDD 修复新 Important：
  - RED：新增 `AppControllerTests.testPauseCannotInterleaveBetweenGestureDecisionAndEventOutput`，用阻塞 fake event output 复现 pause 插入“决定动作”和“真正 post”之间，当前锁外执行事件时测试失败。
  - GREEN：将 `eventOutput.execute` 放回 `stateLock` 临界区，保持“决定动作 + 执行动作”原子；HUD telemetry / presenter 仍在锁外执行。
- 已执行 Phase 12 review 修复后自动化验证：新增 focused tests 3 个通过；`swift test --filter AppControllerTests` 14 个 XCTest 通过；`swift test --filter MainWindowControllerTests` 5 个 XCTest 通过；全量 `swift test` 82 个 XCTest 通过；`swift build` 通过；`./script/build_and_run.sh --verify` 通过；telemetry 仍可捕获 `gestureHUD=Permission icon=alertTriangle`；`git diff --check` 通过；冻结 `plan.md` hash 未变；SwiftUI 禁用检查通过。
- Phase 12 code-quality 第二次 re-review 已通过：确认 telemetry 去重、主线程 precondition、事件执行同步边界和主窗口 preview session 集成断言均已关闭，未发现新的 Critical / Important / Minor。
- Phase 12 真实摄像头/真实手势人工矩阵尚未完成：该矩阵需要用户在设备前做 open palm、index up、index down、fist、OK pinch、hand lost 等实际动作，并观察滚动、右侧 `Command` 和 HUD；当前不能由 Codex 在无人配合下伪造为已通过。

### 2026-06-16 Phase 13 Recognition Metrics And Performance Gates 进度

- 已完成 Task 13.1 recognition metrics collector TDD：
  - RED：新增 `RecognitionMetricsTests` 后运行 `swift test --filter RecognitionMetricsTests`，失败原因符合预期，`RecognitionMetrics` 不存在。
  - GREEN：新增 `Sources/WalkFlowCore/Diagnostics/RecognitionMetrics.swift`，实现按 `GestureKind` 统计准确率和 standby 下 actionable gesture false trigger 计数。
  - focused test 通过：`swift test --filter RecognitionMetricsTests` 2 个 XCTest，0 failures。
  - 全量 test 通过：`swift test` 84 个 XCTest，0 failures。
  - `swift build` 通过。
- Phase 13.1 review gate 已通过：
  - spec reviewer 未发现 Critical / Important / Minor，确认实现与计划一致，且文档没有伪造 Phase 13.2 通过。
  - code-quality reviewer 未发现 Critical / Important / Minor，确认 metrics 语义、测试规模、`Sendable` / `Equatable` / access-control 和文档记录均可接受。
- Phase 13.1 checkpoint commit 已完成：`b3fd7db feat: add recognition metrics`。
- Phase 13.2 manual Vision gate 尚未执行：该 gate 需要用户在设备前按 `plan.md` 的矩阵完成真实手势验证，包括 1 m / 1.5 m / 2 m、normal indoor / dim / backlit、left / right hand、palm facing camera / slight rotation，并记录 accuracy、10 分钟 standby false trigger、10 分钟 voice input accidental interruption 和 median latency。
- 当前不能声明 Vision gate passed，也不能决定 MediaPipe spike 是否需要；该决定必须基于 Phase 13.2 真实矩阵结果。

### 2026-06-16 Camera Permission Launch Bugfix 进度

- Phase 13.2 启动人工 gate 前，用户反馈 App 没有弹出 Camera 权限框。
- 已按 systematic debugging 定位根因：`AVCaptureDevice.authorizationStatus(for: .video)` 仍为 `.notDetermined`，`SystemPermissionService` 已有 `requestCameraAccess`，但 `AppDelegate.applicationDidFinishLaunching` 只调用 `refreshPermissions()`、`configureCameraIfPermitted()`、`startRecognition()`，没有在 `.notDetermined` 状态下主动请求 Camera 授权。
- 已按 TDD 补充 `AppControllerTests.testLaunchPreparationRequestsCameraWhenNotDeterminedThenStartsAfterGrant`：
  - RED：focused test 先因 `AppController` 缺少 `prepareCameraAuthorizationAndStartRecognition()` 失败。
  - GREEN：`AppController` 新增启动授权准备流程；当 camera 为 `.notDetermined` 时调用 `permissions.requestCameraAccess`，授权回调后刷新权限、配置 camera，并启动识别；`AppDelegate` 改为走该启动流程。
- 已同步测试 fake permission services，使 `WalkFlowMacAppTests` 继续编译。
- 已运行修复版 `./script/build_and_run.sh run`，用户确认 macOS Camera 权限弹窗已出现，并已点击允许。
- 已用系统日志只读确认 TCC 记录到 `kTCCServiceCamera` / `com.m1ngwym.walkflowmac` 的创建事件；真实 Camera 权限链路已被触发。
- 已执行 bugfix 验证：
  - `swift test --filter AppControllerTests/testLaunchPreparationRequestsCameraWhenNotDeterminedThenStartsAfterGrant`：1 个 XCTest，0 failures。
  - `swift test`：85 个 XCTest，0 failures。
  - `swift build`：通过。
  - `./script/build_and_run.sh --verify`：通过，输出 `Verified WalkFlowMac is running.`。
  - `git diff --check`：通过。
  - `LC_ALL=C LANG=C shasum -a 256 docs/tasks/001-gesture-control-macos-app-bootstrap/plan.md`：`418fcbab21b9bcf18be86ff550bd5d1cc754f9a5bbfa71903dc556b257d198d7`，冻结计划未修改。
  - SwiftUI 禁用检查：`No SwiftUI references in Package.swift, Sources, Tests, script, or .codex`。
  - local-only 检查：`AGENTS.md`、`.superpowers/`、`docs/superpowers/`、`.worktrees/`、`worktrees/` 仍由 `.gitignore` 忽略；`AGENTS.md`、`.superpowers`、`docs/superpowers` 未被 Git 跟踪。
- Camera permission bugfix code-quality review 初审发现 2 个 Important：
  - `AVCaptureDevice.requestAccess` completion 不保证回调队列，原实现直接在 completion 内刷新权限、配置 camera、启动识别，线程边界不明确。
  - 原测试 fake 同步调用 completion，不能证明授权结果回来前不会 configure/start，也不能覆盖真实异步回调。
- 已按 TDD 修复 review findings：
  - RED：把 `testLaunchPreparationRequestsCameraWhenNotDeterminedThenStartsAfterGrant` 改为手动保存 completion，先断言 request 后 camera 仍未 configure/start，再从后台队列触发授权完成；当前实现失败在 configure/start 不是主线程。
  - GREEN：`AppController.prepareCameraAuthorizationAndStartRecognition()` 在 `requestCameraAccess` completion 内显式 `DispatchQueue.main.async` 后再刷新权限、配置 camera、启动识别；focused test 通过，1 个 XCTest，0 failures。
- review 修复后已重新执行验证：
  - `swift test`：85 个 XCTest，0 failures。
  - `swift build`：通过。
  - `./script/build_and_run.sh --verify`：通过，输出 `Verified WalkFlowMac is running.`。
  - `git diff --check`：通过。
  - `LC_ALL=C LANG=C shasum -a 256 docs/tasks/001-gesture-control-macos-app-bootstrap/plan.md`：`418fcbab21b9bcf18be86ff550bd5d1cc754f9a5bbfa71903dc556b257d198d7`，冻结计划未修改。
  - SwiftUI 禁用检查：`No SwiftUI references in Package.swift, Sources, Tests, script, or .codex`。
  - local-only 检查通过。
- Camera permission bugfix code-quality re-review 已通过：reviewer 确认原 2 个 Important 均已关闭，未发现新的 Critical / Important / Minor，Assessment 为 `Ready to merge? Yes`。
- 该修复只处理启动 Camera 授权请求缺口，不声明 Phase 13.2 Vision gate 已通过；真实手势矩阵仍需继续人工执行。

### 2026-06-17 Camera Preview / Accessibility Recheck Bugfix 进度

- Phase 13.2 继续前，用户反馈当前 App 主窗口右侧仍看不到摄像头画面、摄像头指示灯不亮，并且点击 `Accessibility` 下方的 `Recheck` 按钮没有可见反应。
- 已按 systematic debugging 定位根因：
  - `AppController.startRecognition()` 原先要求 `state.permissions.canControl == true` 才调用 `camera.start()`；`canControl` 同时要求 Camera 和 Accessibility，因此 Accessibility 未授权时 Camera 预览也被挡住。
  - `PermissionPanelView.recheck()` 原先只调用 `refreshPermissions()`，不会触发 `SystemPermissionService.promptForAccessibility()`，所以用户点击 `Recheck` 时没有 macOS Accessibility 授权引导。
- 已按 TDD 补充失败测试：
  - `AppControllerTests.testStartRecognitionStartsCameraPreviewWhenCameraGrantedButAccessibilityMissing` 先失败，证明 Camera 已授权但 Accessibility 缺失时 `camera.startCount` 仍为 0。
  - `MainWindowControllerTests.testPermissionPanelRecheckPromptsForAccessibilityWhenDenied` 先失败，证明 `Recheck` 未调用 Accessibility prompt。
- 已完成 GREEN 修复：
  - `startRecognition()` 改为 Camera granted 时即可启动 camera session，以便主窗口右侧预览出现；如果 Accessibility 仍缺失，HUD 继续显示红点/权限 alert，系统滚动和右侧 `Command` 仍由 `handleObservation(_:)` 的 `permissions.canControl` guard 阻塞。
  - `PermissionServicing` 增加 `promptForAccessibility()`；`PermissionPanelView` 的 `Recheck` 改为在 Accessibility denied 时触发授权引导并刷新权限。
- 已执行自动化验证：
  - 两个新增 RED/GREEN focused tests 均已通过。
  - `swift test --filter AppControllerTests`：18 个 XCTest，0 failures。
  - `swift test --filter MainWindowControllerTests`：6 个 XCTest，0 failures。
  - `swift test --filter MenuBarControllerTests`：5 个 XCTest，0 failures。
  - `swift test --filter SystemPermissionServiceTests`：4 个 XCTest，0 failures。
  - 全量 `swift test`：90 个 XCTest，0 failures。
  - `swift build`：通过。
  - `./script/build_and_run.sh --verify`：通过，输出 `Verified WalkFlowMac is running.`。
  - `git diff --check`：通过。
  - 冻结 `plan.md` hash 仍为 `418fcbab21b9bcf18be86ff550bd5d1cc754f9a5bbfa71903dc556b257d198d7`。
  - SwiftUI 禁用检查无命中；local-only artifact 检查通过。
- 已启动两个并行只读 subagent review：
  - 规格/权限边界 reviewer：重点检查是否错误放开了滚动/右侧 `Command` 的 Accessibility 权限边界。
  - 代码质量 reviewer：重点检查 camera start 时机、locking/publish、Recheck prompt、测试覆盖和回归风险。
- 规格/权限边界 reviewer 未发现 Critical / Important；指出 1 个 Minor：Camera granted + Accessibility denied 时还可补 `handleObservation(_:)` 不发事件/不预热状态机的直接回归测试。
- 已补充并跑通 `AppControllerTests.testAccessibilityBlockedObservationDoesNotExecuteOrPrimeGestureStateWhilePreviewRuns`，证明 Camera preview 可启动但 Accessibility 缺失期间的 open palm 不会预热控制窗口，授权后不会直接触发滚动。
- 代码质量 reviewer 发现 1 个 Important 和 2 个 Minor：
  - Important：用户真实入口是 `prepareCameraAuthorizationAndStartRecognition()` 的 already-determined 分支，不能只测直接 `startRecognition()`。
  - Minor：`Recheck` prompt 分支应断言 prompt 后刷新权限。
  - Minor：`SystemPermissionService.promptForAccessibility()` 应直接测试代理到 `AccessibilityTrustProviding.promptForTrust()`。
- 已补充并跑通对应测试：`testLaunchPreparationStartsPreviewWhenCameraGrantedButAccessibilityMissing`、增强后的 `testPermissionPanelRecheckPromptsForAccessibilityWhenDenied`、`testPromptForAccessibilityDelegatesToAccessibilityProvider`。
- 代码质量 re-review 已通过：确认上一轮 1 个 Important 和 2 个 Minor 均已关闭，未发现新的 Critical / Important / Minor；残余风险仅为 Codex 未直接观察真实摄像头画面、摄像头指示灯或 macOS Accessibility 授权 UI。
- 该修复解除“无法看到预览而无法进入手势验证”的实现阻塞，但真实摄像头画面是否出现、摄像头指示灯是否点亮，仍需用户在当前运行的 App 上现场确认。

### 2026-06-17 Phase 13.2 Manual Gate 权限与摄像头现场确认

- 用户已现场确认：当前 App 主窗口已出现摄像头画面。
- 用户已现场确认：Mac 摄像头指示灯已亮起。
- 用户已点击 `Recheck` 并按系统提示授予 `Accessibility` / “辅助功能”权限。
- Camera 现场启动阻塞已解除；`Accessibility` UI 授权确认已完成，但随后确认当前 ad-hoc app 未被 TCC 信任，仍需处理 code requirement mismatch 后才能进入真实手势 smoke。

### 2026-06-17 Accessibility TCC Code Requirement Mismatch 进度

- 用户反馈：HUD 浮窗仍显示红点和 `Permission` alert，五指张开准备姿态毫无反应。
- 已按 systematic debugging 重新定位根因：
  - 摄像头画面和指示灯已工作，当前不是 Camera pipeline 阻塞。
  - `tccd` 日志明确显示 `Failed to match existing code requirement for subject com.m1ngwym.walkflowmac and service kTCCServiceAccessibility`，并列出两个不同 `cdhash`。
  - 当前 `dist/WalkFlow-Mac.app` 为 ad-hoc 签名，`codesign -dr - dist/WalkFlow-Mac.app` 只输出 `designated => cdhash H"..."`；`security find-identity -p codesigning -v` 返回 `0 valid identities found`。
  - 结论：系统设置里存在 Accessibility 授权记录，但该记录绑定的是旧的 ad-hoc `cdhash`；重新 build/stage 后当前 App 的 `cdhash` 变化，`AXIsProcessTrusted()` 仍会返回 false，HUD 因权限 reducer 保持红点阻塞，手势事件按设计被挡住。
- 已确认不应继续通过修改手势阈值解决该问题；必须先修复本地运行/授权流程。
- 已按 TDD 为 run script 增加 no-build 启动保护：
  - RED：新增 `BuildRunScriptTests.testLaunchExistingModeDoesNotRebuildOrRestageBeforeModeDispatch`，先失败，证明脚本缺少 `--launch-existing`，且进入参数分支前无条件 `build_app` / `stage_bundle`。
  - GREEN：`script/build_and_run.sh` 新增 `--launch-existing|launch-existing`，仅关闭并打开现有 `dist/WalkFlow-Mac.app`，不会 rebuild 或 restage；`run`、`--verify`、`--logs`、`--telemetry` 分支仍负责 build/stage。
- Code review 发现 1 个 Important：原 no-build 回归测试只检查全局前置 build/stage 和模式存在，未直接检查 `--launch-existing` 分支本身未来不能调用 build/stage，也未正向检查 rebuild 模式仍 build/stage。
- 已按 review 加强测试：
  - `testLaunchExistingModeDoesNotRebuildOrRestageBeforeModeDispatch` 现在直接解析 `--launch-existing` 分支，断言该分支不包含 `build_and_stage_app` / `build_app` / `stage_bundle`，并包含 `launch_existing_app`。
  - 新增 `testRebuildModesStillBuildAndStageBeforeLaunch`，断言 `run`、`--verify`、`--logs`、`--telemetry` 仍调用 `build_and_stage_app`。
  - 新增 `testDebugModeStopsRunningAppBeforeBuilding`，保持 `debug` 分支先停旧进程再 build/stage 的旧行为。
- Code review 发现 1 个 Minor：历史文档段落仍写 Accessibility 现场阻塞已解除，容易与后续 TCC mismatch 结论冲突；已改为“Accessibility UI 授权确认已完成，但随后确认当前 ad-hoc app 未被 TCC 信任”。
- 已执行最终验证：
  - `swift test --filter BuildRunScriptTests`：3 个 XCTest，0 failures。
  - `swift test`：93 个 XCTest，0 failures。
  - `swift build`：通过。
  - `bash -n script/build_and_run.sh`：通过。
  - `git diff --check`：通过。
  - `./script/build_and_run.sh --verify`：通过，输出 `Verified WalkFlowMac is running.`。
  - `LC_ALL=C LANG=C shasum -a 256 docs/tasks/001-gesture-control-macos-app-bootstrap/plan.md`：`418fcbab21b9bcf18be86ff550bd5d1cc754f9a5bbfa71903dc556b257d198d7`，冻结计划未修改。
  - SwiftUI 禁用检查无命中。
  - 最终 staged app 的 current designated requirement：`cdhash H"f98a3fb31a3837ef001bf2438b98173140eaf071"`。
- 临时本地证书实验曾触发系统“证书信任设置”授权弹窗；已明确要求用户点“取消”，并中断命令。后续不在未获明确批准时修改系统证书信任或用户 keychain。
- 当前操作策略：完成本轮最终 build/stage 验证后，用户需要在系统设置中移除旧的 WalkFlow-Mac Accessibility 条目，并按当前 `dist/WalkFlow-Mac.app` 重新添加/启用一次；之后用 `./script/build_and_run.sh --launch-existing` 启动，不再 rebuild，继续 Phase 13.2 手势 smoke。

## 下一步

先完成 Accessibility TCC code requirement mismatch 的本地验证和文档收口。完成最终 `swift test`、`swift build`、`./script/build_and_run.sh --verify` 后，不要再 rebuild；由用户移除并重新添加当前 `dist/WalkFlow-Mac.app` 到 Accessibility，再用 `./script/build_and_run.sh --launch-existing` 启动现有包。若 HUD 从红点 `Permission` 进入绿点 standby，再继续 Phase 13.2 manual Vision gate：近距离 smoke `Open Palm` 进入 ready、`Index Up` / `Index Down` 滚动、`Fist` 停止、`OK Pinch` 触发右侧 `Command`，随后扩大到 1 m / 1.5 m / 2 m 的真实手势矩阵。

## 阻塞

Phase 13.2 当前仍存在真实外部阻塞：Accessibility UI 中“已开启”不等于当前 ad-hoc build 已被 TCC 信任。必须先按当前 staged app 重新建立 Accessibility 授权，并避免授权后再次 rebuild。该阻塞解除后，仍必须由用户在设备前执行真实摄像头/真实手势矩阵，才能记录 Vision gate 结果并决定是否进入 MediaPipe spike。
