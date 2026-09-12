# homebrew-tap

个人使用的 Homebrew Tap，收录常用命令行工具、macOS 工具和应用。

仓库为 `oh-my-brew/homebrew-tap`，Tap 名为 `oh-my-brew/tap`。共享源码发布
自动化由 `oh-my-infra/brew-ci` 维护，Apple 发布自动化由
`oh-my-infra/apple-ci` 维护。仓库改名不改变已有包名、版本或应用 Bundle ID。

## 安装

直接安装单个 Formula 或 Cask：

```sh
brew install oh-my-brew/tap/<formula>
brew install --cask oh-my-brew/tap/<cask>
```

也可以先添加 Tap：

```sh
brew tap oh-my-brew/tap
brew install <formula>
```

## Formulae

| 名称 | 用途 | 备注 |
| --- | --- | --- |
| `ds_store` | 查找、清理并监控 `.DS_Store` 文件 | 支持 Homebrew Services |
| `iproxy-ssh` | 通过 USB 将本地 2222 端口转发到设备 SSH 端口 | 支持 Homebrew Services |
| `omcli` | 锁屏、记录磁盘占用快照并管理 Codex remote control | Apple Silicon、macOS、依赖 `ncdu` |
| `scaletail` | 以 `scaletail`/`scaletaild` 命令名安装 Tailscale | 基于官方 Tailscale 源码 |

启动或停止服务：

```sh
brew services start ds_store
brew services stop ds_store

brew services start iproxy-ssh
brew services stop iproxy-ssh
```

安装统一命令行工具：

```sh
brew install oh-my-brew/tap/omcli
```

`omcli` 合并了原来的 `lockscreen`、`dotfiles` 和 `codex-remote`。以下功能命令会直接影响
当前电脑，不应作为安装验证或自动化测试运行：`omcli lockscreen` 会立即锁定当前 macOS
会话，`omcli ncdu` 会扫描根目录并写入磁盘占用快照，`omcli codex start/stop/restart/update`
会改变 ChatGPT Desktop、Codex app-server 或 standalone Codex 的运行和安装状态。

需要使用时手动运行对应入口：

```sh
omcli lockscreen
omcli ncdu
omcli codex status
omcli codex start
omcli codex stop
omcli codex restart
omcli codex update check
```

`omcli codex` 不使用 Homebrew Services 或常驻 LaunchAgent。无参数运行 `omcli codex` 等价于
只读的 `status`；`start` 禁用 ChatGPT 自动更新、智能修复并启动，`stop` 完全关闭，
`restart` 强制重建连接。

## Casks

| 名称 | 用途 | 备注 |
| --- | --- | --- |
| `minitools` | 剪贴板转换、Safari 窗口切换和窗口管理 | macOS 26+、ad-hoc 签名 |

## 维护与验证

提交改动前运行：

```sh
brew style Formula Casks
brew audit --strict --online --tap=oh-my-brew/tap
brew test <formula>
```

`omcli` 和 `ds_store` 由各自仓库的
`VERSION` 文件控制版本。修改发布内容时同步更新 `VERSION`，推送到默认分支后，
GitHub Actions 会先验证构建，再自动创建 tag、Release、发布资源和 SHA-256 文件。

`omcli` 使用 `YYYY.MM.DD.N` 版本号，其中 `N` 是从 `1` 开始的当日发布序号。它的 Homebrew
测试只检查顶层版本、帮助和安装文件，不运行上述会影响电脑的功能命令。

Tap 每天检查一次这些 Release，并通过 Homebrew `bump-packages` 自动创建更新 PR。
启用前需要在仓库 Actions secrets 中添加 `HOMEBREW_BUMP_TOKEN`；它应是仅授权本仓库、
能推送分支并创建 Pull Request 的 fine-grained PAT。组织迁移后应核对该 PAT 的
resource owner 为 `oh-my-brew`，选定仓库为 `homebrew-tap`；仅凭 secret 名称存在
不能确认新组织下的访问权限。未配置时工作流会安全跳过，不会产生失败通知。

`scaletail` 直接跟随 Tailscale 官方稳定 tag，通过同一 Autobump 工作流更新，不需要
单独维护源码仓库。Formula 仅把安装的 CLI、daemon、服务和补全文件改为 `scaletail`
命名；内部版本信息、协议和网络行为仍属于 Tailscale。

`minitools` 从 `oh-my-brew/miniTools` 的版本标签构建通用 macOS 应用，并以 ad-hoc 签名发布。
发行版本使用 `YYYY.MM.DD.N`，其中 `N` 是从 `1` 开始的当日发布序号；应用内显示前三段
日期版本，GitHub Release 和 Cask 使用完整版本。
首次运行可能需要在“系统设置 → 隐私与安全性”中选择“仍要打开”，之后还需授予辅助功能
权限。它同样由 Autobump 检查 GitHub Release 并创建 Cask 更新 PR。

Pull Request 会通过 GitHub Actions 在 Intel macOS、Apple Silicon macOS 和 Linux 上运行 BrewTestBot。
