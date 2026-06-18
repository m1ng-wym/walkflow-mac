# WalkFlow-Mac

`WalkFlow-Mac` 是一个 AppKit 原生 macOS 工具，通过前置摄像头识别手势，支持远距滚动、右侧 `Command` 触发和状态 HUD。

## 本地开发签名

本项目不要求付费 Apple Developer Program。为了避免 macOS Accessibility/TCC 在每次 rebuild 后因为 ad-hoc `cdhash` 变化而反复失效，先创建本机免费自签 Code Signing identity：

```bash
./script/setup_local_signing.sh
./script/build_and_run.sh --verify
```

详细说明见 [docs/LOCAL_SIGNING.md](docs/LOCAL_SIGNING.md)。

该本地证书只用于本机开发，不用于分发、release signing 或 notarization。不要共享、提交或导出私钥。
