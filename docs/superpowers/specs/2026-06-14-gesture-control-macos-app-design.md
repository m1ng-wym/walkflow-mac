# WalkFlow-Mac 设计规格

## 目标

构建 `WalkFlow-Mac`：一个 AppKit-only 的 macOS 原生工具，通过前置摄像头识别用户在 1 到 2 米距离内的手势，实现远距屏幕滚动、右侧 `Command` 键触发、暂停/恢复识别、误触保护和状态反馈。核心使用场景是用户在 vibe coding 时站立或走动，通过手势观察进度、滚动内容，并触发语音输入，而不是一直坐在键盘和鼠标前。

## 非目标

- 不使用 SwiftUI。
- 不把项目改成 monorepo。
- 不在第一版接入云端推理、付费 API、商业视觉 SDK 或真实外部 provider。
- 不把 Roboflow `supervision` 放入第一版 App 运行时。
- 不把标准菜单栏下拉菜单设计成长期常开的实时状态区域。
- 不在 Vision 未实测达标前，用硬凑规则掩盖识别不稳定问题。

## 已确认约束

- 后续开发全流程必须使用 AppKit。
- 正式项目名为 `WalkFlow-Mac`。
- GitHub 远端仓库为 `https://github.com/m1ng-wym/walkflow-mac.git`。
- Git 默认主分支为 `main`。
- 手势识别技术方案必须免费使用、轻量运行、适合 macOS 常驻工具。
- UI 文档和任务文档默认使用中文。
- 第一版目标是完整远距控制面，不是单一滚动或单一快捷键 demo。
- 复杂但可行且效果明显更好的方案要纳入考虑，不能为了实现简单而降级或绕过。

## 技术主线

第一版主线采用：

```text
AppKit
+ AVFoundation
+ Apple Vision hand pose
+ 自研 GestureClassifier
+ GestureStateMachine
+ CGEvent / Accessibility
```

`AVFoundation` 采集前置摄像头帧。`Vision` 输出手部关键点。`GestureClassifier` 使用几何规则识别五指张开、一指向上、一指向下、握拳、OK 捏合。`GestureStateMachine` 处理准备姿态、控制窗口、滚动节奏、OK 冷却和语音输入状态。系统动作执行层只接收状态机输出，通过 `CGEvent` / Accessibility 注入滚动和右侧 `Command`。

这条主线的关键理由是：Apple Vision 是系统内置框架，无需打包 Python runtime、OpenCV、NumPy、SciPy、Matplotlib 或外部 hand model；它和 AppKit、AVFoundation、权限体系、后台常驻模型最贴合。

## 备选方案进入条件

MediaPipe 是备选验证方向，不是默认运行时依赖。

如果 Apple Vision 在 1 到 2 米距离下无法稳定识别 OK 捏合或一指向上/向下等关键手势，应进入 MediaPipe 原生 spike。进入 spike 的判定标准是：任一关键手势在脚本化采样中正确识别率低于 95%，或 10 分钟待机场景中出现 1 次以上会触发系统动作的误识别。MediaPipe 只有同时满足两个条件，才允许纳入运行时：关键手势正确识别率较 Vision 提升至少 5 个百分点，且常驻 CPU、内存没有超过本规格的性能门槛。

Roboflow `supervision` 不作为第一版运行时依赖。它是 MIT 开源 Python CV 工具箱，适合检测结果、keypoints、标注、追踪、数据集和指标处理，但不提供手部姿态识别模型本身。它可用于离线研究或独立 Python 原型，不替代 Apple Vision 或 MediaPipe。

## 手势词汇表

第一版使用准备姿态模型。

- `Open Palm`：五指张开，手掌面向摄像头并短暂停顿。触发准备姿态，进入控制窗口。
- `Index Up`：一指向上，其余四指收缩。表示屏幕向上滚动。
- `Index Down`：一指向下，其余四指收缩。表示屏幕向下滚动。
- `Fist`：五指全部收拢。停止当前连续滚动，或退出控制窗口。
- `OK Pinch`：拇指和食指形成圆形接触，其余手指张开。触发右侧 `Command` 键。

滚动不采用大幅上下挥手作为默认动作。大幅挥手存在方向歧义、动作疲劳、离开画面、误触和滚动幅度不可控风险。

## 状态机

App 启用后进入 `Standby`。HUD 中心为空白，左上角绿点表示可用待机。

用户做 `Open Palm` 并稳定到阈值后，进入 `Ready`，开启 5 秒控制窗口。控制窗口内滚动手势和右侧 `Command` 触发手势有效。

控制窗口退出条件：

- 超过 5 秒没有新动作指令。
- 手部离开画面。
- 用户做 `Fist` 停止手势。

### 滚动

