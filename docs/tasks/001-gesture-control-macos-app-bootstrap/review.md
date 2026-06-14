# macOS 远距手势控制工具 Review

## 风险

- 摄像头手势识别在 1 到 2 米距离下的可靠性取决于光照、摄像头角度、用户站位和手势设计。
- 系统级滚动和快捷键触发需要 macOS 隐私权限，后续必须明确 Camera、Accessibility、可能的 Input Monitoring 权限边界。
- 误触保护如果设计过重，会影响远距操作效率；如果设计过轻，会误触发系统动作。
- 使用手部向上/向下挥动来滚动可能存在方向歧义、动作疲劳、离开画面、误触和滚动幅度不可控风险；当前已改为静态一指向上/向下姿态作为滚动手势。
- 一指向上/向下姿态在 1 到 2 米距离下需要验证手指方向、手掌朝向、四指收缩和左右手镜像场景的识别稳定性。
- 握拳停止需要与滚动手势区分：滚动是单指伸出且四指收缩，停止是五指全部收拢。
- 触发右侧 `Command` 键需要验证 macOS 事件注入是否能稳定表达“右侧 Command”而不是泛化为任意 Command；后续实现必须包含本地验证。
- `OK` 捏合手势在 1 到 2 米距离下需要验证拇指和食指接触点识别稳定性，并防止持续保持姿态造成右侧 `Command` 重复触发。
- 长期保持菜单栏标准下拉菜单作为状态区域不符合 macOS 菜单交互预期；可行方向应是菜单栏锚定的自定义小窗口/Popover，或视觉上靠近菜单栏的可固定 HUD。
- 若需要“长期下拉状态区域”，后续实现可能需要 AppKit interop，例如 `NSStatusItem` 加自定义 `NSPopover`，或非激活式 `NSPanel`；需要验证焦点、全屏空间、多显示器和自动隐藏菜单栏行为。
- 已用 Build macOS Apps 插件说明和 Apple 官方文档复核菜单栏状态区可行性：插件建议 `MenuBarExtra` 用于轻量工具、状态和快速动作，深层工作流打开专用窗口，复杂菜单栏控制用 AppKit interop；Apple SwiftUI 支持 `MenuBarExtraStyle.menu` 和 `MenuBarExtraStyle.window`，其中 `.window` 是 popover-like window；Apple AppKit 的 `NSPopover.Behavior.applicationDefined` 允许应用负责关闭 popover。
- Apple HIG 对 menu bar extra 有更保守的平台建议：点击 menu bar extra 时显示 menu，而不是 popover。因此长期显示状态区不应设计成标准“菜单下拉常开”，更合适的产品定义是菜单栏图标 + 可固定状态 HUD/浮动面板，或菜单栏锚定的 `MenuBarExtra(.window)`/AppKit 面板并明确作为状态窗而非菜单。
- 用户已明确要求后续开发全流程必须使用 AppKit，不可以使用 SwiftUI；这会排除 `MenuBarExtra` 的 SwiftUI 实现路径，菜单栏和浮动面板应采用 AppKit，例如 `NSStatusItem`、`NSMenu`、`NSPanel`、`NSWindowController`。
- 可 pin 的固定浮动面板应避免标准菜单和 transient popover 行为，后续实现更适合使用非激活式 `NSPanel` 或自定义浮动窗口；需要验证全屏空间、多显示器、自动隐藏菜单栏、Mission Control 和窗口层级。
- 浮动面板位置持久化需要处理显示器变更：如果上次保存的位置对应的屏幕不存在，下一次启动应回退到当前主屏幕右上角。
- 用户要求 useAnimations 图标必须保留网站原样动效；已核验 npm 包 `react-useanimations@2.10.0` 依赖 `lottie-web`，并提供 Lottie JSON 资源。由于项目禁止 SwiftUI，后续应采用 AppKit 可承载的 Lottie 播放方案，而不是 React 组件或 SwiftUI 包装。
- 已核验 `react-useanimations@2.10.0` 包内存在 `lock`、`alertTriangle`、`infinity`、`arrowUp`、`arrowDown`、`dribbble` 资源；包内未发现独立 `unlock` 资源，`Lock / Unlock` 应视为同一 `lock` 动画的 click/backwards 状态控制。
- useAnimations 的动效类型是播放控制规则，不只是文件：`alertTriangle`、`infinity`、`arrowUp`、`arrowDown` 为 loop；`lock` 为 click/backwards；`dribbble` 为 hover/backwards。后续实现需要复刻这些播放控制，不能只做静态渲染。
- `Dribbble` 默认 hover 行为是鼠标进入播放、离开反向/停止；用户需求是语音输入期间保持 hover 后动效循环，直到下一次右侧 `Command` 触发结束语音输入，因此后续实现需要状态机驱动播放，而不是依赖鼠标 hover。
- useAnimations/npm 包授权和 attribution 需要在实现计划中复核并沉淀到第三方资源说明，避免遗漏开源归属要求。
- 用户已选择 `AppKit + 原生 Lottie macOS renderer`，不用 WebView 作为默认实现路径；风险是原生 renderer 与 useAnimations 网站的 `lottie-web` 表现可能有细微差异。
- 后续验证必须包含原始 useAnimations/lottie-web 动效与原生 Lottie macOS renderer 的视觉对比；如果存在差异，应优先调整播放区间、方向、循环和速度控制。
- 用户已确认所有当前项目内容需要纳入仓库；`.gitignore` 已调整为不再忽略 `AGENTS.md` 或当前 `.superpowers/` 内容，仅忽略未来本地系统文件、构建产物和临时验证产物。

