# MoodLite 完全离线轻量版发布验收清单

**当前结论（2026-09-20）：首发包已完整移除定时通知、代理提醒权限及相关状态；核心记录闭环和 2×2 桌面卡片已在独立 Release QA 模拟器回归，正式签名 APP/HAP 已重建并校验。当前无已知代码、构建或签名阻塞，可提交 AppGallery 审核；由于没有真机，不声称已完成真机飞行模式验收，也不保证商店审核结果。**

## 最新首发候选包：2026-09-20

- 范围：保留首次启动、五档情绪、文字与标签、时间线/详情/编辑/删除、月度统计、主题/深色模式和 2×2 桌面卡片。AI、账号、定时通知、图片与位置等非首发能力不进包。
- 定时通知删减：已删除设置入口、时间选择器、`ReminderManager`、提醒状态模型与四项持久化键、图标、单测及 `ohos.permission.PUBLISH_AGENT_REMINDER`。隐私页同步删除“提醒配置”表述；代理提醒能力申请和 Profile 更换不再是上架前置条件。
- 权限：构建后清单与模拟器 `bm dump` 均确认仅剩 `ohos.permission.VIBRATE`，供记录滑块与保存触觉反馈使用；无网络、媒体读取或提醒权限。
- 门禁：离线脚本先在旧代码上报出 4 处提醒残留，删减后通过（29 个运行时文件）；轻量化门禁与 `git diff --check` 通过。
- 自动化：ArkTS 13/13（5 套件），`Failure: 0, Error: 0`；Node 9/9（设备冒烟入口 7 项 + 卡片边界 2 项）；Release `assembleApp` 42 tasks，`BUILD SUCCESSFUL`。卡片用例覆盖系统 ID 注册以及已有当日记录的实际摘要。
- 模拟器：正式 HAP 覆盖安装成功。设置页仅显示深色模式、数据与隐私、关于、主题风格；无提醒入口。隐私页显示“情绪记录、标签与主题配置仅保存在你的设备中”。
- 桌面卡片：修复系统 `form_identity` 参数读取（GitHub `bad9437ce1630bd62062f21eb1b8c852adc6c0a8`）。Release QA 实测可添加，强制结束后点击可冷启动，编辑后从“愉悦 / 连续 1 天”立即更新为“低落 / 连续 1 天”，删除测试记录后恢复空状态。测试记录已清理，原模拟器与数据未动。
- APP：`build/outputs/default/MoodLite-default-signed.app`，9,660,438 bytes，SHA-256 `1686ba8f4a746ac4b86ee8b58e75665417804fa517642a9e188352a6e6d51715`。
- HAP：`entry/build/default/outputs/default/entry-default-signed.hap`，9,948,121 bytes，SHA-256 `a3bac243496916bd0c9b214c27e097d115c1903f1dfe764ce3653374ea039d5d`。
- 两个产物均通过 SDK `verify-app`；继续使用原有正式签名。密钥、证书、Profile、密码与本机 `build-profile.json5` 未改动、未打印、未提交。
- 独立审查：卡片修复和提醒删减均无 Critical / Important / Minor 问题，可合入。
- 剩余风险：因无真机，未完成真实设备飞行模式、厂商实机桌面卡片与应用商店安装后验收。这是设备覆盖风险，不再是提醒能力或签名阻塞。当前包可用于提交审核，若上架后取得真机，建议立即补一轮安装/升级/飞行模式验收。

> 以下 2026-09-19 及更早章节仅作历史证据；其中提醒能力申请、提醒真机验收和旧产物哈希已被本节的首发范围与候选包取代。

## 历史验收：2026-09-19 上午

- 运行时代码：`7161fb0886667eaee9671b93e3ce89c577710b97`，`main`，版本 `1.0.0` / `1000000`，目标与最低 SDK 仍为 API 21。
- 签名：复用用户现有正式发布签名；未更改、重新生成或提交密钥、证书、Profile、密码及本机 `build-profile.json5`。本机配置前后 SHA-256 一致；仓库版本仍不含签名材料。
- 产物：`build/outputs/default/MoodLite-default-signed.app`，9,669,369 bytes，SHA-256 `7d950ac4228387f3c2966a162f512b09ce8d533c5d2c7e074a1b39d5ac039487`。
- 产物：`entry/build/default/outputs/default/entry-default-signed.hap`，9,969,134 bytes，SHA-256 `ef3dadacd53f5d62936dcd6b5822b577a97810b1937fe3091b6a8cd83a9df214`。
- APP 与 HAP 均通过 SDK `hap-sign-tool verify-app`；HAP 的 `profile type` 为 `release`，叶证书 SHA-256 为 `2F:42:C3:14:63:58:A6:5E:49:EA:A1:D7:43:AC:20:4B:70:3D:00:B9:8C:4C:0A:A6:30:B2:B0:B8:01:24:A0:D7`。
- API 21 `test`：15/15，通过 6 个套件，`Failure: 0, Error: 0`；Release `assembleApp`：42 tasks，`BUILD SUCCESSFUL`。
- 离线门禁、轻量门禁、`git diff --check` 通过；发布卫生门禁在 `git archive HEAD` 的干净快照中通过。本机私有签名配置不进入检查快照或 Git。
- 冒烟入口 Node 测试 7/7 通过。这是入口逻辑测试，不是 7 项设备验收。

