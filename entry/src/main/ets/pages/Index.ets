/**
 * Index — v2.0 启动入口（三态加载 + 超时熔断）
 *
 * LOADING  → 初始化中，展示 App Icon + 文字
 * SUCCESS  → 自动跳转 Welcome / MainPage
 * EMPTY    → 兜底态，展示欢迎入口防止永久白屏
 */

import router from '@ohos.router';
import DataManager from '../data/DataManager';
import { Token, Dark, S, F } from '../common/styles';

type LoadStatus = 'LOADING' | 'EMPTY' | 'SUCCESS';

@Entry
@Component
struct Index {
  @StorageProp('darkMode') darkMode: boolean = false;
  @State status: LoadStatus = 'LOADING';
  @State statusMsg: string = '正在初始化...';
  private timeoutId: number = -1;

  aboutToAppear(): void {
    console.info('[MoodLite] Index.aboutToAppear — begin');
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
        if (this.status === 'LOADING') {
          console.warn('[MoodLite] Index init TIMEOUT — forcing EMPTY fallback');
          this.status = 'EMPTY';
          this.statusMsg = '加载超时，请退出重试';
        }
      }, TIMEOUT_MS);

      DataManager.init(ctx)
        .then(() => {
          console.info('[MoodLite] Index — init resolved, checking first launch...');
          return DataManager.isFirstLaunch();
        })
        .then((first: boolean) => {
          clearTimeout(this.timeoutId);
          this.timeoutId = -1;
          this.status = 'SUCCESS';
          console.info('[MoodLite] Index — firstLaunch=' + String(first) + ', navigating...');
          const target = first ? 'pages/Welcome' : 'pages/MainPage';
          router.replaceUrl({ url: target });
        })
        .catch((err: Object) => {
          clearTimeout(this.timeoutId);
          this.timeoutId = -1;
          console.error('[MoodLite] Index init FAILED: ' + JSON.stringify(err));
          this.status = 'EMPTY';
          this.statusMsg = '初始化失败，请退出重试';
        });
    } catch (syncErr) {
      console.error('[MoodLite] Index aboutToAppear SYNC error: ' + JSON.stringify(syncErr));
      this.status = 'EMPTY';
      this.statusMsg = '启动异常，请退出重试';
    }
  }

  aboutToDisappear(): void {
    if (this.timeoutId !== -1) {
      clearTimeout(this.timeoutId);
      this.timeoutId = -1;
    }
  }

  build() {
    Column() {
      // ====== 顶部标题区（始终可见） ======
      Column() {
        Text('MoodLite')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(Token.PINK)
        Text('轻心记')
          .fontSize(14)
          .fontColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY)
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
            .fontColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY)
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
            .fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN)
            .margin({ bottom: S.XS })
          Text('开始记录第一条心情吧')
            .fontSize(F.CAPTION)
            .fontColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY)
            .margin({ top: S.XS, bottom: S.LG })

          Button('开始记录')
            .width(180).height(48)
            .backgroundColor(Token.PINK)
            .borderRadius(24)
            .fontSize(F.BODY)
            .fontWeight(FontWeight.Medium)
            .fontColor(Token.TEXT_WHITE)
            .shadow({ radius: 12, color: 'rgba(255,139,167,0.35)', offsetY: 6 })
            .onClick(() => {
              console.info('[MoodLite] Index EMPTY — manual navigation to MainPage');
              router.replaceUrl({ url: 'pages/MainPage' });
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
        .fontColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY)
        .textAlign(TextAlign.Center)
        .padding({ bottom: S.XL, left: S.LG, right: S.LG })
    }
    .width('100%').height('100%')
    .backgroundColor(this.darkMode ? Dark.BG : Token.BG)
  }
}
