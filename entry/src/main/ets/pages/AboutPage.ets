/**
 * AboutPage — 本地应用说明
 */

import { GlassCard } from '../common/components/GlassCard';
import { F, R, S } from '../common/styles';
import { resolveColors } from '../common/ThemeManager';
import { syncSystemBars } from '../common/SystemBarManager';

@Entry
@Component
struct AboutPage {
  @StorageLink('darkMode') darkMode: boolean = false;
  @StorageLink('currentTheme') currentTheme: string = 'blossomPink';

  aboutToAppear(): void {
    syncSystemBars(this.getUIContext().getHostContext(), this.darkMode);
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      Column()
        .width('100%')
        .height('35%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [
            [resolveColors(this.darkMode, this.currentTheme).PINK_LIGHT, 0.0],
            [resolveColors(this.darkMode, this.currentTheme).BG, 1.0],
          ],
        })

      Column() {
        Stack({ alignContent: Alignment.Center }) {
          Text('关于 MoodLite')
            .fontSize(F.BODY)
            .fontWeight(FontWeight.Medium)
            .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_MAIN)

          Row() {
            Image($r('app.media.ic_back'))
              .width(24).height(24).objectFit(ImageFit.Contain)
              .fillColor(resolveColors(this.darkMode, this.currentTheme).TEXT_MAIN)
              .onClick(() => { this.getUIContext().getRouter().back(); })
            Blank()
          }
          .width('100%')
        }
        .width('100%')
        .padding({ top: S.HEADER_TOP, bottom: S.MD, left: S.LG, right: S.LG })

        Scroll() {
          Column({ space: S.MD }) {
            GlassCard() {
              Column({ space: S.SM }) {
                Image($r('app.media.app_icon'))
                  .width(88).height(88).objectFit(ImageFit.Contain)
                  .borderRadius(R.SMALL)
                Text('MoodLite 轻心记')
                  .fontSize(F.TITLE).fontWeight(FontWeight.Bold)
                  .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_MAIN)
                Text('版本 1.0.0')
                  .fontSize(F.CAPTION)
                  .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_GRAY)
              }
              .width('100%').alignItems(HorizontalAlign.Center)
            }

            GlassCard() {
              Column({ space: S.SM }) {
                Text('轻一点记录，更清楚地看见自己')
                  .fontSize(F.SUBTITLE).fontWeight(FontWeight.Bold)
                  .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_MAIN)
                Text('MoodLite 专注于低门槛的情绪记录与月度回顾，帮助你在日常里留下一点自我觉察。')
                  .fontSize(F.BODY).lineHeight(26)
                  .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_GRAY)
                Text('应用完全离线运行，无需登录。你的记录不会离开这台设备。')
                  .fontSize(F.BODY).lineHeight(26)
                  .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_MAIN)
                  .padding(S.SM)
                  .backgroundColor(resolveColors(this.darkMode, this.currentTheme).PINK_LIGHT)
                  .borderRadius(R.SMALL)
              }
              .width('100%').alignItems(HorizontalAlign.Start)
            }

            Row().height(S.BOTTOM_BREATH)
          }
          .padding({ left: S.LG, right: S.LG })
        }
        .layoutWeight(1).scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring)
      }
      .width('100%').height('100%')
    }
    .width('100%').height('100%')
    .backgroundColor(resolveColors(this.darkMode, this.currentTheme).BG)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