### 本轮已修复

1. 编辑保存后刷新主页面；刷新失败保留返回时重试，并按处理器身份注销，避免旧页面误清理新页面。
2. 模拟器再次复现：数据库已更新，但相同日期/ID 的 `ForEach` 仍复用旧内容。日分组键现包含记录内容，编辑后立即显示新情绪和标签；日期和同日记录改为最新优先。
3. 保存期间离开页面后，旧异步回调不再显示动画或执行返回导航；编辑路由失败只清理本次桥接数据。
4. 旧数据数组含 `null`、数字等坏项时，跳过单个坏项并保留合法记录；新增混合坏数据回归。
5. 提醒通知点击配置正确的应用目标；关闭按钮显示“关闭”；发布前请求系统通知授权。
6. 取消时间选择或系统发布失败后，提醒开关外观恢复实际状态，避免显示假开启。

### Release 包模拟器回归

使用独立 `MoodLite Release QA` 模拟器（`127.0.0.1:5557`，HarmonyOS API 23）首次安装并覆盖安装正式签名 HAP，安装成功。原 `Pura 90` 模拟器及其旧记录保留。这里仍不是断网或真机验收。

| 项目 | 结果与范围 |
| --- | --- |
| 首次启动 | 欢迎页可进入主界面，无账号入口 |
| 新增与详情 | 测试记录 `release-qa-20260919` 可保存并查看 |
| 编辑即时刷新 | 从愉悦/休息变为低落/休息·工作，保存后立即显示；仍为 9月19日 11:18，无需重启 |
| 取消编辑 | 改动后返回，情绪、标签及原日期时间不变 |
| 重启持久化 | 强制结束再启动，已保存的记录保持不变 |
| 统计与删除 | 删除本轮创建的测试记录后时间线为空，记录天数归零，情绪占比归零 |
| 本地信息页 | 隐私与关于页可打开；深色模式下返回箭头截图确认完整、清晰 |
| 深色模式 | 开启后强制结束再启动，设置保留 |
| 提醒取消/失败 | 取消选择后开关关闭；授权通知后发布失败也保持关闭，重启仍关闭 |
| 提醒实际发布 | **失败**：`1700002`；系统日志为 `VerifyCloudCapability failed ... reminder_capability`、`The number of reminders exceeds the limit[0]` |
| 提醒触发/关闭/卡片/飞行模式 | 尚未取得完整正向证据，不能标记通过 |

### 目前需要外部处理的事项

1. 在 AppGallery Connect 为该应用申请并开启“代理提醒”开放能力，审批完成后重新生成包含能力的 Profile，继续使用原私钥及证书。当前系统校验未通过；不是把重复提醒清空就能解决的问题。用户要求签名材料不变，因此本轮未替换 Profile 或修改签名目录。
2. 官方说明要求开放能力申请、通知授权及 Profile 配置，并明确 API 20 起支持模拟器。来源：[华为代理提醒开发指南](https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/agent-powered-reminder)（2026-09-19 核验）。本轮已补通知授权，授予后仍复现能力校验失败。
3. 完成真实 HarmonyOS 设备飞行模式、提醒实际触发/点击/取消、2×2 卡片冷启动与更新验收；没有真机，不能把模拟器结果写成真机通过。
4. 当前候选包保持既有未混淆配置；编译器有相应 warning。该构建决定不代表对商店审核的保证。若改变混淆或 Profile，必须重建并重新验收最终包。

以下为此前历史证据；与本节冲突时，以本节日期与产物为准。

## 历史验收基线（2026-09-11）

