# MoodLite 轻心记

> 一款专注情绪追踪与自我觉察的轻量级日记应用，主打低门槛记录与数据可视化。

基于 **HarmonyOS ArkUI (API 21)** + **ArkTS** 声明式框架构建，采用 Stage 模型，支持手机与桌面小组件双形态。

---

## 技术架构

| 层面 | 技术选型 |
|------|----------|
| 开发框架 | HarmonyOS ArkUI (声明式 ArkTS) |
| API 版本 | SDK 6.0.1 (API 21) |
| 应用模型 | Stage 模型 |
| 数据持久化 | `@ohos.data.preferences` (键值对) |
| 构建工具 | Hvigor 6.0.1 |
| 测试框架 | `@ohos/hypium` + `@ohos/hamock` |
| 小组件 | FormExtensionAbility (2×2 / 2×4) |

### 项目目录结构

```
MoodLite/
├── AppScope/                       # 应用级配置 (包名、图标、版本)
├── entry/                          # 主 HAP 模块
│   └── src/main/
│       ├── ets/
│       │   ├── common/             # 全局共享
│       │   │   ├── styles.ets      #   设计 Token 系统
│       │   │   ├── components/
│       │   │   │   └── GlassCard.ets  #   玻璃拟态卡片组件
│       │   │   ├── utils/
│       │   │   │   ├── AiAgentClient.ets       #   AI 对话客户端
│       │   │   │   └── WidgetSyncManager.ets   #   小组件同步
│       │   │   ├── EditBridge.ets          #   跨页面编辑数据桥
│       │   │   └── ReminderManager.ets     #   提醒开关管理
│       │   ├── data/
│       │   │   └── DataManager.ets         # 数据持久层 (单例)
│       │   ├── model/
│       │   │   ├── MoodRecord.ets          # 核心数据模型
│       │   │   └── Achievement.ets         # 成就定义
│       │   ├── viewmodel/
│       │   │   ├── StatsViewModel.ets      # 统计计算引擎
│       │   │   ├── AchievementChecker.ets  # 成就判定引擎
│       │   │   └── LazyDataSource.ets      # 懒加载数据源
│       │   ├── pages/                      # 页面层
│       │   │   ├── Index.ets               #   启动页
│       │   │   ├── Welcome.ets             #   引导页
│       │   │   ├── MainPage.ets            #   主框架 (5 Tab)
│       │   │   ├── HomeTab.ets             #   今日 Tab
│       │   │   ├── TimelineTab.ets         #   时间线 Tab
│       │   │   ├── Stats.ets               #   统计 Tab
│       │   │   ├── Profile.ets             #   我的 Tab
│       │   │   ├── AddEntry.ets            #   记录/编辑页
│       │   │   └── EntryDetail.ets         #   记录详情页
│       │   ├── entryability/               # UIAbility 入口
│       │   ├── entryformability/           # 小组件 FormAbility
│       │   └── widget/ + widget1/          # 桌面小组件
│       └── resources/              # 资源文件 (颜色、字符串、图标)
├── hvigor/                         # 构建配置
└── build-profile.json5             # 签名与产品配置
```

---

## 核心功能

### 1. 情绪记录

- **五级情绪滑块**：使用可视化渐变滑块选择情绪值 (-2 ~ +2)，配合 3D 表情图标即时反馈
- **标签系统**：内置 6 个默认标签（工作、社交、独处、运动、休息、阅读），支持自定义添加
- **文本记录**：无边框 TextArea，自由书写当日感受
- **编辑与删除**：支持从记录详情页进入编辑模式，或删除已有记录（带确认弹窗）
- **振动反馈**：滑动滑块时触发振动，增强操作手感

### 2. 时间线

- **按月分组**：记录按天聚合，每天显示情绪摘要与颜色标识
- **月份导航**：左右箭头切换月份，实时展示当月记录
- **玻璃拟态卡片**：每日记录组以毛玻璃卡片呈现，点击可查看详情

### 3. 数据统计

- **月历热力图**：7×6 网格渲染整月情绪分布，5 级颜色深浅映射情绪强度，支持明暗双主题
- **情绪概览**：四个统计卡片展示愉悦/平静/低落占比与记录天数
- **标签分布**：按标签使用频次排序的横向柱状图，柱体颜色关联该标签下的平均情绪
- **连续记录**：实时计算最长连续记录天数

### 4. 成就系统

内置 7 种成就，分为三类，首次触发时自动弹窗解锁：

| 成就 | 类别 | 解锁条件 |
|------|------|----------|
| 初识自我 | 习惯养成 | 完成第 1 条记录 |
| 拾级而上 | 习惯养成 | 连续 7 天不间断记录 |
| 岁月痕迹 | 习惯养成 | 累计 30 条记录 |
| 调色板 | 情绪觉察 | 一周内体验 4 种不同情绪 |
| 情绪解码器 | 情绪觉察 | 单条记录使用 3+ 标签并附文本 |
| 雨过天晴 | 情绪转化 | 48 小时内从低落到愉悦 |
| 波澜不惊 | 情绪转化 | 连续 5 天保持非负面情绪 |

### 5. AI 智能助手

- 负面情绪（score < 0）记录保存后，异步调用 Dify AI 工作流
- 返回个性化建议弹窗展示在首页，帮助用户调节情绪
- 非阻塞式调用，不影响记录保存流程