## Review 发现

- 当前暂无代码 review 发现。
- 设计规格自审发现并修正了三类可执行性歧义：`Vision` 达标标准、`MediaPipe` 进入门槛、第一版性能门槛。
- 设计规格已明确默认阈值：控制窗口 5 秒、滚动短按稳定 300 ms、连续滚动进入 700 ms、`OK Pinch` 稳定 300 ms、`OK` 冷却 1 秒。
- 实现计划自审未发现占位词命中；计划覆盖 AppKit-only、SwiftPM bootstrap、AVFoundation、Vision、手势分类器、状态机、CGEvent/Accessibility、权限、主窗口、菜单栏、HUD、useAnimations/Lottie、Vision gate、性能 gate 和 MediaPipe 条件分支。
- 用户已更新 git 权限规则：本地 commit 不需要额外同意；push、deploy 和破坏性 git 操作必须停止等待用户明确确认，破坏性 git 操作默认不做。
- 已同步修正 `plan.md` 和 `AGENTS.md`，移除 commit 前置确认冲突。
- 已统一正式项目口径：`WalkFlow-Mac`、`https://github.com/m1ng-wym/walkflow-mac.git`、默认分支 `main`。
- 实现计划中的 SwiftPM 命名已更新为 `WalkFlowMac` package/executable、`WalkFlowCore` library、`WalkFlowMacApp` app target，App 显示名为 `WalkFlow-Mac`。
- 当前项目内容已纳入 Git 跟踪，并完成首次 commit / push。

## 验证命令和结果

- 尚未进入实现阶段，暂无构建、测试或运行验证。
- 已执行只读仓库检查：`rg --files -uu`、`git status --short`、`git branch --show-current`。
- 已执行设计规格自审：检查占位词、内部一致性、范围和歧义，并将结果写入设计规格末尾。
- 已执行实现计划自审命令：`UNFINISHED_PATTERN="$(printf '%s|%s|%s %s|%s %s %s' 'TO''DO' 'T''BD' 'implement' 'later' 'fill' 'in' 'details')" && rg -n "待定|填充|适当|类似|后续实现|$UNFINISHED_PATTERN" docs/tasks/001-gesture-control-macos-app-bootstrap/plan.md`，结果为无命中。
- 已确认本地分支：`main`。
- 已确认远端目标：`https://github.com/m1ng-wym/walkflow-mac.git`。
- 已确认当前 `origin` fetch/push URL 均为 `https://github.com/m1ng-wym/walkflow-mac.git`。
- 已执行 `git add -A`，当前项目文件已纳入暂存并提交。
- 已执行 `git commit -m "docs: initialize WalkFlow-Mac planning docs"`，提交成功。
- 已执行 `git push -u origin main`，远端 `main` 分支创建成功，本地 `main` 已设置为跟踪 `origin/main`。
- 已执行 `git ls-remote --heads origin main`，确认远端 `refs/heads/main` 存在。

