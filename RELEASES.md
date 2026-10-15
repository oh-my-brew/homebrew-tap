# omcli 与 miniTools 的 Homebrew 发行

本文件只描述产品 GitHub Release 成功后的 Tap 更新与三机安装。产品版本、tag、签名和公证由各产品仓库自己的发行文档管理。

## 入口与规则版本

Release subagent 应先取得远程 `oh-my-brew/homebrew-tap` 默认分支 commit，并从同一 commit 读取 `AGENTS.md` 与本文件。整个 Tap 阶段固定使用该规则版本，同时实时读取 workflow、PR 和 Actions 状态。

开始前确认：

- 产品 Release 已成功，tag 指向预期源码 commit；
- 产品资产与 SHA 完整；miniTools 的签名、公证和 Gatekeeper 已通过；
- 没有相同产品和版本的在途 Autobump PR 或发行链；
- Tap 的 `HOMEBREW_BUMP_TOKEN` 和现有工作流没有已知阻塞。

## omcli Formula 与 Bottle

1. 对远程 `oh-my-brew/homebrew-tap` 手动触发 `Autobump releases`，等待 `bump-omcli-<version>` PR；已有相同 PR 时复用，不重复触发。
2. 核对 PR 只修改 `Formula/omcli.rb` 的源码 URL、源码 SHA 和允许的 Bottle 区块。
3. 等待第一轮 `brew test-bot` 成功。macOS 任务产生 Bottle artifact 后，`Publish omcli bottle` 会验证产品 Release、Bottle 元数据、arm64 Tahoe、可迁移性和 SHA。
4. 受信任工作流把 Bottle 上传到 omcli Release，并将 `root_url`、Bottle SHA 和必要的 rebuild 写回原 PR 分支。
5. 写回产生新的 PR head 和新一轮检查。只在最新 head 的 BrewTestBot、CodeQL 和仓库要求的检查全部通过后合并。
6. 合并后核对 Formula 的源码 URL/SHA、Bottle URL/SHA 与产品 Release 资产一致，并记录 Tap merge commit。

Autobump、第一轮 BrewTestBot、Bottle 发布写回和最终 CI 是不同阶段；任何前一阶段的绿色状态都不能替代最终 head 的结果。

## miniTools Cask

1. 对远程 Tap 手动触发 `Autobump releases`，等待 `bump-minitools-<version>` PR；已有相同 PR 时复用。
2. 确认 `Casks/minitools.rb` 的版本和 SHA 对应产品 Release ZIP，且没有夹带无关包修改。
3. 等待最新 PR head 的 BrewTestBot、CodeQL 和仓库要求的检查全部通过后合并。
4. 合并后核对 Cask 版本、SHA、下载 URL 与产品 Release 一致，并记录 Tap merge commit。

miniTools 产品 Release 与 Tap Autobump 是两条独立流水线；Release 成功不会直接修改 Cask。

## M1、M2、M5 定向安装

1. 使用现有 M1 本机会话和 M2/M5 远程入口，运行时解析当前主机与连接方式；仓库不得保存地址、账号或凭据。
2. 每台设备先记录目标包当前版本。miniTools 还要记录升级前是否正在运行。
3. 更新 Tap 元数据后，只升级目标包：

   ```sh
   brew upgrade oh-my-brew/tap/omcli
   brew upgrade --cask oh-my-brew/tap/minitools
   ```

   Homebrew 判断已是目标版本时，不用重装代替判断。只有确认安装损坏或同版本资产确实被替换时才定向 `brew reinstall`。
4. omcli 只验证 `omcli --version`、Formula 版本与来源、Bottle 架构、安装文件及 helper 可执行性；不得调用有副作用的子命令。
5. miniTools 只验证 Cask 版本、应用展示版本与 build、arm64 架构、Bundle ID、Developer ID 签名、公证 ticket 和 Gatekeeper。只在升级前已运行的设备上重新启动正式 `/Applications/miniTools.app`。
6. 确认三台设备达到目标版本，Tap 指向同一 merge commit；确认产品发行 worktree 已清理且没有影响开发仓库。

安装阶段不得运行宽泛 `brew upgrade`、`brew cleanup`、`brew autoremove`，不得触发本地 `homebrew/core` clone，也不得测试产品真实功能。

## 失败处理

- 产品资产不完整或签名失败：停止 Tap 阶段，回产品发行链处理。
- Autobump 没有创建 PR：检查 workflow 结果和 token，不手工伪造成功状态。
- Bottle 写回失败：保留 PR 与运行证据，修复 Tap 工作流后重新使用受信任流程；不在本地手工上传未验证 Bottle。
- CI 失败：按失败所属仓库处理；发行期间不顺便重构无关代码。
- 某台设备不可达或需要人工系统权限：其他已完成状态如实保留，报告该设备未完成，不把三机整体写成成功。

## 最终交付

报告产品版本、tag、源码 commit、产品 Release 与资产 SHA、Tap PR 和 merge commit、最新 CI、三台设备版本、Bottle 或签名证据、未做的功能测试，以及尚未完成或需要用户处理的事项。