### 6. 桌面小组件

| 尺寸 | 功能 |
|------|------|
| 2×2 | 显示表情图标 + App 名称，点击跳转至记录页 |
| 2×4 | 显示当月情绪热力图，点击跳转至统计页 |

- 每次数据变更后自动同步更新所有已注册小组件
- 支持明暗双主题跟随

---

## 设计系统

### 色彩

| 用途 | 色值 | 说明 |
|------|------|------|
| 全局背景 | `#F7F8FA` | 浅灰白底色 |
| 品牌主色 / 愉悦 | `#FF8BA7` | 蜜桃粉 |
| 低落情绪 | `#AEC6CF` | 雾霾蓝 |
| 平静 | `#F5C542` | 暖金色 |
| 主文本 | `#1F2937` | 深灰 |
| 次文本 | `#9CA3AF` | 浅灰 |
| 深色背景 | `#1A1A2E` | 深邃藏蓝 |
| 深色卡片 | `#252540` | 暗色卡片面 |
| 顶部渐变 | `#FFE5EC → transparent` | 粉色呼吸渐变 |

### 玻璃拟态卡片 (Glassmorphism)

所有内容容器统一使用 `GlassCard` 组件：

- 纯白背景（深色模式：`#252540`）
- 大圆角 `24vp`
- `0.5px` 极细描边
- 极弱弥散投影（`radius: 30, offsetY: 10, 透明度 0.03`）
- **严格禁止**浓重发光边缘或粗边框

### 字体与间距

| 层级 | 字号 | 用途 |
|------|------|------|
| TITLE | 28fp | 页面标题 |
| SUBTITLE | 24fp | 卡片标题 |
| BODY | 16fp | 正文 |
| CAPTION | 14fp | 辅助说明 |
| SMALL | 12fp | 标签、日期 |
| TINY | 10fp | 统计微注 |

间距基于 8vp 网格：`XS(8)` `SM(12)` `MD(16)` `LG(24)` `XL(32)`

---

## 页面路由

| 路由路径 | 页面 | 说明 |
|----------|------|------|
| `pages/Index` | Index | 启动页，三态加载 (LOADING/EMPTY/SUCCESS)，检查首次启动 |
| `pages/Welcome` | Welcome | 引导页，玻璃拟态卡片 + 动画入场 |
| `pages/MainPage` | MainPage | 主框架，底部 5 Tab 悬浮胶囊导航 |
| `pages/AddEntry` | AddEntry | 情绪记录/编辑页 |
| `pages/EntryDetail` | EntryDetail | 记录详情页，支持编辑和删除 |
| `pages/Profile` | Profile | 设置页，暗色模式、提醒、反馈 |

**导航方式**：`router.pushUrl`（前进）、`router.replaceUrl`（重定向）、`router.back()`（返回）

---

## 数据模型

### MoodRecord（核心记录）

```typescript
interface MoodRecord {
  id: string;          // UUID 主键
  timestamp: number;   // 毫秒时间戳（排序依据）
  dateStr: string;     // YYYY-MM-DD 格式日期（聚合索引）
  score: number;       // 情绪净值 (-2 ~ +2)
  text: string;        // 用户文本内容
  images: string[];    // 本地沙盒图片路径
  location: string;    // 结构化位置信息
  tags: string[];      // 情绪标签
}
```

### 视图模型

- **CalendarDayItem**：单日聚合数据，用于热力图网格渲染
- **MonthlyStats**：月度汇总（各类情绪占比、平均/最高/最低分、记录天数）

---

## 数据持久化

### DataManager 单例

- 基于 `@ohos.data.preferences` 的键值存储（库名：`moodlite_db`）
- 存储 Key：`records` (JSON 数组)、`first_launch` (boolean)、`unlocked_achievements` (JSON Map)
- **串行写队列**：所有写操作排队执行，防止并发竞态
- **写后钩子**：每次 `saveRecord()` 后自动执行成就检测 + 小组件同步刷新
- **初始化保护**：使用共享 `initPromise` 防止重复初始化
- 全局单例，通过 `DataManager.init(context)` 初始化后，所有页面通过实例方法访问

### 跨页面通信

- **AppStorage**：暗色模式、提醒状态、AI 意图、Tab 切换等全局状态
- **EditBridge**：从详情页到编辑页的内存数据桥接（只读一次模式）

---

## 构建与运行

### 环境要求

- **DevEco Studio** (SDK 6.0.1+)
- **HarmonyOS NEXT** API 21+

### 构建命令

```bash
# 安装依赖
ohpm install

# 调试构建
hvigorw assembleHap --mode module -p product=default

# 发布构建
hvigorw assembleHap --mode module -p product=default -p buildMode=release
```

### 签名配置

签名配置位于 `build-profile.json5`，使用 ECDSA (SHA256withECDSA) 证书。调试与发布分别配置独立的 `.p12` 密钥文件和 `.cer` 证书文件。

### 权限声明

| 权限 | 用途 |
|------|------|
| `ohos.permission.INTERNET` | AI 助手 API 调用 |
| `ohos.permission.VIBRATE` | 情绪滑块触觉反馈 |
| `ohos.permission.PUBLISH_AGENT_REMINDER` | 定时记录提醒 |

---

## License

This project is for learning and personal use.
