# MoodLite 完全离线轻量版实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 MoodLite 收敛为完全离线、无需登录，并可在飞行模式下完成记录、历史、编辑删除、月度统计、主题、本地提醒和 2×2 卡片闭环的轻量情绪日记。

**Architecture:** 保留 Stage 模型、ArkUI、ArkTS 和 Preferences，以 `DataManager` 为本地单一事实来源；把记录规范化、编辑合并、统计摘要、卡片摘要与启动意图校验提取为可单测的纯函数。运行时不保留网络、账号、AI、成就、2×4 卡片或第二条写入链路；每个可验证批次都提交到 `main`，推送 GitHub，并追加到同一份 MoodLite 飞书项目文档。

**Tech Stack:** HarmonyOS 6.0.1 / API 21、ArkTS、ArkUI、Preferences、Reminder Agent、FormExtensionAbility、Hypium、Node.js 静态约束脚本、Git、飞书云文档 v2。

**Spec:** `docs/superpowers/specs/2026-09-10-offline-lightweight-mood-diary-design.md`

## Global Constraints

- `targetSdkVersion` 与 `compatibleSdkVersion` 固定为 `6.0.1(21)`，不得为适配本机工具链而提升。
- 应用运行时不得请求网络、打开网页、引用远程 URL、AI 服务地址或 API Key。
- 情绪数据只保存在本机 Preferences；不添加登录、会员、云同步、备份、导出、图片、位置或社交功能。
- 只保留 `ohos.permission.PUBLISH_AGENT_REMINDER` 和 `ohos.permission.VIBRATE` 两项实际使用权限。
- 旧数据中的 `images` 与 `location` 只做兼容读取和编辑保留，新记录固定写入 `[]` 与 `''`。
- 编辑只允许改变 `score`、`text`、`tags`，必须保留 `id`、`timestamp`、`dateStr`、`images`、`location`。
- 保存、删除、提醒发布或取消失败时，界面不得提前显示成功状态。
- 统计与卡片中的“记录天数”都按当月不重复 `dateStr` 计算。
- 桌面卡片启动目标只允许 `pages/MainPage` 与 `pages/AddEntry`，且必须先经过 `Index` 和 `DataManager.init()`。
- 每个批次只暂存计划列出的文件；不提交 `.DS_Store`、`AGENTS.md` 或用户的无关改动。
- 每个批次在测试通过后执行：Git 提交 → `git push origin main` → 更新 MoodLite 飞书项目文档 → 重新读取远端章节验证。

---

## 文件职责映射

- `scripts/verify-offline.mjs`：扫描运行时源码、页面清单、模块清单和模块构建配置，阻止网络、AI、账号与远程地址回归。
- `scripts/verify-lightweight-scope.mjs`：阻止成就、2×4 卡片、快捷写入和未注册备份能力重新进入首发包。
- `entry/src/main/ets/model/MoodRecordPolicy.ets`：解析、校验、规范化、排序旧记录，并构造保留元数据的编辑结果。
- `entry/src/main/ets/viewmodel/StatsViewModel.ets`：月份过滤、月度聚合、标签分布和唯一记录日口径。
- `entry/src/main/ets/viewmodel/WidgetViewModel.ets`：生成 2×2 卡片使用的纯数据摘要，供主进程和 Form 进程共用。
- `entry/src/main/ets/common/LaunchIntent.ets`：解析和白名单校验卡片启动参数。
- `entry/src/main/ets/data/DataManager.ets`：唯一的主应用记录持久化入口，成功落盘后才更新缓存和卡片。
- `entry/src/main/ets/common/ReminderManager.ets`：只封装系统提醒发布/取消结果，不直接改 UI 持久状态。
- `entry/src/main/ets/pages/DataPrivacyPage.ets` 与 `AboutPage.ets`：完全本地的信息页面。
- `entry/src/test/*.test.ets`：纯函数单元测试；`entry/src/test/List.test.ets` 统一注册。

---

### Task 1: 建立离线边界并移除 AI、外链和无用权限

**Files:**
- Create: `scripts/verify-offline.mjs`
- Create: `entry/src/main/ets/pages/DataPrivacyPage.ets`
- Create: `entry/src/main/ets/pages/AboutPage.ets`
- Modify: `entry/build-profile.json5`
- Modify: `entry/src/main/module.json5`
- Modify: `entry/src/main/resources/base/profile/main_pages.json`
- Modify: `entry/src/main/ets/pages/AddEntry.ets`
- Modify: `entry/src/main/ets/pages/HomeTab.ets`
- Modify: `entry/src/main/ets/pages/Profile.ets`
- Delete: `entry/src/main/ets/common/utils/AiAgentClient.ets`

**Interfaces:**
- Consumes: `resolveColors(darkMode: boolean, preset: string)`、现有 `GlassCard`、ArkUI router。
- Produces: `scripts/verify-offline.mjs` 的零退出码离线门禁；路由 `pages/DataPrivacyPage` 与 `pages/AboutPage`；不含 AI/网络分支的 `AddEntry` 与 `HomeTab`。

- [x] **Step 1: 写入会在当前代码上失败的离线约束脚本**