- 验收日期：2026-09-11（Asia/Shanghai）
- 分支：`main`
- 运行时代码提交：`4be558ac52df70f9d41bf734582f09d1ea0b416a`
- 应用版本：`1.0.0`（`versionCode: 1000000`）
- SDK：HarmonyOS `6.0.1(21)`，`targetSdkVersion` 与 `compatibleSdkVersion` 均为 API 21
- 当前设备连接：无；`hdc list targets` 返回 `[Empty]`
- 当前构建产物：`entry/build/default/outputs/default/entry-default-unsigned.hap`，9,917,730 bytes
- 设备测试产物：`entry/build/default/outputs/ohosTest/entry-ohosTest-unsigned.hap`，10,766,138 bytes
- 签名说明：仓库不再保存本机签名材料；当前产物为未签名 HAP，需在受控发布环境注入生产签名后再做安装和上架验收。
- 历史签名核查：旧配置引用的 Provision Profile 仍可由 SDK 工具校验，但类型为 Debug，不是 Release，不能作为生产签名或上架证据。

## 自动化验收结果

- [x] `node scripts/verify-offline.mjs`：通过，扫描 31 个运行时源码/清单文件。
- [x] `node scripts/verify-lightweight-scope.mjs`：通过。
- [x] `node scripts/verify-release-hygiene.mjs`：先检出旧窗口、路由、振动、卡片入口和签名配置问题；修复后通过。
- [x] ArkTS 单元测试：`BUILD SUCCESSFUL`，20 个构建任务完成；仅注册 5 个真实测试套件。
- [x] API 21 Debug HAP：`BUILD SUCCESSFUL`，33 个构建任务完成。
- [x] API 21 Release HAP：`BUILD SUCCESSFUL`，33 个构建任务完成。
- [x] API 21 `ohosTest` HAP：`BUILD SUCCESSFUL`，35 个构建任务全部执行；设备侧路由安全用例已编译打包，尚未在真机运行。
- [x] 真机冒烟入口测试：`node --test scripts/run-device-smoke.test.mjs` 通过 7/7；覆盖未签名包、无设备、多设备、飞行模式确认、SDK 根目录解析、成功报告与失败报告分支。
- [x] 模板断言审计：`assertContain`、`let a = 'abc'` 无命中。
- [x] 可执行源码远程残留审计：网络 API、远程 URL、AI 配置、登录/会员符号无命中。SVG 的 W3C XML 命名空间不是网络依赖，审计已限定为 `.ets/.ts/.js/.mjs/.json/.json5`。
- [x] 权限清单：仅 `ohos.permission.PUBLISH_AGENT_REMINDER` 与 `ohos.permission.VIBRATE`。
- [x] Git 范围：无已跟踪 `.DS_Store` 或 `AGENTS.md`；用户原有未跟踪文件未纳入提交。

Release 构建仍会提示“未配置 signingConfig”和“未启用混淆”。前者是避免把本机密钥材料提交到仓库后的预期结果；后者不影响编译，但是否启用必须结合生产签名包做真机回归后决定。

## 规格逐条覆盖

