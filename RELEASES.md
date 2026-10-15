# omcli 与 miniTools 的 Homebrew 更新

产品仓库完成 GitHub Release 后即结束产品发行。Tap 每天北京时间 11:17 运行
`Autobump releases`，独立检查稳定 Release，并为 omcli、miniTools 及其他受管包创建
版本更新 PR。产品 Release 不手动触发这条工作流，也不等待 Tap 或设备安装。

## 定时发现与 PR

1. Autobump 只创建版本更新 PR，不自动合并。
2. 已有相同包和版本的 PR 时复用，不重复创建。
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