```js
// scripts/verify-offline.mjs
import { readFile, readdir, stat } from 'node:fs/promises';
import { extname, join, relative } from 'node:path';

const root = new URL('..', import.meta.url);
const scanRoots = [
  'entry/src/main/ets',
  'entry/src/main/module.json5',
  'entry/src/main/resources/base/profile/main_pages.json',
  'entry/build-profile.json5',
];
const forbidden = [
  ['network API', /@ohos\.net|@kit\.NetworkKit/],
  ['remote URL', /https?:\/\//],
  ['AI configuration', /DIFY|DEEPSEEK|API_KEY|AiAgentClient|analyzeMood|activeIntent/],
  ['internet permission', /ohos\.permission\.INTERNET/],
  ['media read permission', /ohos\.permission\.READ_IMAGEVIDEO/],
  ['account residue', /AuthManager|LoginPage|memberType|AIAgentChatPage/],
];

async function filesAt(path) {
  const url = new URL(path, root);
  const metadata = await stat(url);
  if (metadata.isFile()) return [url];
  const entries = await readdir(url, { withFileTypes: true });
  const nested = await Promise.all(entries.map(entry =>
    entry.isDirectory() ? filesAt(join(path, entry.name)) : [new URL(join(path, entry.name), root)]));
  return nested.flat().filter(file => ['.ets', '.ts', '.json5', '.json'].includes(extname(file.pathname)));
}

const files = (await Promise.all(scanRoots.map(filesAt))).flat();
const violations = [];
for (const file of files) {
  const content = await readFile(file, 'utf8');
  for (const [label, pattern] of forbidden) {
    if (pattern.test(content)) violations.push(`${label}: ${relative(root.pathname, file.pathname)}`);
  }
}
if (violations.length > 0) {
  console.error(violations.join('\n'));
  process.exit(1);
}
console.log(`offline verification passed (${files.length} files scanned)`);
```

- [x] **Step 2: 运行脚本并确认失败原因覆盖现有联网实现**

Run: `node scripts/verify-offline.mjs`

Expected: FAIL，至少报告 `AiAgentClient.ets`、`DIFY_API_KEY`、`https://api.dify.ai`、Profile 外链、`ohos.permission.INTERNET` 和 `ohos.permission.READ_IMAGEVIDEO`。

- [x] **Step 3: 删除 AI 调用、配置和权限**

在 `AddEntry.ets` 删除 `analyzeMood` import 与保存成功后的 `activeIntent` 分支；在 `HomeTab.ets` 删除 `AiSuggestion`、`@StorageLink('activeIntent')`、解析/动画状态和“AI 温暖提示”卡片。将 `entry/build-profile.json5` 的 `buildProfileFields` 整体删除，并从 `module.json5` 删除 `INTERNET` 与 `READ_IMAGEVIDEO` 权限。

- [x] **Step 4: 用两个本地页面替换 Profile 外链**

`Profile.ets` 的信息项固定为“数据与隐私”和“关于 MoodLite”，点击时分别调用：

```ts
this.getUIContext().getRouter().pushUrl({ url: 'pages/DataPrivacyPage' });
this.getUIContext().getRouter().pushUrl({ url: 'pages/AboutPage' });
```

`DataPrivacyPage.ets` 明确展示：记录、标签、主题和提醒配置仅在本机；无需账号；不上传情绪内容；不调用第三方 AI；卸载或清空数据后无法由云端恢复。`AboutPage.ets` 展示应用名称、版本 `1.0.0`、产品定位与“完全离线”说明。两个页面复用现有主题、卡片、间距和返回按钮，不导入 `common`、`Want` 或浏览器能力。

- [x] **Step 5: 注册本地页面并重新运行离线检查**

在 `main_pages.json` 增加 `pages/DataPrivacyPage` 与 `pages/AboutPage`。

Run: `node scripts/verify-offline.mjs`

Expected: PASS，输出扫描文件数且无违规项。

- [x] **Step 6: 构建当前批次**

Run: `/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw --mode module -p product=default -p module=entry@default assembleHap --no-daemon`

Expected: API 21 工具链可用时 PASS；若构建在读取 ArkTS 前因本机仅有 API 26 而停止，保留完整错误证据，不改目标版本，并继续以静态门禁验证本批次。

- [x] **Step 7: 提交并同步批次**

```bash
git add scripts/verify-offline.mjs entry/build-profile.json5 entry/src/main/module.json5 \
  entry/src/main/resources/base/profile/main_pages.json \
  entry/src/main/ets/pages/AddEntry.ets entry/src/main/ets/pages/HomeTab.ets \
  entry/src/main/ets/pages/Profile.ets entry/src/main/ets/pages/DataPrivacyPage.ets \
  entry/src/main/ets/pages/AboutPage.ets entry/src/main/ets/common/utils/AiAgentClient.ets
git commit -m "feat: make MoodLite runtime fully offline"
git push origin main
```

飞书追加“批次 1：离线边界”，记录提交哈希、`verify-offline` 结果、构建结果和剩余批次；随后按该标题关键词重新读取，确认远端内容存在。

---

### Task 2: 移除成就、2×4 卡片、快捷写入和未启用备份

**Files:**
- Create: `scripts/verify-lightweight-scope.mjs`
- Modify: `entry/src/main/ets/data/DataManager.ets`
- Modify: `entry/src/main/ets/pages/HomeTab.ets`
- Modify: `entry/src/main/ets/entryformability/EntryFormAbility.ets`
- Modify: `entry/src/main/ets/common/utils/WidgetSyncManager.ets`
- Modify: `entry/src/main/resources/base/profile/form_config.json`
- Modify: `entry/src/main/resources/base/element/string.json`
- Delete: `entry/src/main/ets/common/components/AchievementDialog.ets`
- Delete: `entry/src/main/ets/model/Achievement.ets`
- Delete: `entry/src/main/ets/viewmodel/AchievementChecker.ets`
- Delete: `entry/src/main/ets/entrybackupability/EntryBackupAbility.ets`
- Delete: `entry/src/main/ets/widget1/pages/Widget1Card.ets`
- Delete: `entry/src/main/ets/widget1/view/ControlButtonComponent.ets`
- Delete: `entry/src/main/ets/widget1/viewmodel/ControlButtonParameter.ets`
- Delete: `entry/src/main/resources/base/profile/backup_config.json`
- Delete: `entry/src/main/resources/base/media/achievement_hourglass.png`
- Delete: `entry/src/main/resources/base/media/achievement_magnifier.png`
- Delete: `entry/src/main/resources/base/media/achievement_palette.png`
- Delete: `entry/src/main/resources/base/media/achievement_rainbow.png`
- Delete: `entry/src/main/resources/base/media/achievement_seed.png`
- Delete: `entry/src/main/resources/base/media/achievement_steps.png`
- Delete: `entry/src/main/resources/base/media/achievement_zen.png`
- Delete: `entry/src/main/resources/base/media/ic_cloud_download.svg`
- Delete: `entry/src/main/resources/base/media/ic_export.svg`
- Delete: `entry/src/main/resources/base/media/ic_image.svg`
- Delete: `entry/src/main/resources/base/media/ic_location.svg`
- Delete: `entry/src/main/resources/base/media/ic_message.svg`
- Delete: `entry/src/main/resources/base/media/ic_widget_activity.png`
- Delete: `entry/src/main/resources/base/media/ic_widget_background.png`
- Delete: `entry/src/main/resources/base/media/ic_widget_explored.png`
- Delete: `entry/src/main/resources/base/media/ic_widget_mine.png`
- Delete: `entry/src/main/resources/base/media/ic_widget_study.png`

