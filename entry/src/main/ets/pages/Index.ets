/**
 * Index — v2.0 启动入口（三态加载 + 超时熔断）
 *
 * LOADING  → 初始化中，展示 App Icon + 文字
 * SUCCESS  → 自动跳转 Welcome / MainPage
 * EMPTY    → 兜底态，展示欢迎入口防止永久白屏
 */

import DataManager from '../data/DataManager';
import { Token, S, F } from '../common/styles';
import { resolveColors } from '../common/ThemeManager';
import {
  LaunchIntent,
  LaunchParameters,
  PENDING_TAB_KEY,
  PENDING_TARGET_KEY,
  parseLaunchIntent,
} from '../common/LaunchIntent';

// 全局持久化状态初始化（应在应用入口最早执行）
PersistentStorage.persistProp('isReminderOn', false);
PersistentStorage.persistProp('reminderHour', 20);
PersistentStorage.persistProp('reminderMinute', 0);
PersistentStorage.persistProp('mood_reminder_id', -1);
PersistentStorage.persistProp('darkMode', false);
PersistentStorage.persistProp('currentTheme', 'blossomPink');

type LoadStatus = 'LOADING' | 'EMPTY' | 'SUCCESS';

@Entry
@Component
struct Index {
  @StorageProp('darkMode') darkMode: boolean = false;
  @StorageLink('currentTheme') currentTheme: string = 'blossomPink';
  @State status: LoadStatus = 'LOADING';
  @State statusMsg: string = '正在初始化...';
  private timeoutId: number = -1;
  private attemptId: number = 0;

  aboutToAppear(): void {
    console.info('[MoodLite] Index.aboutToAppear — begin');
    this.initialize();
  }

  private initialize(): void {
    this.clearTimer();
    const attempt: number = ++this.attemptId;
    this.status = 'LOADING';
    this.statusMsg = '正在初始化...';
    try {
      const uiCtx: UIContext = this.getUIContext();
      const hostCtx: Context | undefined = uiCtx.getHostContext();
      if (!hostCtx) {
        this.status = 'EMPTY';
        this.statusMsg = '无法获取应用上下文';
        return;
      }
      const ctx: Context = hostCtx;
      console.info('[MoodLite] Index — context acquired');

      // 3 秒超时熔断 —— 防止异步链静默挂起
      const TIMEOUT_MS = 3000;
      this.timeoutId = setTimeout(() => {
        if (attempt === this.attemptId && this.status === 'LOADING') {
          console.warn('[MoodLite] Index init TIMEOUT — forcing EMPTY fallback');
          this.timeoutId = -1;
          this.status = 'EMPTY';
          this.statusMsg = '加载超时，请重试';
        }
      }, TIMEOUT_MS);

      DataManager.init(ctx)
        .then(() => {
          console.info('[MoodLite] Index — init resolved, checking first launch...');
          return DataManager.isFirstLaunch();
        })
        .then((first: boolean) => {
          if (attempt !== this.attemptId || this.status !== 'LOADING') return;
          this.clearTimer();
          this.status = 'SUCCESS';
          console.info('[MoodLite] Index — firstLaunch=' + String(first) + ', navigating...');
          this.navigateAfterInit(first);
        })
        .catch((err: Object) => {
          if (attempt !== this.attemptId || this.status !== 'LOADING') return;
          this.clearTimer();
          console.error('[MoodLite] Index init FAILED: ' + JSON.stringify(err));
          this.status = 'EMPTY';
          this.statusMsg = '初始化失败，请重试';
        });
    } catch (syncErr) {
      if (attempt !== this.attemptId) return;
      this.clearTimer();
      console.error('[MoodLite] Index aboutToAppear SYNC error: ' + JSON.stringify(syncErr));
      this.status = 'EMPTY';
      this.statusMsg = '启动异常，请重试';
    }
  }

  aboutToDisappear(): void {
    this.attemptId++;
    this.clearTimer();
  }

  private clearTimer(): void {
    if (this.timeoutId !== -1) {
      clearTimeout(this.timeoutId);
      this.timeoutId = -1;
    }
  }