| 规格 | 正向证据 | 状态 |
| --- | --- | --- |
| §2.1–2.4 无账号、无网络、无无关权限、本地信息页 | [`verify-offline.mjs`](../../scripts/verify-offline.mjs)、[`module.json5`](../../entry/src/main/module.json5)、[`DataPrivacyPage.ets`](../../entry/src/main/ets/pages/DataPrivacyPage.ets)、[`AboutPage.ets`](../../entry/src/main/ets/pages/AboutPage.ets) | 已通过静态/构建验证 |
| §2.5 飞行模式完整闭环 | 下方真机清单 | 待真机 |
| §2.6 编辑日期不变、失败不伪成功 | [`MoodRecordPolicy.test.ets`](../../entry/src/test/MoodRecordPolicy.test.ets)、[`DataManager.ets`](../../entry/src/main/ets/data/DataManager.ets)、[`EntryDetail.ets`](../../entry/src/main/ets/pages/EntryDetail.ets) | 纯逻辑与源码通过；交互待真机 |
| §2.7 当月隔离与日期去重 | [`StatsViewModel.test.ets`](../../entry/src/test/StatsViewModel.test.ets)、[`WidgetViewModel.test.ets`](../../entry/src/test/WidgetViewModel.test.ets) | 已通过单测 |
| §2.8 初始化优先与路由白名单 | [`LaunchIntent.test.ets`](../../entry/src/test/LaunchIntent.test.ets)、[`EntryAbility.ets`](../../entry/src/main/ets/entryability/EntryAbility.ets)、[`Index.ets`](../../entry/src/main/ets/pages/Index.ets) | 已通过单测/构建；卡片冷启动待真机 |
| §2.9 可重复离线与核心测试 | 3 个 Node 门禁、5 个 ArkTS 套件、设备侧路由安全冒烟测试 | 已通过本地自动化 |
| §3 首发保留/延期范围 | [`verify-lightweight-scope.mjs`](../../scripts/verify-lightweight-scope.mjs)、[`form_config.json`](../../entry/src/main/resources/base/profile/form_config.json) | 延期能力已移除；保留能力交互待真机 |
| §5 启动与导航 | [`LaunchIntent.ets`](../../entry/src/main/ets/common/LaunchIntent.ets)、设备侧 [`Ability.test.ets`](../../entry/src/ohosTest/ets/test/Ability.test.ets) | 白名单已验证；真机卡片待验 |
| §6 完全离线 | [`verify-offline.mjs`](../../scripts/verify-offline.mjs) 与本地隐私/关于页面 | 静态边界通过；飞行模式待验 |
| §7 轻量化 | [`verify-lightweight-scope.mjs`](../../scripts/verify-lightweight-scope.mjs) | 已通过 |
| §8 本地记录正确性 | [`MoodRecordPolicy.ets`](../../entry/src/main/ets/model/MoodRecordPolicy.ets)、[`DataManager.ets`](../../entry/src/main/ets/data/DataManager.ets) | 单测通过；重启持久化待真机 |
| §9 统计口径 | [`StatsViewModel.ets`](../../entry/src/main/ets/viewmodel/StatsViewModel.ets)、[`WidgetViewModel.ets`](../../entry/src/main/ets/viewmodel/WidgetViewModel.ets) | 已通过单测 |
| §10 定时通知延后 | 首发范围修订、离线门禁与构建后权限清单 | 提醒 UI、实现、状态、测试和权限均已移除；不属于本次真机验收 |
| §11 错误处理 | `Index` 重试/竞态保护、DataManager 落盘后更新、保存/删除失败分支 | 源码与构建通过；设备交互待真机 |
| §12 测试策略 | 自动化矩阵见上；`ohosTest` 测试 HAP 已成功构建；设备执行见下 | 自动与设备测试编译完成，真机执行待办 |
| §14 实施顺序与同步 | Git 提交 `02a1596` 至 `4be558a`，以及历史 Tasks 1–7 已以 GitHub/飞书回读验证的批次记录与最终验收章节 | 历史同步已完成；本节不作为本轮增量同步完成证据，本轮以包含本节的 GitHub 远端提交与飞书回读为准 |
| §15 非目标 | 离线、轻量与发布卫生门禁无禁用能力残留 | 已通过 |

## 真机自动冒烟入口

`scripts/run-device-smoke.mjs` 用于在真机到位后执行最小设备侧门禁。它要求两个 HAP 都使用绝对路径、拒绝文件名明确标记为 `unsigned` 的产物、调用 SDK 的 `verify-app` 验证签名、在多设备时要求显式选择目标，并仅在人工确认飞行模式后安装应用与测试 HAP。随后固定运行 `LaunchRouteSafety` 套件，并同时校验 Hypium 汇总与状态码，避免“命令退出 0、测试实际失败”被误判为通过。

```bash
node scripts/run-device-smoke.mjs \
  --app-hap /绝对路径/MoodLite-signed.hap \
  --test-hap /绝对路径/MoodLite-ohosTest-signed.hap \
  --flight-mode-confirmed yes \
  --target 设备序列号
```

只有一台设备时可省略 `--target`。该入口只覆盖设备侧路由安全冒烟测试，不能替代下方首次启动、记录持久化和桌面卡片等人工飞行模式验收；当前已有正式签名 HAP，但因没有连接真机而未执行。

## 模拟器补充验证（不替代真机证据）

- 验收日期：2026-09-12（Asia/Shanghai）
- 设备：HarmonyOS 模拟器，`127.0.0.1:5555`，`const.product.name=emulator`，`const.ohos.apiversion=23`
- 验收所基于的运行时代码提交：`981d51fa2c0289fedc31a951435315b3e0c6426b`（本轮文档提交以 Git log 及后续同步记录为准）
- 已发现使用本机 Debug profile 签名的 HAP（app 为 Release buildMode、test 为 ohosTest Debug buildMode；均非生产签名）：
  - `entry/build/default/outputs/default/entry-default-signed.hap`，SHA-256 `b6273bf7ef63ec8ae24ace80b9cdd800b1a19a862b87ca19aaf088034d56c3f4`
  - `entry/build/default/outputs/ohosTest/entry-ohosTest-signed.hap`，SHA-256 `1affa5b6abf3c5ac26bdbbe12a9a76d95f720f38a2a566fabc8655378cc6954b`