**Interfaces:**
- Consumes: Task 1 的 `verify-offline.mjs`。
- Produces: 只注册 `MoodWidgetCard` 的 `form_config.json`；只有 `DataManager.saveRecord()` 的主应用写入链路；没有成就或备份代码的首发包。

- [x] **Step 1: 写轻量范围检查并确认当前失败**

```js
// scripts/verify-lightweight-scope.mjs
import { access, readFile } from 'node:fs/promises';

const forbiddenPaths = [
  'entry/src/main/ets/model/Achievement.ets',
  'entry/src/main/ets/viewmodel/AchievementChecker.ets',
  'entry/src/main/ets/common/components/AchievementDialog.ets',
  'entry/src/main/ets/widget1',
  'entry/src/main/ets/entrybackupability',
  'entry/src/main/resources/base/profile/backup_config.json',
];
const existing = [];
for (const path of forbiddenPaths) {
  try { await access(path); existing.push(path); } catch (_) {}
}
const formConfig = await readFile('entry/src/main/resources/base/profile/form_config.json', 'utf8');
const runtime = await Promise.all([
  readFile('entry/src/main/ets/data/DataManager.ets', 'utf8'),
  readFile('entry/src/main/ets/entryformability/EntryFormAbility.ets', 'utf8'),
]);
const violations = [
  ...existing,
  ...(formConfig.includes('widget1') || formConfig.includes('2*4') ? ['2x4 form registration'] : []),
  ...(runtime.join('\n').match(/quickSaveRecord|quick_log|checkNewAchievements|pending_achievements/g) || []),
];
if (violations.length) {
  console.error(violations.join('\n'));
  process.exit(1);
}
console.log('lightweight scope verification passed');
```

Run: `node scripts/verify-lightweight-scope.mjs`

Expected: FAIL，列出成就文件、`widget1`、备份目录、2×4 注册和 `quickSaveRecord`/`quick_log`。

- [x] **Step 2: 从 DataManager 和 HomeTab 删除成就状态与 UI**

`DataManager.ets` 删除成就 imports、keys、缓存字段、初始化读取、结算、队列 API、`AppStorage('achievements')` 同步与 `quickSaveRecord`；保留记录 CRUD、首次启动和清空本地数据。`HomeTab.ets` 只保留今日摘要、固定本地关怀文案、空状态和记录入口，删除全部成就 import、状态、弹窗、动画与素材引用。

- [x] **Step 3: 删除第二条写入链路与 2×4 卡片**

`EntryFormAbility.ets` 删除 `QuickLogMessage`、`onFormEvent()`、`generateUUID`/`quickSaveRecord` imports；`form_config.json` 只保留 `MoodWidgetCard` 的 2×2 配置。同步删除 `widget1`、成就、备份文件和仅为延期功能存在的素材/字符串。

- [x] **Step 4: 修正文案与注释并执行双门禁**

将 `EntryFormAbility` 与 `WidgetSyncManager` 中“同时服务 2x2 和 2x4”“快捷记录”等注释改为真实的 2×2 展示职责。

Run: `node scripts/verify-offline.mjs && node scripts/verify-lightweight-scope.mjs`

Expected: PASS。

- [x] **Step 5: 编译并提交同步**

Run: `/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw --mode module -p product=default -p module=entry@default assembleHap --no-daemon`

```bash
git add scripts/verify-lightweight-scope.mjs entry/src/main/ets/data/DataManager.ets \
  entry/src/main/ets/pages/HomeTab.ets entry/src/main/ets/entryformability/EntryFormAbility.ets \
  entry/src/main/ets/common/utils/WidgetSyncManager.ets \
  entry/src/main/resources/base/profile/form_config.json entry/src/main/resources/base/element/string.json
git add entry/src/main/ets/common/components/AchievementDialog.ets \
  entry/src/main/ets/model/Achievement.ets entry/src/main/ets/viewmodel/AchievementChecker.ets \
  entry/src/main/ets/entrybackupability entry/src/main/ets/widget1 \
  entry/src/main/resources/base/profile/backup_config.json \
  entry/src/main/resources/base/media/achievement_hourglass.png \
  entry/src/main/resources/base/media/achievement_magnifier.png \
  entry/src/main/resources/base/media/achievement_palette.png \
  entry/src/main/resources/base/media/achievement_rainbow.png \
  entry/src/main/resources/base/media/achievement_seed.png \
  entry/src/main/resources/base/media/achievement_steps.png \
  entry/src/main/resources/base/media/achievement_zen.png \
  entry/src/main/resources/base/media/ic_cloud_download.svg \
  entry/src/main/resources/base/media/ic_export.svg \
  entry/src/main/resources/base/media/ic_image.svg \
  entry/src/main/resources/base/media/ic_location.svg \
  entry/src/main/resources/base/media/ic_message.svg \
  entry/src/main/resources/base/media/ic_widget_activity.png \
  entry/src/main/resources/base/media/ic_widget_background.png \
  entry/src/main/resources/base/media/ic_widget_explored.png \
  entry/src/main/resources/base/media/ic_widget_mine.png \
  entry/src/main/resources/base/media/ic_widget_study.png
git commit -m "refactor: remove deferred release features"
git push origin main
```

