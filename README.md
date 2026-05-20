# mac-qq-exporter

面向 `Apple Silicon macOS` 的 QQ 聊天记录导出运行包仓库。

这个仓库提供一套已经整理好的 macOS 运行时，包含：

- `QCE Launcher.app` 双击启动器
- `launcher-user.sh` 完整启动链
- `prepare-local-qq-app.sh` 本地 `QQ.app` 副本注入逻辑
- `QQ Chat Exporter` 插件及其静态资源

目标不是保留上游全部跨平台开发结构，而是提供一个 **可直接在 macOS 上使用** 的运行版本。

## Release

当前发布版本：

- [v5.5.64-macos](https://github.com/sudo-yf/mac-qq-exporter/releases/tag/v5.5.64-macos)

下载资产：

- `NapCat-QCE-macOS-arm64-v5.5.64-release.tar.gz`

## 适用范围

- 系统：`macOS`
- 芯片：`Apple Silicon`
- 状态：`experimental`
- 依赖：本机已安装 `QQ.app`

当前不承诺：

- Intel Mac
- Windows / Linux
- 完整上游开发工作流

## 快速开始

1. 从 [Releases](https://github.com/sudo-yf/mac-qq-exporter/releases) 下载压缩包。
2. 解压后，把整个 `NapCat-QCE-macOS-arm64/` 目录放到你希望保存的位置。
   推荐位置：`~/Applications/QQ Chat Exporter/`
3. 首次运行前，在目录中执行：

```bash
xattr -r -d com.apple.quarantine .
chmod +x launcher-user.sh start-standalone.sh
```

4. 双击：

```text
QCE Launcher.app
```

5. 浏览器入口：

- `http://127.0.0.1:40653/qce-v4-tool/`
- `http://127.0.0.1:40653/qce-v4-tool/auth?token=qce_mock_token_for_tests`

## 一键安装

如果你当前就是这个私有仓库的拥有者，或者本机已经 `gh auth login` 过，可以直接执行：

```bash
curl -fsSL -H "Authorization: Bearer $(gh auth token)" \
  -H "Accept: application/vnd.github.raw" \
  https://api.github.com/repos/sudo-yf/mac-qq-exporter/contents/scripts/install.sh | bash
```

安装脚本会：

- 下载仓库当前 `main` 分支内容
- 安装到 `~/Applications/QQ Chat Exporter/NapCat-QCE-macOS-arm64`
- 创建 CLI：`~/.local/bin/qce`
- 创建 App 链接：`~/Applications/QCE Launcher.app`
- 在检测到 `/Applications/QQ.app` 后自动执行 `qce start`

如果后续把仓库改成公开仓库，可以直接简化成：

```bash
curl -fsSL https://raw.githubusercontent.com/sudo-yf/mac-qq-exporter/main/scripts/install.sh | bash
```

执行成功后，目标是**一条命令完成安装并启动**。如果自动启动失败，安装器会明确提示你再手动执行一次：

```bash
~/.local/bin/qce start
```

## CLI

安装后可用命令：

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

## 启动方式

### 1. 双击启动

推荐直接双击：

- `QCE Launcher.app`

这个启动器会：

- 拉起 QCE 运行链
- 等待服务可用
- 自动打开浏览器到 QCE 页面

### 2. 命令行启动

如果你想手动看日志：

```bash
QCE_QUICK_LOGIN_UIN=2645084731 ./launcher-user.sh
```

或者直接：

```bash
qce start
```

### 3. 独立浏览模式

如果你只想浏览已经导出的数据：

```bash
./start-standalone.sh
```

## macOS 运行机制

这个版本不会直接修改系统 `/Applications/QQ.app`。

启动时会：

1. 检测本机 `QQ.app`
2. 复制出一个本地运行副本
3. 将 NapCat + QCE 运行时覆盖进副本
4. 用这个副本启动 QQ 与导出服务

默认本地副本位置：

```text
~/Applications/QQ Chat Exporter/QQ-QCE-runtime.app
```

## 已验证内容

这份仓库对应的版本已经实际验证过：

- quick login 成功
- NapCat 成功收消息
- `qq-chat-exporter` 插件成功加载
- `40653` 成功监听
- `QCE` 页面可访问
- `auth` 页面可访问
- 静态资源、WebSocket、API 可访问

## 已知事项

- 启动时 NapCat 日志里仍可能出现当前 QQ 版本架构兼容提示
- 这不阻塞 QCE 页面和基础 API 启动
- 某些 QQ 版本变更后，可能需要重新生成本地副本

## 仓库内容说明

这个仓库保存的是 **macOS 可运行分发内容**，不是最小源码差异仓库。

因此你会看到：

- `node_modules/`
- `native/`
- `static/`
- `plugins/`
- `QCE Launcher.app/`

这是为了保证从 Git 历史本身就能恢复可运行状态，而不只是一堆不完整源码。

## 备份与恢复

如果本地运行副本损坏，可以删除：

```text
~/Applications/QQ Chat Exporter/QQ-QCE-runtime.app
```

然后重新运行启动器，系统会自动重建。

## 致谢

- [NapCatQQ](https://github.com/NapNeko/NapCatQQ)
- [shuakami/qq-chat-exporter](https://github.com/shuakami/qq-chat-exporter)
