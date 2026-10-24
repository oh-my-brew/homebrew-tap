# 自有产品的 Homebrew 自动更新

产品仓库完成 GitHub Release 后即结束产品发行。Tap 每天北京时间 11:17 运行
`Autobump releases`，独立检查稳定 Release，并为 omcli、miniTools 及其他受管包创建
版本更新 PR。产品 Release 不手动触发这条工作流，也不等待 Tap 或设备安装。

产品发布代理的单实例、重试、回执、通知和关闭协议留在各产品发行文档；
Tap 不承接每次 Release 的即时代理链。独立 Tap 维护任务如使用代理，复用同一任务代理完成
检查/合并/明确要求的安装，交接后按实际工具收尾；归档不等于资源释放。

## 定时发现与 PR

1. omcli、miniTools、RustDeskX 的受信任纯版本 PR 自动合并；scaletail 与其他改动仍人工审核。
2. 已有相同包和版本的 PR 时复用；受信任纯版本旧 PR 被较新的稳定 Release 取代时关闭并保留来源链接，再由 Homebrew 工具创建新 PR。未知作者、来源或混合改动使自动取代停止，不强推旧分支。
3. 每个 PR 只包含该包的版本、URL、SHA 和受信任 Bottle 写回；夹带无关修改时不合并。
4. 所有判断以最新 PR head 的必需检查为准。

## omcli Formula 与 Bottle

omcli 第一轮 BrewTestBot 通过后，受信任的 `Publish omcli bottle` 工作流验证产品
Release、Bottle 元数据、arm64 Tahoe、可迁移性和 SHA，将 Bottle 上传到产品 Release，
并把 Bottle 区块写回原 PR。写回会产生新 head；必须等待新一轮最终检查通过后才能合并。

Autobump、第一轮 BrewTestBot、Bottle 写回和最终 CI 是不同阶段，前一阶段的绿色结果
不能代替最终 head。不得本地手工上传或伪造 Bottle。

## miniTools Cask

miniTools PR 必须确认版本和 SHA 对应已经签名、公证且包含签名 appcast 的产品 Release。
Cask 使用 `auto_updates true`，因为应用可由 Sparkle 自行下载和安装更新。等待最新 PR head
的 BrewTestBot、CodeQL 和仓库必需检查通过后，才可单独决定合并。

## 安装与升级

Tap 合并不自动升级 M1、M2、M5。设备日常优先使用产品自更新：miniTools 状态菜单的
“检查更新…”和 `omcli update`。Homebrew 仍用于首次安装、恢复和定期基线收敛。

只有任务明确要求 Homebrew 安装或迁移时，才对指定设备运行：

```sh
brew upgrade oh-my-brew/tap/omcli
brew upgrade --cask oh-my-brew/tap/minitools
```

安装验证只读取版本、来源、架构、签名、公证及文件布局，不运行产品真实功能。不得运行
宽泛 `brew upgrade`、`brew cleanup`、`brew autoremove`，也不得触发本地
`homebrew/core` clone。

## 失败处理

- 产品资产、签名或 appcast 不完整：保留 Tap PR，回产品仓库修复。
- Autobump 未创建 PR：检查定时 workflow 和 token，不手工伪造成功状态。
- Bottle 写回失败：修复受信任工作流并复用原 PR。
- CI 失败：只修复对应包和失败链路，不顺带升级无关包。
- 设备不可达或需要人工系统权限：如实记录，不把部分安装表述为全部完成。

## 发布就绪与自动合并（2026-10-25）

用户已授权三个自有产品的纯版本自动更新与合并，不扩展到设备升级或产品发行。
`release-ready.yml` 只从受信任 base commit 读取脚本，通过 GitHub API 获取 PR 内容，
不 checkout 或执行 PR 的 Ruby、脚本和 workflow。作者固定为当前 bump token 身份
`assassinor`，只接受本仓库 `bump-<package>-<version>` 分支、main 目标和单包修改。
更换 token 身份须显式更新策略并评审。

- 仅允许版本、URL、SHA；omcli 另允许经验证的 Bottle 块。其他改动只供人工审核，不启用自动合并。
- 最新正式 Release 必须与 PR 版本一致，资产必须上传完成且 SHA-256 匹配。
- omcli 必须有当前版本的 arm64 Tahoe 可迁移 Bottle，并与产品 Release 的资产摘要一致；第一轮缺少 Bottle 时门禁失败，Bottle 写回触发新 head 的门禁和完整 CI。
- 两个 Cask 实际下载 ZIP，验证归档摘要、校验文件、Bundle ID、Developer ID、固定 Team ID、arm64、Gatekeeper 与 stapled 公证票据；miniTools 同时验证 helper 身份及固定公钥的 Sparkle Ed25519 归档签名。
- `tap-release-ready` 状态明确写到正在验证的 PR head SHA；pull_request_target 自身运行的 base SHA 不作为就绪依据。合并前再次检查 head、改动范围与最新 Release。
- 仓库开启原生 auto-merge，以 squash 维持线性历史；保留严格最新分支检查、BrewTestBot，并增加发布就绪、自动化测试及 CodeQL 必需检查。没有 admin 绕过。
- 多个包同时更新时，前一个合并会使后一个落后 main；main 推送会触发受信任协调流程，通过 GitHub 的普通分支更新接口同步受信任 PR，重新等待新 head 检查，不 force push。

每日发现流程继续与产品 Release 解耦。`HOMEBREW_BUMP_TOKEN` 缺失、旧 PR 无法安全取代、
或没有代表最新稳定版的 PR 时，Autobump 失败并输出各包状态，不再静默成功。
失败由 Actions 保留记录，不新增飞书通知或设备操作。

维护验证：`python3 -m unittest discover -s tests -v`、`actionlint .github/workflows/*.yml`。