飞书追加“批次 2：轻量化”，列出删除范围、提交哈希、双门禁与构建结果；重新读取该章节验证。

---

### Task 3: 规范化本地数据并保证编辑与删除语义

**Files:**
- Create: `entry/src/main/ets/model/MoodRecordPolicy.ets`
- Create: `entry/src/test/MoodRecordPolicy.test.ets`
- Modify: `entry/src/test/List.test.ets`
- Modify: `entry/src/main/ets/data/DataManager.ets`
- Modify: `entry/src/main/ets/common/EditBridge.ets`
- Modify: `entry/src/main/ets/pages/AddEntry.ets`
- Modify: `entry/src/main/ets/pages/EntryDetail.ets`

**Interfaces:**
- Produces: `parseMoodRecords(raw: string): MoodRecord[]`、`normalizeMoodRecord(value: Object): MoodRecord | null`、`buildEditedMoodRecord(original: MoodRecord, score: number, text: string, tags: string[]): MoodRecord`。
- Consumes: `MoodRecord`、`formatDateStr()`、`DataManager.saveRecord()` 与 `deleteRecord()`。

- [x] **Step 1: 写失败单测并注册测试套件**

```ts
// entry/src/test/MoodRecordPolicy.test.ets
import { describe, it, expect } from '@ohos/hypium';
import { buildEditedMoodRecord, parseMoodRecords } from '../main/ets/model/MoodRecordPolicy';
import { MoodRecord } from '../main/ets/model/MoodRecord';

export default function moodRecordPolicyTest(): void {
  describe('MoodRecordPolicy', () => {
    it('normalizesLegacyRecordsAndSortsNewestFirst', 0, () => {
      const raw = JSON.stringify([
        { id: 'old', timestamp: 100, dateStr: '2026-09-01', score: 8, text: 'a' },
        { id: '', timestamp: 200, dateStr: '2026-09-02', score: 0, text: 'bad' },
        { id: 'new', timestamp: 300, dateStr: '2026-09-03', score: 1.6, text: 'b', tags: ['工作'] },
      ]);
      const records = parseMoodRecords(raw);
      expect(records.length).assertEqual(2);
      expect(records[0].id).assertEqual('new');
      expect(records[0].score).assertEqual(2);
      expect(records[0].images.length).assertEqual(0);
      expect(records[0].location).assertEqual('');
      expect(records[1].score).assertEqual(2);
    });

    it('returnsEmptyListForMalformedJson', 0, () => {
      expect(parseMoodRecords('{broken').length).assertEqual(0);
    });

    it('preservesIdentityAndCompatibilityFieldsWhenEditing', 0, () => {
      const original: MoodRecord = {
        id: 'r1', timestamp: 123, dateStr: '2026-08-03', score: -1,
        text: 'old', tags: ['旧'], images: ['sandbox://legacy'], location: 'legacy',
      };
      const edited = buildEditedMoodRecord(original, 2, 'new', ['新']);
      expect(edited.id).assertEqual('r1');
      expect(edited.timestamp).assertEqual(123);
      expect(edited.dateStr).assertEqual('2026-08-03');
      expect(edited.images[0]).assertEqual('sandbox://legacy');
      expect(edited.location).assertEqual('legacy');
      expect(edited.score).assertEqual(2);
      expect(edited.text).assertEqual('new');
    });
  });
}
```

在 `List.test.ets` import 并调用 `moodRecordPolicyTest()`。

- [x] **Step 2: 运行单测并确认缺少纯函数实现**

Run: `/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw --mode module -p product=default -p module=entry@default test --no-daemon`

Expected: API 21 工具链可用时 FAIL，错误指向 `MoodRecordPolicy` 模块或导出函数不存在；工具链不匹配时记录环境失败，不把它误报为测试失败。

- [x] **Step 3: 实现记录规范化与编辑构造函数**

`normalizeMoodRecord()` 仅接受非空字符串 ID、正有限时间戳、严格 `YYYY-MM-DD` 日期和可转为有限数值的 score。日期除正则外，还要解析年月日并用 `new Date(year, month - 1, day)` 回读验证，拒绝 `2026-02-30`、月份 0/13 等无效日期；score 先四舍五入再限制到 `[-2, 2]`。`text`/`location` 非字符串时使用空字符串，`tags`/`images` 只保留字符串元素并复制数组。`parseMoodRecords()` 捕获 JSON 错误、拒绝非数组、过滤 null，并按 `timestamp` 降序。`buildEditedMoodRecord()` 复制原对象的身份/时间/兼容字段，只替换经过限制的 score、text 与 tags。

- [x] **Step 4: 接入 DataManager 的读写缓存**

`doInit()` 用 `parseMoodRecords(recordsRaw)` 预热缓存；解析损坏时记录错误并使用空数组，但 Preferences 本身打不开时仍抛错进入 Index 可重试错误态。`saveRecord()` 与 `deleteRecord()` 以当前已规范化 `cache` 构造候选数组，只有 `put()` 与 `flush()` 成功后才替换 `cache` 并异步刷新卡片。

- [x] **Step 5: 让编辑桥传递完整记录副本**

`EditPayload` 改为：

```ts
export interface EditPayload {
  record: MoodRecord;
}
```