## 跳过的检查

- 未运行 build、test、lint：仓库尚未定义 App、包管理器或验证命令。

## 关键决策

- 第一版目标不是单一功能 MVP，而是完整远距控制面。
- 暂停/恢复识别采用混合控制：菜单栏和全局快捷键作为硬开关，远距手势作为软开关。
- 第一版手势交互采用准备姿态模型。
- 控制窗口退出条件为约 5 秒无新动作指令、手部离开画面或停止手势。
- 已确认准备姿态为五指张开且手掌面向摄像头。
- 已确认滚动手势为一指向上或一指向下且其余四指收缩。
- 已确认滚动节奏为短按/长按混合，连续滚动中手势变化即停止。
- 已确认停止手势为握拳。
- 已确认快捷键触发目标为右侧 `Command` 键，用于用户现有语音输入开始/结束切换。
- 已确认右侧 `Command` 键触发手势为 `OK` 捏合。
- 已确认 `OK` 捏合采用稳定触发加冷却，必须释放后才能再次触发。
- 已确认 App 外壳为主窗口为主、菜单栏状态为辅。
- 已确认后续开发全流程必须使用 AppKit，不可以使用 SwiftUI。
- 已确认状态反馈采用菜单栏图标加可 pin 固定浮动面板，默认固定在屏幕右上角。
- 已确认浮动面板可拖动并记住最后位置。
- 已确认浮动面板同一时间只显示一个大图标。
- 已确认浮动面板外观采用用户草图方向：顶部居中小箭头、左上角状态点、中心单一状态图标区域。
- 已确认状态图标使用 useAnimations Lottie 动效资源，并保留原样动效。
- 已确认 Lottie 集成采用 AppKit + 原生 Lottie macOS renderer。
- 已确认 `Command` 结束后不回 `Ready`；手仍可识别时回 `Standby` 空白绿点，手不在画面时红点阻塞。
- 已确认主窗口左右分栏约 `1:4`，右侧摄像头预览中复用 HUD 样式作为实时识别浮层。
- 已确认权限体验为主窗口权限面板常驻加启动时一次性引导。
- 已确认硬开关第一版不预设全局快捷键，仅保留设置项；这可能降低默认情况下对 Input Monitoring 权限的依赖，但实现时仍需验证全局快捷键配置方案。
- 手势识别方案调研结论：Apple Vision 是当前最适合第一版的主候选，因为它是 macOS 内置框架、免费、无需额外模型文件、AppKit 可直接集成；但必须用本项目手势词汇表做 1 到 2 米实测，尤其是 `OK` 捏合、一指向上/向下、四指收缩和握拳之间的区分。
- MediaPipe Hand Landmarker 是最强备选：免费、Apache 2.0、开源项目和社区使用最多，官方模型输出 21 个手部关键点并有轻量 tracking 优化；风险是引入模型/runtime、AppKit 原生集成复杂度和常驻资源占用高于 Apple Vision。
- OpenCV 传统几何/轮廓方案免费且轻，但在普通室内光照、肤色、背景、遮挡和远距小手区域下鲁棒性不足，不适合作为第一版主识别方案。
- TensorFlow.js/Fingerpose/Web 路线免费且社区教程多，但会引入 WebView/JS runtime，不符合当前 AppKit-only 和轻量常驻目标，不推荐作为主线。
- 自训练 Core ML 免费但需要采集数据、训练和评估，第一版成本高；可作为后续提升分类器稳定性的增强项。
- 商业/产品类方案如 Airpoint、GestureX、AGI Gestures 可作产品参考，不适合作为依赖：要么不是开源 SDK，要么模型/授权/运行成本不透明。
- Roboflow `supervision` 量化评估：项目 MIT 开源，当前 PyPI 稳定版本为 `0.28.0`，`develop` 分支为 `0.29.0.rc0`；支持 MacOS/Windows/Linux 和 Python 3.9-3.14。它是 model-agnostic 的 Python CV 工具箱，提供检测、分割、标注、追踪、数据集转换、指标和 keypoint 结果标准化能力，但不包含手部姿态识别模型或推理引擎本身。
- 在本机 MacBook Air M2 / 16GB / Python 3.10 / arm64 的全新 venv 中，`pip install --dry-run --report supervision` 解析出 23 个包，wheel 下载体积合计约 87.6 MB；真实安装后 `site-packages` 约 331 MB，不含独立打包 Python runtime 的额外体积。主要展开体积为 `cv2` 119 MB、`scipy` 92 MB、`numpy` 29 MB、`matplotlib` 26 MB、`PIL` 14 MB、`supervision` 自身 2.2 MB。
- 在同一临时 venv 中，第二次执行 `import supervision as sv` 的最大 RSS 约 128 MB，峰值内存 footprint 约 88 MB；这只是 import 后的空闲成本，不包含摄像头采集、模型推理或跨进程通信。
- 对照：Python `mediapipe` 在全新 venv 中解析出 19 个包，wheel 下载体积合计约 88.1 MB；真实安装后 `site-packages` 约 299 MB，第二次 `import mediapipe` 最大 RSS 约 78 MB。MediaPipe 原生 Hand Landmarker `hand_landmarker.task` 模型文件约 7.5 MB。
- 对照：Apple Vision 主方案不需要随 App 打包 Python runtime、OpenCV、NumPy、SciPy、Matplotlib 或外部 hand model；它的增量包体积接近 0 MB，因为使用系统内置 Vision/AVFoundation 框架。其 CPU/FPS/准确率仍必须通过本项目手势词汇表实测确认。
- “Python/OpenCV/模型推理生态”的具体含义：如果把 `supervision` 放入运行时，AppKit 主进程无法直接调用 Swift/AppKit 类型来完成识别，通常需要嵌入 Python 或启动 Python sidecar；视频帧要从 AVFoundation/AppKit 传到 Python/OpenCV/NumPy，某个外部模型完成推理后，再把 keypoints/结果传回 AppKit 状态机。`supervision` 主要处理推理结果，不负责产生本项目需要的手部关键点。
- 更新后的选型边界：复杂度本身不是淘汰理由；如果某个 `supervision + 具体模型` 组合在本项目手势上显著优于 Apple Vision/MediaPipe，并且常驻资源可接受，应纳入候选。但当前单独的 `supervision` 不是识别模型，因此不能替代 Apple Vision 或 MediaPipe；第一版不应把它作为核心识别运行时依赖。
- 已确认第一版技术主线：`AVFoundation + Apple Vision hand pose + 自研轻量 GestureClassifier + GestureStateMachine + CGEvent/Accessibility + AppKit`。
- 已确认 Apple Vision 的验证门槛：在 1 到 2 米距离下，五指张开、一指向上、一指向下、握拳、OK 捏合五个关键手势识别稳定率达标，则不引入 MediaPipe。
- 已确认 MediaPipe 进入门槛：如果 Vision 对 OK 捏合或一指方向等关键手势不稳定，再做 MediaPipe 原生 spike；只有 MediaPipe 显著提升识别稳定性且 CPU/内存可接受，才纳入运行时。
- 在设计规格获得用户批准前，不进入代码实现。
- 早期因项目级 `AGENTS.md` 曾要求 commit 前必须先问用户，未自动 commit 设计规格；当前规则已更新为本地 commit 可直接执行。
- 用户要求 implementation plan 写入当前任务 `plan.md`，因此未创建 `docs/superpowers/plans/` 下的新计划文件。