- 两个 HAP 均经 `hap-sign-tool verify-app` 校验成功，profile type 明确为 `debug`；Debug/Release app 构建均 `BUILD SUCCESSFUL`（33 tasks），ArkTS unit test `BUILD SUCCESSFUL`（20 tasks，10/10 pass）。ohosTest 首次 SignHap 因 `11014003/keystore password incorrect` 失败，未改配置，带 `--stacktrace` 原命令重试后 `BUILD SUCCESSFUL`（35 tasks）。
- `hdc list targets` 返回单个模拟器；`node --test scripts/run-device-smoke.test.mjs` 通过 7/7。在线模拟器安装 app/test HAP 成功，`aa test ... class LaunchRouteSafety` 返回 Hypium `Tests run: 1, Failure: 0, Error: 0, Pass: 1`、`OHOS_REPORT_CODE: 0`；此证据不替代真机飞行模式。
- 执行前网络状态：模拟器 `eth0` 为 `10.0.2.15`、`UP BROADCAST RUNNING`，`hidumper --net` 显示至外部地址的 ESTABLISHED/CLOSE_WAIT 连接，`ping 1.1.1.1` 成功；因此无法称为断网。
- 断网决策：未执行断网。`hdc shell` 身份为 `uid=2000(shell)` 且 `CapEff=0`；虽然系统提供 `ifconfig ... down`，但没有证据证明对模拟器接口执行后可由同一权限安全恢复，也没有可审计的模拟器飞行模式 API。为避免改变共享模拟器网络状态，未关闭 `eth0`、`wifi_eth` 或 `wlan0`。
- 模拟器结果仅证明连接、工具、产物和在线设备侧路由安全冒烟的补充事实；未勾选任何真机飞行模式条目，未生成生产签名或上架证据。网络恢复验证不适用（网络未被修改）。

## 首发范围真机飞行模式验收

执行前填写：

- 设备型号：待填写
- HarmonyOS 版本：待填写
- 生产/测试签名包哈希：待填写
- 执行人：待填写
- 执行日期：待填写

以下条目必须在已开启飞行模式的真实设备上逐项获得正向结果；未执行项不得以“未发现问题”代替：

- [ ] 清除应用数据后首次启动进入欢迎页，无登录、注册、会员或联网提示。
- [ ] 完成欢迎流程后进入主页面，飞行模式下无网络错误分支。
- [ ] 新增五档情绪中的至少两条记录，并包含预设标签、自定义标签和文字。
- [ ] 强制结束并重启应用，记录仍存在且按创建时间倒序展示。
- [ ] 时间线可进入详情，内容与标签正确。
- [ ] 编辑记录后分数/文字/标签更新，原始日期和创建时间不变。
- [ ] 删除成功后才离开详情；记录从时间线、首页、统计和卡片摘要中消失。
- [ ] 当月热力图、占比和标签只使用当前月；同一天多条记录只计一个记录日。
- [ ] 切换主题与深色模式后重启，设置仍保留。
- [ ] 添加 2×2 卡片，摘要、当天情绪和记录天数正确。
- [ ] 从卡片冷启动应用时先初始化本地数据，再进入安全目标；卡片更新可见。
- [ ] “数据与隐私”和“关于 MoodLite”均为本地页面，内容正确且不打开浏览器。
- [ ] 系统应用权限页只显示振动相关权限，不显示网络、媒体读取或代理提醒权限。

## 历史上架前阻塞项（已被 2026-09-20 结论取代）

- [ ] 连接真实 HarmonyOS 设备并完成上方全部飞行模式验收。
- [x] 使用现有正式发布证书生成并校验 Release 签名 APP/HAP，并在独立模拟器安装成功；详见 2026-09-19 产物与哈希。证书、私钥、口令和本机配置未提交到 Git。
- [ ] 完成代理提醒开放能力申请与包含该能力的 Profile 配置，解决正式包 `1700002` / `reminder_capability` 校验失败，然后重新验证提醒完整路径。
- [ ] 用最终生产签名包重新执行启动、提醒和 2×2 卡片回归。
- [x] 当前候选包保持既有未混淆配置；若后续启用，需为 ArkUI 路由、FormExtensionAbility 和序列化字段补保留规则并重新回归。
- [ ] 若该 GitHub 仓库曾对外开放，评估是否轮换旧调试签名材料并清理历史中的本机签名配置引用。仓库历史未包含证书或私钥文件。

【历史结论】本段已被文首 2026-09-20 最新首发候选包结论取代。