`setEditPayload()` 深拷贝 `tags`、`images`；`getEditPayload()` 单次消费。`EntryDetail.onEdit()` 传入完整记录，`AddEntry.aboutToAppear()` 保存 `originalRecord: MoodRecord | null`，`done()` 编辑时调用 `buildEditedMoodRecord()`，新增时仍生成新 ID、当前时间、空兼容字段。

- [x] **Step 6: 修复删除失败反馈和重复点击**

为 `EntryDetail` 增加 `@State deleting: boolean = false`。`doDelete()` 在处理中直接返回；只有 `DataManager.deleteRecord()` 返回 `true` 才设置时间线 tab 并返回，返回 `false` 时留在当前页并显示“删除失败，请重试”。确认按钮在 `deleting` 时不可再次触发。

- [x] **Step 7: 运行单测、静态门禁和构建**

Run: `/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw --mode module -p product=default -p module=entry@default test --no-daemon`

Run: `node scripts/verify-offline.mjs && node scripts/verify-lightweight-scope.mjs`

Run: `/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw --mode module -p product=default -p module=entry@default assembleHap --no-daemon`

Expected: 单测覆盖三条规范化场景与编辑保留字段；静态门禁 PASS；构建在正确 API 21 工具链下 PASS。

- [x] **Step 8: 提交并同步批次**

```bash
git add entry/src/main/ets/model/MoodRecordPolicy.ets entry/src/test/MoodRecordPolicy.test.ets \
  entry/src/test/List.test.ets entry/src/main/ets/data/DataManager.ets \
  entry/src/main/ets/common/EditBridge.ets entry/src/main/ets/pages/AddEntry.ets \
  entry/src/main/ets/pages/EntryDetail.ets
git commit -m "fix: preserve and validate local mood records"
git push origin main
```

飞书追加“批次 3：记录正确性”，记录旧数据处理、编辑/删除语义、提交哈希和测试结果；按标题重新读取验证。

---

### Task 4: 统一月度统计与 2×2 卡片摘要口径

**Files:**
- Create: `entry/src/main/ets/viewmodel/WidgetViewModel.ets`
- Create: `entry/src/test/StatsViewModel.test.ets`
- Create: `entry/src/test/WidgetViewModel.test.ets`
- Modify: `entry/src/test/List.test.ets`
- Modify: `entry/src/main/ets/viewmodel/StatsViewModel.ets`
- Modify: `entry/src/main/ets/pages/Stats.ets`
- Modify: `entry/src/main/ets/common/utils/WidgetSyncManager.ets`
- Modify: `entry/src/main/ets/entryformability/EntryFormAbility.ets`

**Interfaces:**
- Produces: `recordsForMonth(records: MoodRecord[], year: number, month: number): MoodRecord[]`、`countUniqueRecordDays(records: MoodRecord[]): number`、`buildWidgetSummary(records: MoodRecord[], now: Date, darkMode: boolean): WidgetSummary`、`buildCompactMonthData(records: MoodRecord[], year: number, month: number): number[]`。
- Consumes: `calcMonthlyStats()`、`calcTagDistribution()`、`calcStreak()`、MoodRecord 情绪映射函数。

- [x] **Step 1: 写月度隔离与唯一日期失败测试**

```ts
// entry/src/test/StatsViewModel.test.ets
import { describe, it, expect } from '@ohos/hypium';
import { recordsForMonth, calcMonthlyStats, calcTagDistribution } from '../main/ets/viewmodel/StatsViewModel';
import { MoodRecord } from '../main/ets/model/MoodRecord';

function record(id: string, dateStr: string, score: number, tags: string[]): MoodRecord {
  return { id, dateStr, score, tags, timestamp: 1, text: '', images: [], location: '' };
}

export default function statsViewModelTest(): void {
  describe('StatsViewModel month scope', () => {
    it('keepsTagsInsideSelectedMonthAndCountsUniqueDays', 0, () => {
      const all = [
        record('a', '2026-09-01', 2, ['九月']),
        record('b', '2026-09-01', -1, ['同日']),
        record('c', '2026-08-31', 1, ['八月']),
      ];
      const september = recordsForMonth(all, 2026, 9);
      const stats = calcMonthlyStats(2026, 9, september);
      const tags = calcTagDistribution(september);
      expect(september.length).assertEqual(2);
      expect(stats.totalDays).assertEqual(1);
      expect(tags.some(item => item.tag === '八月')).assertFalse();
    });
  });
}
```

- [x] **Step 2: 写卡片摘要失败测试**

```ts
// entry/src/test/WidgetViewModel.test.ets
import { describe, it, expect } from '@ohos/hypium';
import { buildWidgetSummary } from '../main/ets/viewmodel/WidgetViewModel';
import { MoodRecord } from '../main/ets/model/MoodRecord';

export default function widgetViewModelTest(): void {
  describe('WidgetViewModel', () => {
    it('countsTwoRecordsOnOneDayAsOneRecordDay', 0, () => {
      const records: MoodRecord[] = [
        { id: 'a', timestamp: 2, dateStr: '2026-09-02', score: 2, text: '', tags: [], images: [], location: '' },
        { id: 'b', timestamp: 1, dateStr: '2026-09-02', score: -1, text: '', tags: [], images: [], location: '' },
      ];
      const summary = buildWidgetSummary(records, new Date(2026, 8, 2), false);
      expect(summary.recordDays).assertEqual(1);
      expect(summary.happyPercent).assertEqual(50);
      expect(summary.sadPercent).assertEqual(50);
    });
  });
}
```

注册两个测试套件后运行 unit test；Expected: FAIL，因为 `recordsForMonth` 与 `WidgetViewModel` 尚不存在。

- [x] **Step 3: 实现共享月份与卡片纯函数**

