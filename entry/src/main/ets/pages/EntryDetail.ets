/**
 * EntryDetail — 记录详情页（深色模式适配）
 */

import router from '@ohos.router';
import { Token, Dark, Shadow, R, S, F } from '../common/styles';
import { GlassCard } from '../common/components/GlassCard';
import { getMoodIconResource, getMoodLabel } from '../model/MoodRecord';
import { setEditPayload } from '../common/EditBridge';

@Entry
@Component
struct EntryDetail {
  @StorageLink('darkMode') darkMode: boolean = false;
  @State recordId: string = '';
  @State dateStr: string = '';
  @State score: number = 0;
  @State text: string = '';

  aboutToAppear(): void {
    const p = router.getParams() as Record<string, string | number>;
    if (p) {
      this.recordId = (p['recordId'] as string) || '';
      this.dateStr = (p['recordDate'] as string) || '';
      this.score = (p['recordScore'] as number) || 0;
      this.text = (p['recordText'] as string) || '';
    }
  }

  onEdit(): void {
    setEditPayload({ id: this.recordId, text: this.text, score: this.score });
    router.replaceUrl({ url: 'pages/AddEntry', params: { fromTab: 1 } });
  }

  build() {
    Column() {
      Row() {
        Button() {
          Image($r('app.media.ic_back')).width(24).height(24).objectFit(ImageFit.Contain)
            .fillColor(this.darkMode ? '#E8E8EC' : '#1F2937')
            .colorFilter(
              this.darkMode
                ? [-1, 0, 0, 0, 255, 0, -1, 0, 0, 255, 0, 0, -1, 0, 255, 0, 0, 0, 1, 0]
                : [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0]
            )
        }
        .width(40).height(40).backgroundColor('transparent')
        .onClick(() => { router.back(); })

        Blank()

        Text('详情').fontSize(F.BODY).fontWeight(FontWeight.Medium)
          .fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN)

        Blank()

        Row({ space: 4 }) {
          Image($r('app.media.ic_edit')).width(14).height(14).fillColor(Token.TEXT_WHITE)
          Text('编辑').fontSize(14).fontWeight(FontWeight.Medium).fontColor(Token.TEXT_WHITE)
        }
        .padding({ left: 14, right: 14, top: 6, bottom: 6 })
        .backgroundColor(Token.PINK).borderRadius(16)
        .shadow({ radius: 30, color: this.darkMode ? Dark.SHADOW_COLOR : Token.SHADOW_COLOR, offsetY: 10 })
        .onClick(() => { this.onEdit(); })
      }
      .width('100%')
      .padding({ top: 32, bottom: S.XS, left: S.MD, right: S.MD })
      .alignItems(VerticalAlign.Center)

      Scroll() {
        Column() {
          GlassCard() {
            Column() {
              Row() {
                Image($r('app.media.ic_sparkles')).width(20).height(20).objectFit(ImageFit.Contain)
                  .opacity(0.6)
              }
              .width('100%').justifyContent(FlexAlign.End)

              Image(getMoodIconResource(this.score))
                .width(120).height(120).objectFit(ImageFit.Contain)
                .margin({ top: 10, bottom: 20 })

              Text(getMoodLabel(this.score))
                .fontSize(24).fontWeight(FontWeight.Bold)
                .fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN)

              Text(this.dateStr)
                .fontSize(14)
                .fontColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY)
                .margin({ top: 8, bottom: 30 })

              Column() {
                Text(this.text || '没有记录文字')
                  .fontSize(18)
                  .fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN)
                  .lineHeight(30).textAlign(TextAlign.Center)
              }
              .width('100%').padding({ left: 10, right: 10 })

              Row() {
                Image($r('app.media.ic_sparkles')).width(16).height(16).objectFit(ImageFit.Contain)
                  .opacity(0.4)
              }
              .width('100%').margin({ top: 40 })
            }
            .width('100%').alignItems(HorizontalAlign.Center).padding(24)
          }
        }
        .padding({ left: S.LG, right: S.LG })
      }
      .layoutWeight(1).scrollBar(BarState.Off)
    }
    .width('100%').height('100%')
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: this.darkMode
        ? [[Dark.PINK_LIGHT, 0.0], [Dark.BG, 1.0]]
        : [[Token.PINK_LIGHT, 0.0], [Token.TEXT_WHITE, 1.0]],
    })
  }
}
