/**
 * HomeTab — 今日首页
 * 展示今日心情摘要 / 欢迎引导 / AI 建议胶囊
 */

import router from '@ohos.router';
import curves from '@ohos.curves';
import { Token, Dark, Shadow, R, S, F } from '../common/styles';
import { GlassCard } from '../common/components/GlassCard';
import { MoodRecord, getMoodEmoji, getMoodIconResource, getMoodLabel, formatDateStr } from '../model/MoodRecord';
import { AiSuggestion } from '../common/utils/AiAgentClient';

@Component
export struct HomeTab {
  @Prop @Watch('onRecordsChange') records: MoodRecord[] = [];
  @StorageLink('activeIntent') activeIntent: string | null = null;
  @StorageLink('darkMode') darkMode: boolean = false;
  @State emoji: string = '😐';
  @State label: string = '';
  @State score: number = 0;
  @State comfort: string = '';
  @State capsuleOpacity: number = 0;
  @State capsuleOffY: number = 20;

  aboutToAppear(): void {
    this.updateMoodState();
    this.animateCapsule();
  }

  onRecordsChange(): void {
    this.updateMoodState();
    this.animateCapsule();
  }

  private updateMoodState(): void {
    if (this.records.length === 0) {
      this.emoji = '😐'; this.label = '还没有记录'; this.score = 0;
      this.comfort = '写下今天的第一条心情吧 🌱'; return;
    }
    const r = this.records[0];
    this.emoji = getMoodEmoji(r.score);
    this.label = getMoodLabel(r.score);
    this.score = r.score;
    if (r.score >= 1) this.comfort = '心情不错！把这份快乐传递给身边的人吧 ✨';
    else if (r.score <= -1) this.comfort = '看起来今天有些疲惫，给你一个温暖的拥抱，好好休息一下吧 ☁️';
    else this.comfort = '平平淡淡也是一种难得的幸福 🍵';
  }

  private isTodayRecorded(): boolean {
    if (this.records.length === 0) return false;
    const today = formatDateStr(new Date());
    return this.records[0].dateStr === today;
  }

  private parseActiveIntent(): AiSuggestion | null {
    if (!this.activeIntent) return null;
    try {
      const obj = JSON.parse(this.activeIntent) as AiSuggestion;
      const today = formatDateStr(new Date());
      if (obj.dateStr !== today) return null;
      return obj;
    } catch (_e) {
      return null;
    }
  }

  private animateCapsule(): void {
    const intent = this.parseActiveIntent();
    if (intent) {
      animateTo({ curve: curves.springMotion(0.4, 0.6) }, () => {
        this.capsuleOpacity = 1;
        this.capsuleOffY = 0;
      });
    } else {
      this.capsuleOpacity = 0;
      this.capsuleOffY = 20;
    }
  }

  build() {
    Column() {
      Column() {
        Row({ space: 8 }) {
          Text(this.isTodayRecorded() ? '今日心情' : '今天过得怎么样？')
            .fontSize(F.TITLE).fontWeight(FontWeight.Bold).fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN)
          Image($r('app.media.ic_sparkles'))
            .width(22).height(22).objectFit(ImageFit.Contain)
        }
        Text('记录情绪，了解自己。')
          .fontSize(14).fontColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY).margin({ top: 6 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ top: S.HEADER_TOP, bottom: 24, left: 24, right: 24 })

      Column({ space: S.MD }) {
        if (this.isTodayRecorded()) {
          GlassCard() {
            Column({ space: S.MD }) {
              Image(getMoodIconResource(this.score))
                .width(120).height(120).objectFit(ImageFit.Contain)
              Text(this.label).fontSize(22).fontWeight(FontWeight.Bold)
                .fontColor(this.score >= 1 ? Token.PINK : this.score <= -1 ? Token.BLUE : Token.TEXT_GRAY)
              Text(this.comfort)
                .fontSize(14).fontColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY)
                .textAlign(TextAlign.Center).lineHeight(22)
            }
            .width('100%').alignItems(HorizontalAlign.Center)
            .padding({ top: 28, bottom: 28, left: 20, right: 20 })
          }

          if (this.parseActiveIntent()) {
            Column() {
              GlassCard() {
                Row({ space: S.SM }) {
                  Text('💡').fontSize(18)
                  Column({ space: 4 }) {
                    Text('AI 温暖提示').fontSize(F.SMALL).fontWeight(FontWeight.Bold)
                      .fontColor(Token.PINK)
                    Text(this.parseActiveIntent()?.suggestion || '')
                      .fontSize(F.CAPTION).fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN)
                      .maxLines(3).textOverflow({ overflow: TextOverflow.Ellipsis })
                  }.layoutWeight(1)
                }
                .width('100%').alignItems(VerticalAlign.Top)
              }
            }
            .width('100%')
            .opacity(this.capsuleOpacity)
            .translate({ y: this.capsuleOffY })
          }
        } else {
          GlassCard() {
            Column() {
              Image($r('app.media.img_home_cloud'))
                .width(180).height(130).objectFit(ImageFit.Contain)
                .margin({ bottom: 16 })

              Row({ space: 8 }) {
                Text('欢迎回来').fontSize(22).fontWeight(FontWeight.Bold).fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN)
                Image($r('app.media.ic_smiling_hearts')).width(24).height(24).objectFit(ImageFit.Contain)
              }
              .justifyContent(FlexAlign.Center)

              Text('每一次记录\n都是你关心自己的方式')
                .fontSize(14).fontColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY)
                .textAlign(TextAlign.Center).lineHeight(22)
                .margin({ top: 16, bottom: 50 })

              Column({ space: 16 }) {
                Row({ space: 4 }) {
                  Image($r('app.media.ic_sparkles')).width(14).height(14).objectFit(ImageFit.Contain)
                  Text('坚持记录可以帮助你更好地理解自己的情绪模式。')
                    .fontSize(11)
                    .fontColor(this.darkMode ? Dark.INFO_TIP : Token.INFO_TIP)
                    .maxLines(1)
                }
                .width('100%').justifyContent(FlexAlign.Center)
                .padding({ top: 10, bottom: 10 })
                .backgroundColor(this.darkMode ? Dark.BUBBLE_BG : Token.BUBBLE_BG).borderRadius(R.TINY)

                Button('开始记录今天的心情')
                  .width('100%').height(48)
                  .backgroundColor(Token.PINK).borderRadius(24)
                  .fontSize(16).fontWeight(FontWeight.Medium).fontColor(Token.TEXT_WHITE)
                  .shadow(Shadow.CARD)
                  .onClick(() => {
                    router.pushUrl({ url: 'pages/AddEntry', params: { fromTab: 0 } });
                  })
              }
              .width('100%')
            }
            .width('100%')
            .padding({ top: 24, bottom: 24, left: 20, right: 20 })
          }
        }
      }
      .width('100%').padding({ left: 24, right: 24 })
    }
    .width('100%').height('100%')
  }
}