`recordsForMonth()` 使用完整 `YYYY-MM-` 前缀过滤；`countUniqueRecordDays()` 使用 `Set<string>`；`buildWidgetSummary()` 只统计 `now` 所在月份，记录条数用于情绪占比、不重复日期用于 `recordDays`，并选择当天时间戳最大的记录作为今日状态。`buildCompactMonthData()` 接受显式年月，避免单测依赖系统时间。

- [x] **Step 4: 删除 Stats 的脆弱缓存并只传当月标签**

`StatsContent.refresh()` 每次调用 `recordsForMonth(this.records, this.year, this.month)`；删除 `monthCache`、`lastRecordKey` 与 `rebuildCache()`。热力图、`calcMonthlyStats()` 和 `calcTagDistribution()` 均接收同一个 `monthRecords`。

- [x] **Step 5: 让两个卡片进程复用 WidgetViewModel**

`WidgetSyncManager.updateWidgets()` 和 `EntryFormAbility.buildWidgetData()` 都调用 `buildWidgetSummary(records, new Date(), darkMode)`，不再各自复制月度循环。主进程只额外负责 form ID 和 `formProvider.updateForm()`，Form 进程只负责读取 Preferences 与绑定数据。

- [x] **Step 6: 运行单测、双门禁和构建**

Run: `/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw --mode module -p product=default -p module=entry@default test --no-daemon`

Run: `node scripts/verify-offline.mjs && node scripts/verify-lightweight-scope.mjs`

Run: `/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw --mode module -p product=default -p module=entry@default assembleHap --no-daemon`

Expected: 月份隔离、唯一记录日与卡片占比测试 PASS。

- [x] **Step 7: 提交并同步批次**

```bash
git add entry/src/main/ets/viewmodel/WidgetViewModel.ets \
  entry/src/main/ets/viewmodel/StatsViewModel.ets entry/src/main/ets/pages/Stats.ets \
  entry/src/main/ets/common/utils/WidgetSyncManager.ets \
  entry/src/main/ets/entryformability/EntryFormAbility.ets \
  entry/src/test/StatsViewModel.test.ets entry/src/test/WidgetViewModel.test.ets entry/src/test/List.test.ets
git commit -m "fix: align monthly and widget statistics"
git push origin main
```

飞书追加“批次 4：统计口径”，写入提交哈希、月度标签隔离和唯一记录日测试结果；重新读取验证。

---

### Task 5: 保证卡片冷启动先初始化并限制导航目标

**Files:**
- Create: `entry/src/main/ets/common/LaunchIntent.ets`
- Create: `entry/src/test/LaunchIntent.test.ets`
- Modify: `entry/src/test/List.test.ets`
- Modify: `entry/src/main/ets/entryability/EntryAbility.ets`
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/main/ets/widget/pages/MoodWidgetCard.ets`

**Interfaces:**
- Produces: `parseLaunchIntent(params: Record<string, Object> | undefined): LaunchIntent`，其中 `LaunchIntent` 为 `{ targetPage: string; tab: number | null }`；允许目标集合固定为 `pages/MainPage` 与 `pages/AddEntry`。
- Consumes: `DataManager.init()`、`DataManager.isFirstLaunch()`、AppStorage keys `moodlite_pending_target` 与 `moodlite_pending_tab`。

- [x] **Step 1: 写合法、非法和缺省参数失败测试**

```ts
import { describe, it, expect } from '@ohos/hypium';
import { parseLaunchIntent } from '../main/ets/common/LaunchIntent';

export default function launchIntentTest(): void {
  describe('LaunchIntent', () => {
    it('acceptsOnlyWhitelistedTargets', 0, () => {
      expect(parseLaunchIntent({ targetPage: 'pages/AddEntry', tab: 1 }).targetPage).assertEqual('pages/AddEntry');
      expect(parseLaunchIntent({ targetPage: 'pages/Profile' }).targetPage).assertEqual('');
      expect(parseLaunchIntent({ targetPage: 'https://example.com' }).targetPage).assertEqual('');
    });
    it('dropsInvalidTabValues', 0, () => {
      expect(parseLaunchIntent({ targetPage: 'pages/MainPage', tab: 99 }).tab).assertNull();
      expect(parseLaunchIntent(undefined).targetPage).assertEqual('');
    });
  });
}
```

注册测试并运行 unit test；Expected: FAIL，`LaunchIntent` 模块不存在。

- [x] **Step 2: 实现纯函数白名单**

`parseLaunchIntent()` 只接受两个精确字符串；tab 只接受 `0`、`1`、`3`、`4`。非法值返回空目标与 `null` tab，函数不访问 AppStorage 或 router。

- [x] **Step 3: EntryAbility 冷启动始终加载 Index，热启动只导航白名单目标**

`onCreate()` 调用私有 `storeLaunchIntent(want)`；该方法校验后写入临时 AppStorage。`onWindowStageCreate()` 无条件执行：

```ts
windowStage.loadContent('pages/Index', callback);
```

`onNewWant()` 同样先调用 `parseLaunchIntent()`：非法目标只记录日志并忽略；`DataManager.isReady()` 为 `false` 时写入临时 AppStorage 等待 Index 消费；已经初始化时才用 `router.replaceUrl()` 导航到经过白名单校验的目标，并在导航前应用合法 tab。不得把未校验的 `targetPage` 传给 router。

- [x] **Step 4: Index 在初始化成功后消费安全目标**

`Index` 初始化成功后先读取并删除 `moodlite_pending_target`/`moodlite_pending_tab`。首次启动仍优先进入 Welcome；非首次启动时，有白名单目标就进入该目标，否则进入 MainPage。AddEntry 接收合法 tab；非法或缺失参数安全回落 MainPage。EMPTY 错误态按钮改为“重试”，重新调用初始化函数，不得绕过 DataManager 直接进主页面。每次初始化递增 `attemptId`，Promise 回调只有在捕获的 ID 等于当前 ID 且状态仍为 `LOADING` 时才允许导航，防止旧的超时请求在重试后覆盖新状态。

- [x] **Step 5: 验证 2×2 卡片目标与测试**

`MoodWidgetCard` 保持 `targetPage: 'pages/MainPage'`，不增加其他目标。运行 unit test、双门禁和 assembleHap；Expected: 白名单测试 PASS，静态门禁 PASS，正确工具链下构建 PASS。

- [x] **Step 6: 提交并同步批次**

```bash
git add entry/src/main/ets/common/LaunchIntent.ets entry/src/test/LaunchIntent.test.ets \
  entry/src/test/List.test.ets entry/src/main/ets/entryability/EntryAbility.ets \
  entry/src/main/ets/pages/Index.ets entry/src/main/ets/widget/pages/MoodWidgetCard.ets