滚动采用短按/长按混合：

- `Index Up` 或 `Index Down` 姿态默认稳定 300 ms 后，先滚动一段。
- 继续保持超过 700 ms 后进入连续滚动。
- 连续滚动期间只要手势变化，立即停止滚动。

默认单步滚动距离、连续滚动速度和阈值必须集中在设置模型中，允许用户在设置里调整。初始默认值由实现计划给出，并用实测验证确认不会产生明显过快或过慢的滚动体验。

### 右侧 Command

右侧 `Command` 是用户当前语音输入配置键。按一次开始语音输入，再按一次结束语音输入。

`OK Pinch` 触发规则：

- 姿态默认稳定 300 ms 后触发一次。
- 触发后进入 1 秒冷却。
- 冷却后如果仍保持 `OK Pinch`，不重复触发。
- 必须松开后重新做 `OK Pinch` 才能再次触发。

第一次 `OK Pinch` 触发右侧 `Command` 后，进入语音输入中状态。第二次 `OK Pinch` 再次触发右侧 `Command` 后，结束语音输入。结束后不回到 `Ready` 图标；如果手仍可识别，回到 `Standby` 空白绿点；如果手不在画面，显示红点阻塞。

## 系统事件注入

滚动和右侧 `Command` 由执行层注入。执行层只接收状态机输出，不直接读取视觉帧。

后续实现必须验证：

- 滚动方向符合用户语义。
- 连续滚动可随手势变化立即停止。
- 右侧 `Command` 能被稳定表达为右侧修饰键，而不是泛化成任意 `Command`。
- 缺少 Accessibility 权限时不发系统事件，并清晰进入阻塞状态。

硬开关第一版不预设全局快捷键，避免默认冲突。设置里保留可配置全局快捷键选项。是否需要 `Input Monitoring`，由后续全局快捷键实现方案验证决定。

## 权限体验

主窗口左侧常驻权限面板。启动时一次性检查并引导必需权限。

必需权限：

- `Camera`：摄像头采集和手势识别。
- `Accessibility`：滚动和右侧 `Command` 注入。

预留权限：

- `Input Monitoring`：仅在后续启用全局快捷键配置时验证是否需要。

缺少必需权限时，主窗口仍可打开，但控制能力进入阻塞状态。HUD 显示红点和 `Alert triangle` loop 动效。权限面板提供权限状态、重新检查和打开系统设置入口。

## 主窗口

主窗口采用 AppKit 左右分栏，比例约 `1:4`。

左侧窄配置栏包含：

- 权限状态和修复入口。
- Enable / Pause 控制。
- HUD 显示、pin、位置恢复设置。
- 快捷键配置入口。
- 手势识别阈值和诊断信息。

右侧为摄像头预览和实时识别：

- 摄像头预览是主要区域。
- 预览区右上角复用一套 HUD 样式作为实时识别反馈。
- 该预览内 HUD 不替代真正的桌面浮动 HUD，只用于调试和校准。

## 菜单栏

菜单栏使用 AppKit `NSStatusItem` 和 `NSMenu`。

菜单栏图标显示总状态。菜单项包括：

- `Enable`
- `Pause`
- `Show HUD`
- `Open Window`
- `Settings`
- `Quit`

菜单栏菜单只做快速动作和入口，不承载长期实时状态。

## HUD 浮动面板

HUD 使用 AppKit 浮动面板，优先以非激活式 `NSPanel` 或自定义浮动窗口实现。

行为：

- 默认出现在屏幕右上角。
- 可 pin。
- pin 后不因点击其他区域而消失。
- 可拖动。
- 记住最后位置。
- 下一次启动恢复上一次拖动后的位置。
- 如果显示器变化导致保存位置不可用，回退到当前主屏幕右上角。

外观：

- 小巧、内容简洁。
- 顶部居中有一个小箭头，形成从菜单栏拉下来的视觉感。
- 左上角显示状态点。
- 中心区域同一时间只显示一个大图标。
- 用户草图中的中心方框仅表示图标位置，实际 UI 不显示方框。

状态点规则：

- 红点：`Disabled`、权限缺失、`Hand Lost`、`Stop` 等阻塞或不可控状态。
- 绿点：`Standby` 和正常可用状态。

`Standby` 中心区域保持空白，只显示绿点。

`Hand Lost`、`Stop`、`Paused`、`Cooldown` 暂不显示中心图标。其中 `Hand Lost` 和 `Stop` 使用红点表达。

## HUD 动效图标

中心状态图标使用 `https://useanimations.com/#explore` 的 Lottie 动效资源，必须保留网站原样动效。实现使用 AppKit + 原生 Lottie macOS renderer，不使用 SwiftUI，不默认使用 WebView。

图标映射：

