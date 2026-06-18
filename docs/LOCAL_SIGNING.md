# WalkFlow-Mac 本地签名

`WalkFlow-Mac` 需要 Camera 和 Accessibility 权限。macOS TCC 会用 app 的 code requirement 识别“这是不是同一个 app”。如果只用 ad-hoc 签名，rebuild 后 `cdhash` 会变化，Accessibility 授权可能反复失效。

本项目不要求付费 Apple Developer Program。开发者可以为自己的 Mac 创建一个免费本地自签 Code Signing 证书。

## 边界

这个证书只用于本机开发，目的是让 macOS TCC 在 rebuild 后仍能识别同一个本地开发版 App。它不是分发签名方案，也不用于 release signing、Developer ID、Gatekeeper 分发或 notarization。

## 一键配置

```bash
./script/setup_local_signing.sh
```

脚本会：

- 创建本机自签 Code Signing identity，默认名称为 `WalkFlow Local Development`。
- 导入当前用户默认 keychain。
- 请求 macOS 将该证书信任为 code signing 证书。
- 写入本地文件 `.walkflow-local-signing.env`。

`.walkflow-local-signing.env` 已被 `.gitignore` 忽略，不会提交到仓库。

## 使用

配置完成后，正常运行：

```bash
./script/build_and_run.sh --verify
```

`build_and_run.sh` 会自动读取 `.walkflow-local-signing.env` 并启用：

```bash
WALKFLOW_REQUIRE_CERT_SIGNING=1
WALKFLOW_CODESIGN_IDENTITY='WalkFlow Local Development'
```

## 验证

```bash
/usr/bin/security find-identity -p codesigning -v
/usr/bin/codesign -dr - dist/WalkFlow-Mac.app
```

`codesign -dr -` 不应再只显示：

```text
designated => cdhash H"..."
```

如果仍然是纯 `cdhash`，说明当前 app 仍是 ad-hoc fallback，不是稳定本地签名状态。

## 如果脚本没有完成信任

macOS 可能要求输入密码或使用 Touch ID 来变更证书信任设置。如果脚本提示证书还不是 valid code signing identity：

1. 打开 `Keychain Access`。
2. 找到 `WalkFlow Local Development`。
3. 打开证书详情。
4. 在 `Trust` 中将 Code Signing 设为信任。
5. 再运行：

```bash
./script/setup_local_signing.sh --check
./script/build_and_run.sh --verify
```

## 自定义名称

```bash
WALKFLOW_LOCAL_SIGNING_IDENTITY='My WalkFlow Signing' ./script/setup_local_signing.sh
```

不同开发者应使用自己的本机证书。不要共享、提交或导出私钥。