git commit -m "fix: initialize local data before widget routing"
git push origin main
```

飞书追加“批次 5：冷启动与路由”，记录白名单、初始化顺序、提交哈希和测试结果；重新读取验证。

---

### Task 6: 让提醒开关与系统实际状态保持一致

**Files:**
- Create: `entry/src/main/ets/common/ReminderState.ets`
- Create: `entry/src/test/ReminderState.test.ets`
- Modify: `entry/src/test/List.test.ets`
- Modify: `entry/src/main/ets/common/ReminderManager.ets`
- Modify: `entry/src/main/ets/pages/Profile.ets`

**Interfaces:**
- Produces: `ReminderSettings`、`enabledReminderSettings(id: number, hour: number, minute: number): ReminderSettings`、`disabledReminderSettings(): ReminderSettings`、`publishDailyReminder(ctx: Context, hour: number, minute: number): Promise<number>`、`cancelDailyReminder(id: number): Promise<boolean>`。
- Consumes: PersistentStorage keys `isReminderOn`、`mood_reminder_id`、`reminderHour`、`reminderMinute`。

- [x] **Step 1: 写提醒状态失败测试**

```ts
import { describe, it, expect } from '@ohos/hypium';
import { enabledReminderSettings, disabledReminderSettings } from '../main/ets/common/ReminderState';

export default function reminderStateTest(): void {
  describe('ReminderState', () => {
    it('enablesOnlyWithPositivePublishedId', 0, () => {
      expect(enabledReminderSettings(-1, 20, 0).isOn).assertFalse();
      const enabled = enabledReminderSettings(42, 9, 30);
      expect(enabled.isOn).assertTrue();
      expect(enabled.id).assertEqual(42);
      expect(enabled.hour).assertEqual(9);
      expect(enabled.minute).assertEqual(30);
    });
    it('disablesWithClearedId', 0, () => {
      const disabled = disabledReminderSettings();
      expect(disabled.isOn).assertFalse();
      expect(disabled.id).assertEqual(-1);
    });
  });
}
```

注册测试并运行 unit test；Expected: FAIL，`ReminderState` 模块不存在。

- [x] **Step 2: 实现纯状态构造器与异步系统封装**

`ReminderManager` 不再读取或写入 AppStorage。`publishDailyReminder()` 发布成功返回正 ID，失败返回 `-1`；`cancelDailyReminder(id)` 在无有效 ID 时返回 `true`，系统回调无错误才返回 `true`。所有 Promise 在每条回调路径上只 resolve 一次。

- [x] **Step 3: 修复开启、取消和改时序**

`Profile` 增加 `@State reminderBusy`。关闭态把 Toggle 拨为开时，立即保持 `isReminderOn=false` 并打开时间选择器；用户取消不改变状态。用户确认时间后调用 `publishDailyReminder()`，只有正 ID 才一次性写入四个 PersistentStorage 字段并显示成功；失败保持关闭并 toast。

关闭已有提醒时，先调用 `cancelDailyReminder(currentId)`；成功才写入 `disabledReminderSettings()`，失败保持原 ID、时间与开启状态并 toast。编辑已开启提醒时间时，先发布新提醒，再取消旧提醒；取消旧提醒失败时尽力取消新提醒并保留旧状态，向用户提示未更改。

- [x] **Step 4: 运行单测、门禁与构建**

Run: `/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw --mode module -p product=default -p module=entry@default test --no-daemon`

Run: `node scripts/verify-offline.mjs && node scripts/verify-lightweight-scope.mjs`

Run: `/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw --mode module -p product=default -p module=entry@default assembleHap --no-daemon`

Expected: ReminderState tests PASS；静态门禁 PASS；正确工具链下构建 PASS。

- [x] **Step 5: 提交并同步批次**

```bash
git add entry/src/main/ets/common/ReminderState.ets entry/src/test/ReminderState.test.ets \
  entry/src/test/List.test.ets entry/src/main/ets/common/ReminderManager.ets \
  entry/src/main/ets/pages/Profile.ets
