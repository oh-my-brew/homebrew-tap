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
| `omcli` | 锁屏、记录磁盘占用快照并提供 active writer 应急恢复 | Apple Silicon、macOS、依赖 `ncdu` |
| `scaletail` | 以 `scaletail`/`scaletaild` 命令名安装 Tailscale | 基于官方 Tailscale 源码 |

安装统一命令行工具：

```sh
brew install oh-my-brew/tap/omcli
```

`omcli` 合并了原来的 `lockscreen` 和 `dotfiles`，并保留 `codex` 作为 active writer
应急恢复命令。`lockscreen` 支持自动选择经锁定状态确认的实现，也可以显式指定
`direct`、`agent`、`display-sleep` 或 `hotkey`；`status` 和 `doctor` 只读取状态。
以下功能命令会直接影响当前电脑，不应作为安装验证或自动化测试运行：
`omcli lockscreen` 会立即锁定当前 macOS 会话，`omcli ncdu dump [DIRECTORY]` 会扫描目录并
写入磁盘占用快照，`omcli ncdu prune` 会删除每个扫描目标超出保留数量的旧快照，
`omcli codex recover` 会终止正在持有 Codex thread-writer lock 的进程。

需要使用时手动运行对应入口：

```sh
omcli lockscreen
omcli lockscreen status
omcli lockscreen doctor
omcli ncdu dump
omcli ncdu read
omcli ncdu list
omcli ncdu prune --dry-run
omcli codex recover
```

## Casks

| 名称 | 用途 | 备注 |
| --- | --- | --- |
| `minitools` | 编码转换、Safari 窗口切换和窗口管理 | macOS 26+、Developer ID 签名并公证 |
| `rustdeskx` | RustDesk 的 Apple Silicon 重品牌发行包 | macOS 12+、Developer ID 签名并公证 |

## 维护与验证

提交改动前运行：

```sh
brew style Formula Casks
brew audit --strict --online --tap=oh-my-brew/tap
brew test <formula>
```

Tap只消费产品的稳定Release，不编排产品Beta或正式提升。产品流程分别见
[omcli发行说明](https://github.com/oh-my-brew/omcli/blob/main/RELEASING.md)、
[miniTools发行说明](https://github.com/oh-my-brew/miniTools/blob/master/DISTRIBUTION.md)与
[RustDeskX发行说明](https://github.com/oh-my-brew/rustdeskx/blob/main/DISTRIBUTION.md)。

`omcli` 使用 `YYYY.MM.DD.N` 版本号，其中 `N` 是从 `1` 开始的当日发布序号。它的 Homebrew
测试只检查顶层版本、帮助和安装文件，不运行上述会影响电脑的功能命令。

Tap 每天检查一次这些 Release，并通过 Homebrew `bump-packages` 自动创建更新 PR。
启用前需要在仓库 Actions secrets 中添加 `HOMEBREW_BUMP_TOKEN`；它应是仅授权本仓库、
能推送分支并创建 Pull Request 的 fine-grained PAT。组织迁移后应核对该 PAT 的
resource owner 为 `oh-my-brew`，选定仓库为 `homebrew-tap`；仅凭 secret 名称存在
不能确认新组织下的访问权限。未配置时工作流会明确失败，避免把没有更新的软件包标为同步成功。

`scaletail` 直接跟随 Tailscale 官方稳定 tag，通过同一 Autobump 工作流更新，不需要
单独维护源码仓库。Formula 仅把安装的 CLI、daemon、服务和补全文件改为 `scaletail`
命名；内部版本信息、协议和网络行为仍属于 Tailscale。

`minitools` 下载产品仓库已构建的 Apple Silicon 正式ZIP，包含 Developer ID、Hardened Runtime、Apple 公证和 stapled ticket。
发行版本使用 `YYYY.MM.DD.N`，其中 `N` 是从 `1` 开始的当日发布序号；应用内、GitHub
Release 和 Cask 均显示完整版本。应用提供签名的 Sparkle 手动更新，因此 Cask 标记为
`auto_updates true`。
相关窗口功能需要辅助功能权限，鼠标侧键还需要输入监控权限。它同样由 Autobump 检查 GitHub Release 并创建 Cask 更新 PR。

Pull Request 会通过 GitHub Actions 在 macOS 26 和 Linux 上运行 BrewTestBot。产品 Release
与 Tap 解耦；定时发现、Bottle、合并和按需安装规则见 `RELEASES.md`。

三个自有产品的纯版本更新可自动取代旧 PR、验证发布资产并按必需检查自动合并；scaletail 和非版本改动仍人工审核。具体范围、身份与门禁见 [RELEASES.md](RELEASES.md)。