  private consumeLaunchIntent(): LaunchIntent {
    const target: string | undefined = AppStorage.get(PENDING_TARGET_KEY) as string | undefined;
    const tab: number | undefined = AppStorage.get(PENDING_TAB_KEY) as number | undefined;
    AppStorage.delete(PENDING_TARGET_KEY);
    AppStorage.delete(PENDING_TAB_KEY);
    const params: LaunchParameters = {};
    if (typeof target === 'string') params.targetPage = target;
    if (typeof tab === 'number') params.tab = tab;
    return parseLaunchIntent(params);
  }

  private navigateAfterInit(first: boolean): void {
    const intent: LaunchIntent = this.consumeLaunchIntent();
    try {
      const uiRouter = this.getUIContext().getRouter();
      if (first) {
        uiRouter.replaceUrl({ url: 'pages/Welcome' }).catch((err: Error) => {
          this.handleNavigationFailure(err);
        });
        return;
      }
      if (intent.targetPage === 'pages/AddEntry') {
        uiRouter.replaceUrl({
          url: 'pages/AddEntry',
          params: { fromTab: intent.tab === null ? 0 : intent.tab },
        }).catch((err: Error) => {
          this.handleNavigationFailure(err);
        });
        return;
      }
      if (intent.tab !== null) {
        AppStorage.setOrCreate('moodlite_tab', intent.tab);
      }
      uiRouter.replaceUrl({ url: 'pages/MainPage' }).catch((err: Error) => {
        this.handleNavigationFailure(err);
      });
    } catch (err) {
      this.handleNavigationFailure(err as Object);
    }
  }

  private handleNavigationFailure(err: Object): void {
    console.error('[MoodLite] Navigation failed: ' + JSON.stringify(err));
    this.status = 'EMPTY';
    this.statusMsg = '页面打开失败，请重试';
  }

  build() {
    Column() {
      // ====== 顶部标题区（始终可见） ======
      Column() {
        Text('MoodLite')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(resolveColors(this.darkMode, this.currentTheme).PINK)
        Text('轻心记')
          .fontSize(14)
          .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_GRAY)
          .margin({ top: S.XS })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .padding({ top: 120 })

      // ====== 核心状态区 ======
      Column() {
        if (this.status === 'LOADING') {
          // 加载态 —— 仅使用确定存在的组件，避免运行时崩溃
          Image($r('app.media.app_icon'))
            .width(80).height(80)
            .objectFit(ImageFit.Contain)
            .opacity(0.6)
          Text(this.statusMsg)
            .fontSize(F.CAPTION)
            .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_GRAY)
            .margin({ top: S.MD })
        } else if (this.status === 'EMPTY') {
          // 兜底态 —— 即使数据为空，入口按钮必须可点
          Image($r('app.media.img_home_cloud'))
            .width(120).height(120)
            .objectFit(ImageFit.Contain)
            .opacity(0.8)
            .margin({ bottom: S.MD })
          Text(this.statusMsg)
            .fontSize(F.BODY)
            .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_MAIN)
            .margin({ bottom: S.XS })
          Text('本地数据尚未准备完成')
            .fontSize(F.CAPTION)
            .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_GRAY)
            .margin({ top: S.XS, bottom: S.LG })

          Button('重试')
            .width(180).height(48)
            .backgroundColor(resolveColors(this.darkMode, this.currentTheme).PINK)
            .borderRadius(24)
            .fontSize(F.BODY)
            .fontWeight(FontWeight.Medium)
            .fontColor(resolveColors(this.darkMode, this.currentTheme).BTN_TEXT)
            .shadow({ radius: 12, color: 'rgba(255,139,167,0.35)', offsetY: 6 })
            .onClick(() => {
              console.info('[MoodLite] Index EMPTY — retry initialization');
              this.initialize();
            })
        }
      }
      .layoutWeight(1)
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      // ====== 底部提示（始终可见） ======
      Text('每一次记录 都是你关心自己的方式')
        .fontSize(F.SMALL)
        .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_GRAY)
        .textAlign(TextAlign.Center)
        .padding({ bottom: S.XL, left: S.LG, right: S.LG })
    }
    .width('100%').height('100%')
    .backgroundColor(resolveColors(this.darkMode, this.currentTheme).BG)
  }
}
