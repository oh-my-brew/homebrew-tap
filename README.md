# homebrew-omzcj

个人使用的 Homebrew Tap，收录常用命令行工具、macOS 工具和应用。

## 安装

直接安装单个 Formula 或 Cask：

```sh
brew install omzcj/omzcj/<formula>
brew install --cask omzcj/omzcj/<cask>
```

也可以先添加 Tap：

```sh
brew tap omzcj/omzcj
brew install <formula>
```

## Formulae

| 名称 | 用途 | 备注 |
| --- | --- | --- |
| `codex-remote` | 手动让 ChatGPT Desktop 复用 Codex managed app-server | macOS、手动运行 |
| `dotfiles` | 使用 ncdu 记录磁盘占用快照 | 依赖 `ncdu` |
| `ds_store` | 查找、清理并监控 `.DS_Store` 文件 | 支持 Homebrew Services |
| `iproxy-ssh` | 通过 USB 将本地 2222 端口转发到设备 SSH 端口 | 支持 Homebrew Services |
| `lockscreen` | 从命令行锁定当前 macOS 会话 | macOS |
| `scaletail` | 以 `scaletail`/`scaletaild` 命令名安装 Tailscale | 基于官方 Tailscale 源码 |

启动或停止服务：

```sh
brew services start ds_store
brew services stop ds_store

brew services start iproxy-ssh
brew services stop iproxy-ssh
```

`codex-remote` 不使用 Homebrew Services 或 LaunchAgent。安装后需要时手动运行：

```sh
codex-remote
codex-remote status
```

## Casks

| 名称 | 用途 | 备注 |
| --- | --- | --- |
| `minitools` | 剪贴板转换、Safari 窗口切换和窗口管理 | macOS 26+、ad-hoc 签名 |

## 维护与验证

提交改动前运行：

```sh
brew style Formula Casks
brew audit --strict --online --tap=omzcj/omzcj
brew test <formula>
```

`dotfiles`、`ds_store` 和 `lockscreen` 由各自仓库的
`VERSION` 文件控制版本。修改发布内容时同步更新 `VERSION`，推送到默认分支后，
GitHub Actions 会先验证构建，再自动创建 tag、Release、发布资源和 SHA-256 文件。

Tap 每天检查一次这些 Release，并通过 Homebrew `bump-packages` 自动创建更新 PR。
启用前需要在仓库 Actions secrets 中添加 `HOMEBREW_BUMP_TOKEN`；它应是仅授权本仓库、
能推送分支并创建 Pull Request 的 fine-grained PAT。未配置时工作流会安全跳过，不会产生
失败通知。

`scaletail` 直接跟随 Tailscale 官方稳定 tag，通过同一 Autobump 工作流更新，不需要
单独维护源码仓库。Formula 仅把安装的 CLI、daemon、服务和补全文件改为 `scaletail`
命名；内部版本信息、协议和网络行为仍属于 Tailscale。

`minitools` 从 `omzcj/miniTools` 的版本标签构建通用 macOS 应用，并以 ad-hoc 签名发布。
发行版本使用 `YYYY.MM.DD.N`，其中 `N` 是从 `1` 开始的当日发布序号；应用内显示前三段
日期版本，GitHub Release 和 Cask 使用完整版本。
首次运行可能需要在“系统设置 → 隐私与安全性”中选择“仍要打开”，之后还需授予辅助功能
权限。它同样由 Autobump 检查 GitHub Release 并创建 Cask 更新 PR。

Pull Request 会通过 GitHub Actions 在 Intel macOS、Apple Silicon macOS 和 Linux 上运行 BrewTestBot。
