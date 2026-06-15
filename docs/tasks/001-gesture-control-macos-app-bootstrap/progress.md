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

## 下一步

进入 `plan.md` 的 Phase 0 preflight，随后开始 AppKit-only macOS App bootstrap 实现。

## 阻塞

暂无阻塞。
