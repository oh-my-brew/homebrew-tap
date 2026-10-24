# Homebrew Tap 工程约定

本仓库是 `oh-my-brew/tap` 的 Formula、Cask 与 GitHub Actions 权威来源。任何影响本仓库、远程 Tap PR 或安装的 agent 都必须遵守本文件；现有产品更新另读同一 commit 的 `RELEASES.md`。

## 通用边界

- 开始前读取实时远程状态，保留用户与其他会话的修改；不要 reset、clean、stash、强推、覆盖 tag、删除历史或擅自切换正在使用的分支。
- 正常产品发行通过 Autobump、BrewTestBot 和受信任工作流完成，不手工编辑本地 Tap checkout 模拟自动化结果。
- 不修改无关 Formula/Cask，不升级无关软件，不运行 `brew autoremove`、宽泛 `brew cleanup` 或全量 `brew upgrade`。
- 禁止克隆或拉取完整 `homebrew/core`：不得执行 `brew tap homebrew/core`、不得设置 `HOMEBREW_NO_INSTALL_FROM_API=1`，也不得采用其他触发 core 仓库克隆的方式。流程要求本地 core tap 时立即停止并报告。
- 测试只验证包、安装布局和无副作用接口；不得调用 omcli 或 miniTools 的真实功能。
- 发布代理复用、结果回传和关闭由产品仓库 AGENTS 及发行文档管理；Tap 不接收每次产品发版的即时代理派发，也不承担唤醒开发主会话。Tap 自身任务交付后同样应回传结果并按可用工具收尾，不为查询 CI 另开代理。
- 产品 Release 与 Tap 维护相互独立。定时 Autobump 对三个自有产品的纯版本更新创建/取代 PR，并在发布就绪和必需检查通过后自动合并；scaletail 与非版本改动仍人工审核；安装也不是每次产品发行的完成条件。

## 现有产品更新

- 处理 omcli 或 miniTools 的 Tap 更新时，必须读取与本文件相同 commit 的 `RELEASES.md`。
- 固定一次维护使用的规则 commit，同时实时核对 workflow、PR、检查和 Release；文档不替代当前 GitHub 状态。
- Autobump 创建 PR 不等于可以合并。只接受最新 PR head 的必需检查；omcli Bottle 写回后必须等待新一轮最终检查。
- 正常发行不得通过手工改版本/SHA、直接上传未验证资产或跳过失败检查来绕过 Actions。

## 新建 Formula 或 Cask

- 必须有用户明确要求；不能因发现一个项目而自动加入 Tap。
- 确认包名、上游仓库、许可证、版本来源、支持架构和最低系统版本。优先使用正式 Release 资产，不引用默认分支快照。
- Formula 定义最小依赖、准确安装内容、无副作用的 `test do` 和 `livecheck`。Cask 定义准确 artifact、安装目标、卸载行为、必要的 `zap`、权限说明和 `livecheck`。
- 明确是否加入 Autobump，并同步 README 与相关工作流。测试不能调用产品真实功能，也不能以拉取本地 core tap 作为前提。

## 修改 Formula 或 Cask

- 常规版本、URL 和 SHA 更新优先交给 Autobump；手工修改用于安装逻辑、依赖、Bottle/Cask 行为、工作流修复或自动化无法表达的变化。
- 每个 PR 尽量只修改一个包；受信任 Bottle 工作流对同一 PR 的自动写回除外。
- 修改安装内容时同步无副作用测试。omcli 必须覆盖 Release 的全部 `bin/*`；miniTools 必须保持 `/Applications` 安装位置、Bundle ID、Team ID、Developer ID 身份和 helper label。
- 必须依据最新 PR head 的 CI，不使用旧 commit 的绿色结果。

## 删除 Formula 或 Cask

- 必须有用户明确授权。删除前检查三机安装、chezmoi/Brewfile 声明、运行中的 service、其他包依赖、README、Autobump、workflow 和测试引用。
- 根据实际情况决定先 deprecated/disabled、提供迁移说明或直接移除，不能只删除单个 Ruby 文件留下入口。
- 删除 Tap 定义不代表获准卸载三台设备、清理配置、删除上游 Release 或归档源码仓库；这些都是独立操作范围。

## 完成标准

- 报告产品版本与 Release、Tap PR 和 merge commit、最新 CI、Bottle 或签名证据，以及本次明确要求的安装结果。
- 工作流仍在运行时不得把 Tap 更新描述为完成；明确标注非阻塞检查与真正阻塞项。
