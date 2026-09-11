# MoodLite 完全离线轻量版发布验收清单

**当前结论：自动化验收通过；真机飞行模式、生产签名和上架包验收尚未完成，当前不得标记“可上架”。**

## 验收基线

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
| §10 提醒状态 | [`ReminderState.test.ets`](../../entry/src/test/ReminderState.test.ets)、[`ReminderManager.ets`](../../entry/src/main/ets/common/ReminderManager.ets)、[`Profile.ets`](../../entry/src/main/ets/pages/Profile.ets) | 状态构造通过；系统发布/取消待真机 |
| §11 错误处理 | `Index` 重试/竞态保护、DataManager 落盘后更新、保存/删除/提醒失败分支 | 源码与构建通过；系统失败路径待真机 |
| §12 测试策略 | 自动化矩阵见上；`ohosTest` 测试 HAP 已成功构建；设备执行见下 | 自动与设备测试编译完成，真机执行待办 |
| §14 实施顺序与同步 | Git 提交 `02a1596` 至 `4be558a`，以及指定飞书项目文档的批次记录与最终验收章节 | 以 GitHub 远端哈希和飞书章节回读为准 |
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

只有一台设备时可省略 `--target`。该入口只覆盖设备侧路由安全冒烟测试，不能替代下方首次启动、记录持久化、提醒和桌面卡片等人工飞行模式验收；当前仍因没有连接真机和已签名 HAP 而未执行。

## 真机飞行模式验收

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
- [ ] 关闭态打开提醒时先弹时间选择器；取消选择后开关保持关闭。
- [ ] 确认提醒后系统实际创建提醒、开关和时间正确；修改时间不会遗留重复提醒。
- [ ] 关闭提醒后系统实际取消；重启后提醒配置与系统状态一致。
- [ ] 添加 2×2 卡片，摘要、当天情绪和记录天数正确。
- [ ] 从卡片冷启动应用时先初始化本地数据，再进入安全目标；卡片更新可见。
- [ ] “数据与隐私”和“关于 MoodLite”均为本地页面，内容正确且不打开浏览器。
- [ ] 系统应用权限页只显示提醒与振动相关权限，不显示网络或媒体读取权限。

## 上架前阻塞项

- [ ] 连接真实 HarmonyOS 设备并完成上方全部飞行模式验收。
- [ ] 在受控环境配置正式发布证书，生成并校验可安装的生产签名包；历史 Debug Profile 不能替代，且不得把证书、私钥或口令提交到 Git。
- [ ] 用最终生产签名包重新执行启动、提醒和 2×2 卡片回归。
- [ ] 决定是否启用源码混淆；若启用，需为 ArkUI 路由、FormExtensionAbility 和序列化字段补保留规则并重新回归。
- [ ] 若该 GitHub 仓库曾对外开放，评估是否轮换旧调试签名材料并清理历史中的本机签名配置引用。仓库历史未包含证书或私钥文件。

全部阻塞项和真机条目勾选前，本清单结论保持“自动化通过，尚不可上架”。
