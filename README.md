# mac-qq-exporter

[![Release](https://img.shields.io/github/v/release/sudo-yf/mac-qq-exporter?display_name=tag)](https://github.com/sudo-yf/mac-qq-exporter/releases/latest)
[![Platform](https://img.shields.io/badge/platform-macOS-blue)](https://github.com/sudo-yf/mac-qq-exporter/releases/latest)
[![Arch](https://img.shields.io/badge/arch-Apple%20Silicon-black)](https://github.com/sudo-yf/mac-qq-exporter/releases/latest)
[![Status](https://img.shields.io/badge/status-experimental-orange)](https://github.com/sudo-yf/mac-qq-exporter/releases/latest)

面向 `Apple Silicon macOS` 的 QQ 聊天记录导出运行包仓库。  
这不是上游开发源码仓库，而是一个 **可直接分发、安装、启动和恢复** 的 macOS 运行版。

它包含：

- `QCE Launcher.app` 双击启动器
- `qce` CLI
- `launcher-user.sh` 启动链
- `prepare-local-qq-app.sh` 本地 `QQ.app` 副本注入逻辑
- `qq-chat-exporter` 插件与静态资源

## Release

当前推荐版本：

- [V1.0001](https://github.com/sudo-yf/mac-qq-exporter/releases/tag/V1.0001)

下载资产：

- `NapCat-QCE-macOS-arm64-V1.0001.tar.gz`

## 一键安装并启动

如果本机已经 `gh auth login` 过，直接执行这一行：

```bash
curl -fsSL -H "Authorization: Bearer $(gh auth token)" \
  -H "Accept: application/vnd.github.raw" \
  https://api.github.com/repos/sudo-yf/mac-qq-exporter/contents/scripts/install.sh | bash
```

它会自动完成：

- 下载当前 `main` 分支内容
- 安装到 `~/Applications/QQ Chat Exporter/NapCat-QCE-macOS-arm64`
- 创建 CLI：`~/.local/bin/qce`
- 创建应用入口：`~/Applications/QCE Launcher.app`
- 自动执行 `qce start`

如果以后改成公开仓库，可简化成：

```bash
curl -fsSL https://raw.githubusercontent.com/sudo-yf/mac-qq-exporter/main/scripts/install.sh | bash
```

## 首次登录方式

首次没有可复用登录态时，不会直接进入主页面，而是进入 QQ 登录流程。

### 主页面

- `http://127.0.0.1:40653/qce-v4-tool/`

### 首次扫码登录页

- `http://127.0.0.1:40654/login`

当首次没有登录态时，优先打开：

```text
http://127.0.0.1:40654/login
```

这个页面会：

- 只显示二维码
- 自动刷新最新二维码
- 登录成功后自动跳转到 QCE 主页面

二维码原始文件同时保存在：

```text
~/Applications/QQ Chat Exporter/NapCat-QCE-macOS-arm64/cache/qrcode.png
```

## 适用范围

- 系统：`macOS`
- 架构：`Apple Silicon`
- 状态：`experimental`
- 依赖：本机已安装官方 QQ：

```text
/Applications/QQ.app
```

当前不承诺：

- Intel Mac
- Windows / Linux

## Quick Start

### 双击启动

双击：

```text
~/Applications/QCE Launcher.app
```

### 命令行启动

```bash
~/.local/bin/qce start
```

如果 `~/.local/bin` 不在 `PATH`，加入：

```bash
export PATH="$HOME/.local/bin:$PATH"
```

### 常用命令

```bash
qce start
qce stop
qce open
qce status
qce logs
qce rebuild
qce prepare
qce standalone
qce path
```

## 运行机制

这个版本不会直接修改系统 `/Applications/QQ.app`。

启动时会：

1. 检测本机 `QQ.app`
2. 复制出本地运行副本
3. 将 NapCat + QCE 运行时覆盖进副本
4. 使用副本启动 QQ 与导出服务

本地运行副本路径：

```text
~/Applications/QQ Chat Exporter/QQ-QCE-runtime.app
```

## 已验证内容

基于干净环境和真实运行验证过：

- 一条命令安装成功
- 自动启动成功
- `qce start` 可拉起 QQ / NapCat / QCE
- `qq-chat-exporter` 插件可成功加载
- `40653` 可监听
- `40654/login` 可返回二维码网页
- `http://127.0.0.1:40653/qce-v4-tool/` 可访问
- auth 页面可访问
- 静态资源、WebSocket、API 可访问

## 已知事项

- 首次没有登录态时，用户仍需自己用手机 QQ 扫码
- 启动日志里可能出现 NapCat 的 QQ 架构兼容提示
- 某些 QQ 大版本变更后，可能需要重新生成本地运行副本

## 仓库内容说明

这是一个 **可运行分发仓库**，不是最小源码差异仓库。

因此仓库中保留了运行所需的：

- `node_modules/`
- `native/`
- `static/`
- `plugins/`
- `QCE Launcher.app/`

这样做的目的是保证从 Git 历史和 Release 资产本身就能恢复可运行状态，而不只是拿到不完整源码。

## 恢复与重建

如果本地运行副本损坏，可以删除：

```text
~/Applications/QQ Chat Exporter/QQ-QCE-runtime.app
```

然后重新运行：

```bash
qce start
```

CLI 会自动重新准备本地副本。

## 致谢

- [NapCatQQ](https://github.com/NapNeko/NapCatQQ)
- [shuakami/qq-chat-exporter](https://github.com/shuakami/qq-chat-exporter)