- `Disabled`：`Lock / Unlock`。硬开关关闭时显示 lock 状态；开启硬开关后触发一次 unlock click 动效，动效结束后进入 `Standby`，中心图标消失。
- `Permission`：`Alert triangle` loop。
- `Ready`：`Infinity` loop。
- `Scroll Up`：`Arrow up` loop。
- `Scroll Down`：`Arrow down` loop。
- `Command`：`Dribbble` hover 后动效。第一次右侧 `Command` 触发后持续循环，直到下一次右侧 `Command` 触发结束语音输入。

已知实现风险：

- `react-useanimations@2.10.0` 包内存在 `lock`、`alertTriangle`、`infinity`、`arrowUp`、`arrowDown`、`dribbble` Lottie JSON。
- 包内没有独立 `unlock` 资源，`Lock / Unlock` 应视为同一 `lock` 动画的 click/backwards 状态控制。
- useAnimations 的动效是播放控制规则，不只是文件：`alertTriangle`、`infinity`、`arrowUp`、`arrowDown` 为 loop；`lock` 为 click/backwards；`dribbble` 为 hover/backwards。
- 原生 Lottie renderer 与网站的 `lottie-web` 可能存在细微差异。后续必须做视觉对比验证，优先调整播放区间、方向、循环和速度，不能退成静态图。

## 技术验证门槛

Apple Vision 主线必须先验证五个关键手势：

- 五指张开。
- 一指向上。
- 一指向下。
- 握拳。
- OK 捏合。

验证场景：

- 距离：1 米、1.5 米、2 米。
- 光照：正常室内光照、偏暗光照、背光。
- 左右手：左手和右手。
- 角度：手掌正对摄像头和轻微偏转。

如果 Vision 在目标距离和场景下稳定率达标，不引入 MediaPipe。若 Vision 对 OK 捏合或一指方向不稳定，进入 MediaPipe 原生 spike。

Apple Vision 达标标准：

- 每个关键手势在每个距离档位的正确识别率不低于 95%。
- 10 分钟 `Standby` 待机场景中，不出现会触发滚动或右侧 `Command` 的误触。
- 10 分钟语音输入场景中，持续 `Command` 状态不会被其他手势打断，第二次 `OK Pinch` 可以稳定结束语音输入。
- 从手势稳定到状态机输出动作的端到端延迟中位数不超过 250 ms。

## 性能验证

实现阶段必须验证：

- 摄像头采集 FPS。
- Vision 推理频率。
- 后台常驻 CPU 和内存。
- 主窗口打开/关闭的资源变化。
- HUD pin 后长期显示的 CPU 和内存。
- Lottie 动效循环期间的 CPU。
- 连续滚动期间的事件频率。
- 语音输入期间 `Dribbble` 动效长期循环的资源占用。

目标是常驻运行时不明显占用 CPU/内存，不导致 UI 卡顿，不显著影响 vibe coding 工作流。

第一版性能门槛：

- 空闲待机且摄像头识别开启时，App 进程 CPU 10 分钟平均不超过 15%。
- 空闲待机且摄像头识别开启时，App 进程常驻内存不超过 300 MB。
- HUD 单独循环 Lottie 动效时，CPU 增量不超过 3%。
- 主窗口关闭但菜单栏和 HUD 保持运行时，不保留不必要的预览渲染资源。
- 连续滚动事件频率必须被节流，避免造成目标 App 明显卡顿。

## 系统行为验证

实现阶段必须覆盖：

- 权限缺失。
- Camera 被其他 App 占用。
- Accessibility 未授权。
- 右侧 `Command` 注入准确性。
- 滚动方向准确性。
- 全屏空间。
- 多显示器。
- 自动隐藏菜单栏。
- Mission Control。
- HUD 保存位置对应的显示器不存在时的回退。

## 设计边界

视觉识别、手势分类、状态机、系统事件注入和 UI 必须分层。

`GestureClassifier` 不直接发系统事件。`GestureStateMachine` 不直接处理摄像头帧。`EventInjector` 不理解图像，只执行状态机输出的动作。这样后续如果从 Apple Vision 切换到 MediaPipe，只需要替换识别层和分类输入，不重写 HUD、菜单栏、权限面板和事件注入。

## 自审结果

- 占位检查：无 `TBD`、`TODO` 或空白章节。
- 一致性检查：AppKit-only、主线技术、HUD 状态、右侧 `Command` 触发规则和任务四文档一致。
- 范围检查：规格覆盖一个可独立实现的 macOS App bootstrap，不拆分为多个互相独立的子项目。
- 歧义处理：已明确默认时间阈值、Vision/MediaPipe 进入门槛和第一版性能门槛；可调参数进入设置模型，不作为未定义行为。