git commit -m "fix: keep reminder state transactional"
git push origin main
```

飞书追加“批次 6：本地提醒”，记录系统成功后才改状态的规则、提交哈希和验证结果；重新读取验证。

---

### Task 7: 发布前总验收与可复现记录

**Files:**
- Create: `docs/release/offline-release-checklist.md`
- Delete: `entry/src/test/LocalUnit.test.ets`
- Modify: `entry/src/test/List.test.ets`
- Modify: `entry/src/ohosTest/ets/test/Ability.test.ets`
- Modify: `entry/src/ohosTest/ets/test/List.test.ets`
- Modify: `docs/superpowers/plans/2026-09-10-offline-lightweight-mood-diary.md`

**Interfaces:**
- Consumes: Tasks 1–6 的所有门禁、单测、运行时代码和已同步提交。
- Produces: 可复核的发布检查清单、最终测试/构建证据和飞行模式人工验收记录。

- [x] **Step 1: 删除模板断言并确认测试注册完整**

删除 `LocalUnit.test.ets` 模板文件；本地 `List.test.ets` 只注册 MoodRecordPolicy、StatsViewModel、WidgetViewModel、LaunchIntent、ReminderState 五个真实套件。把 `ohosTest/ets/test/Ability.test.ets` 改为设备侧安全策略冒烟测试：调用 `parseLaunchIntent({ targetPage: 'pages/Profile' })` 并断言目标为空，再由其 `List.test.ets` 注册。运行 `rg -n "assertContain|let a = 'abc'" entry/src/test entry/src/ohosTest`，Expected: 无模板命中。

- [x] **Step 2: 执行全部自动验证**

```bash
node scripts/verify-offline.mjs
node scripts/verify-lightweight-scope.mjs
/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw --mode module \
  -p product=default -p module=entry@default test --no-daemon
/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw --mode module \
  -p product=default -p module=entry@default assembleHap --no-daemon
/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw --mode module \
  -p product=default -p module=entry@default -p buildMode=release assembleHap --no-daemon
```

Expected: 两个 Node 门禁 PASS；ArkTS unit test PASS；API 21 Debug 和 Release 构建 PASS。若当前机器缺 API 21，清单必须明确标为“环境阻塞”，不得用 API 26 结果代替。

- [x] **Step 3: 审计权限、远程残留和 Git 范围**

Run: `rg -n --glob '*.{ets,ts,js,mjs,json,json5}' "@ohos\\.net|@kit\\.NetworkKit|https?://|DIFY|DEEPSEEK|API_KEY|AuthManager|LoginPage|memberType|AIAgentChatPage" entry/src/main entry/build-profile.json5`

Expected: 无命中。

Run: `git status --short && git diff --check && git ls-files | rg "(^|/)\.DS_Store$|^AGENTS\.md$"`

Expected: `git diff --check` 无错误；最后一条无命中；只剩用户原有未跟踪文件。

- [ ] **Step 4: 在真机飞行模式下逐项验收**

`docs/release/offline-release-checklist.md` 记录设备型号、HarmonyOS 版本、构建提交和日期，并逐项勾选：首次启动欢迎页；新增记录；重启后数据存在；时间线/详情；编辑后日期不变；删除；当月统计与同日去重；主题/深色模式；提醒开启、取消选择、关闭、重启持久化；2×2 卡片展示与冷启动；设置页本地隐私/关于；系统权限页仅显示提醒与振动相关权限。

- [x] **Step 5: 回读规格并完成逐条覆盖审计**

对设计规范第 2、3、5–12、14、15 节逐项在检查清单中链接到测试、源码或人工证据。未验证项保持未勾选，不用“未发现问题”代替正向证据。将本计划已完成步骤的复选框改为 `[x]`。

- [x] **Step 6: 提交最终验收记录并同步**

```bash
git add docs/release/offline-release-checklist.md \
  docs/superpowers/plans/2026-09-10-offline-lightweight-mood-diary.md \
  entry/src/test/LocalUnit.test.ets entry/src/test/List.test.ets entry/src/ohosTest/ets/test
git commit -m "test: verify offline release readiness"
git push origin main
```

飞书追加“最终验收”，包含最终提交哈希、所有自动命令结果、真机飞行模式结果、权限清单和任何仍未通过项；重新读取“最终验收”章节验证。只有 GitHub 与飞书都包含最终提交，且规格成功定义的每一项都有正向证据时，才可声明方案 A 完成并可上架。

---

## 每批飞书同步约束

批次标题固定映射如下：

| Task | 飞书标题 |
|---|---|
| 1 | 批次 1：离线边界 |
| 2 | 批次 2：轻量化 |
| 3 | 批次 3：记录正确性 |
| 4 | 批次 4：统计口径 |
| 5 | 批次 5：冷启动与路由 |
| 6 | 批次 6：本地提醒 |
| 7 | 最终验收 |

每个批次只追加一次结构化 XML：一级内容由该批次的固定 `<h2>` 标题、一个绿色完成状态 `<callout>`、`<h3>实际修改</h3>`、`<h3>验证证据</h3>` 和 `<h3>剩余工作</h3>` 组成。完成状态必须写入 `git rev-parse HEAD` 返回的真实完整哈希以及 GitHub 推送结果；实际修改来自本批 Git diff；验证证据逐条写入刚执行的命令和真实结果；剩余工作写下一 Task 的固定标题，最终验收写“无”。禁止写入签名密码、访问令牌、API Key 或真实用户情绪内容。

同步前用 `lark-cli drive +search --query "MoodLite" --only-title --doc-types docx,wiki --sort edit_time --page-size 20 --format json --as user` 定位文档。选择经标题和现有项目章节核验的结果后，把其完整 URL 逐字保存到任务专用变量 `MOODLITE_FEISHU_DOC_URL`，把上表中的当前固定标题保存到 `MOODLITE_FEISHU_BATCH_TITLE`，并先运行 `test -n "$MOODLITE_FEISHU_DOC_URL" && test -n "$MOODLITE_FEISHU_BATCH_TITLE"`。更新命令固定为 `lark-cli docs +update --api-version v2 --doc "$MOODLITE_FEISHU_DOC_URL" --command append --content "$MOODLITE_FEISHU_BATCH_XML" --as user`，其中 `MOODLITE_FEISHU_BATCH_XML` 是按本段规则构造、只包含本批真实数据的完整字符串。更新后用 `lark-cli docs +fetch --api-version v2 --doc "$MOODLITE_FEISHU_DOC_URL" --scope keyword --keyword "$MOODLITE_FEISHU_BATCH_TITLE" --detail full --as user` 回读。若搜索返回多个候选，不得猜选。
