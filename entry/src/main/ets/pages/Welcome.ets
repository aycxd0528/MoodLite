/**
 * Welcome — v2.0 工业级玻璃拟态欢迎页
 */

import DataManager from '../data/DataManager';
import { Token, Dark, R, S, F } from '../common/styles';

@Entry
@Component
struct Welcome {
  @StorageLink('darkMode') darkMode: boolean = false;
  @State cardOpacity: number = 0;
  @State cardOffY: number = 40;
  @State btnOpacity: number = 0;
  @State btnOffY: number = 30;

  aboutToAppear(): void {
    this.getUIContext()?.animateTo({ duration: 600, curve: Curve.EaseOut }, () => {
      this.cardOpacity = 1;
      this.cardOffY = 0;
    });
    setTimeout(() => {
      this.getUIContext()?.animateTo({ duration: 500, curve: Curve.FastOutSlowIn }, () => {
        this.btnOpacity = 1;
        this.btnOffY = 0;
      });
    }, 350);
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // ====== 1. 渐变背景底层 ======
      Column()
        .width('100%').height('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: this.darkMode
            ? [[Dark.PINK_LIGHT, 0.0], [Dark.BG, 1.0]]
            : [['rgba(255,235,240,1)', 0.0], ['#FFF0F3', 0.5], [Token.PINK_LIGHT, 1.0]],
        })

      Column() {
        // ====== 2. 顶部文字区域 ======
        Column() {
          Text('欢迎使用')
            .fontSize(18)
            .fontColor(this.darkMode ? Dark.TEXT_HINT : Token.TEXT_HINT)
            .letterSpacing(2)
            .margin({ bottom: S.XS })
          Text('MoodLite')
            .fontSize(42)
            .fontWeight(FontWeight.Bold)
            .fontColor(Token.PINK)
            .letterSpacing(1)
        }
        .alignItems(HorizontalAlign.Center)
        .margin({ top: 80, bottom: 36 })

        // ====== 3. 玻璃拟态卡片 ======
        Column() {
          Text('记录每日情绪')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN)
            .margin({ top: S.XL, bottom: S.XS })

          Text('发现内心轨迹')
            .fontSize(14)
            .fontColor(this.darkMode ? Dark.TEXT_HINT : Token.TEXT_HINT)
            .margin({ bottom: 36 })

          Column() {
            Button('开始体验')
              .width('80%').height(50)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(Token.TEXT_WHITE)
              .backgroundColor(Token.PINK)
              .borderRadius(R.BUTTON)
              .shadow({ radius: 15, color: 'rgba(255,122,154,0.4)', offsetY: 8 })
              .onClick(() => {
                DataManager.markLaunched();
                this.getUIContext().getRouter().replaceUrl({ url: 'pages/MainPage' });
              })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .opacity(this.btnOpacity)
          .translate({ y: this.btnOffY })
          .margin({ bottom: 30 })
        }
        .width('85%')
        .backgroundColor(this.darkMode
          ? 'rgba(37,37,64,0.55)'
          : 'rgba(255,255,255,0.40)')
        .backdropBlur(40)
        .borderRadius(32)
        .border({
          width: 1,
          color: this.darkMode
            ? 'rgba(255,255,255,0.10)'
            : 'rgba(255,255,255,0.70)',
        })
        .shadow({
          radius: 40,
          color: this.darkMode
            ? 'rgba(0,0,0,0.25)'
            : 'rgba(0,0,0,0.05)',
          offsetY: 15,
        })
        .alignItems(HorizontalAlign.Center)
        .opacity(this.cardOpacity)
        .translate({ y: this.cardOffY })
      }
      .width('100%')
    }
    .width('100%').height('100%')
  }
}
