/**
 * HomeTab — 今日首页
 * 展示今日心情摘要、固定本地关怀文案和记录入口。
 */

import { Shadow, S, F } from '../common/styles';
import { resolveColors } from '../common/ThemeManager';
import { GlassCard } from '../common/components/GlassCard';
import { MoodRecord, getMoodIconResource, getMoodLabel, formatDateStr } from '../model/MoodRecord';

@Component
export struct HomeTab {
  @Prop @Watch('onRecordsChange') records: MoodRecord[] = [];
  @StorageLink('darkMode') darkMode: boolean = false;
  @StorageLink('currentTheme') currentTheme: string = 'blossomPink';
  @State label: string = '';
  @State score: number = 0;
  @State comfort: string = '';

  aboutToAppear(): void {
    this.updateMoodState();
  }

  onRecordsChange(): void {
    this.updateMoodState();
  }

  private todayRecord(): MoodRecord | null {
    const today = formatDateStr(new Date());
    return this.records.find((record: MoodRecord) => record.dateStr === today) || null;
  }

  private updateMoodState(): void {
    const record = this.todayRecord();
    if (!record) {
      this.label = '还没有记录';
      this.score = 0;
      this.comfort = '写下今天的第一条心情吧 🌱';
      return;
    }
    this.label = getMoodLabel(record.score);
    this.score = record.score;
    if (record.score >= 1) {
      this.comfort = '心情不错！把这份快乐传递给身边的人吧 ✨';
    } else if (record.score <= -1) {
      this.comfort = '看起来今天有些疲惫，给自己一个温暖的拥抱，好好休息一下吧 ☁️';
    } else {
      this.comfort = '平平淡淡也是一种难得的幸福 🍵';
    }
  }

  private isTodayRecorded(): boolean {
    return this.todayRecord() !== null;
  }

  build() {
    Column() {
      Row({ space: S.XS }) {
        Text(this.isTodayRecorded() ? '今日心情' : '今天过得怎么样？')
          .fontSize(F.TITLE).fontWeight(FontWeight.Bold)
          .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_MAIN)
        Image($r('app.media.ic_sparkles'))
          .width(22).height(22).objectFit(ImageFit.Contain)
      }
      .width('100%').alignItems(VerticalAlign.Center)
      .padding({ top: S.HEADER_TOP, bottom: S.LG, left: S.LG, right: S.LG })

      Scroll() {
        Column({ space: S.MD }) {
          if (this.isTodayRecorded()) {
            GlassCard() {
              Column({ space: S.MD }) {
                Image(getMoodIconResource(this.score))
                  .width(120).height(120).objectFit(ImageFit.Contain)
                Text(this.label)
                  .fontSize(F.SUBTITLE).fontWeight(FontWeight.Bold)
                  .fontColor(this.score >= 1
                    ? resolveColors(this.darkMode, this.currentTheme).PINK
                    : this.score <= -1
                      ? resolveColors(this.darkMode, this.currentTheme).BLUE
                      : resolveColors(this.darkMode, this.currentTheme).TEXT_GRAY)
                Text(this.comfort)
                  .fontSize(F.CAPTION).lineHeight(22).textAlign(TextAlign.Center)
                  .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_GRAY)
              }
              .width('100%').alignItems(HorizontalAlign.Center)
              .padding({ top: S.SM, bottom: S.SM })
            }

            Button('再记一笔')
              .width('100%').height(48)
              .backgroundColor(resolveColors(this.darkMode, this.currentTheme).PINK)
              .borderRadius(24)
              .fontSize(F.BODY).fontWeight(FontWeight.Medium)
              .fontColor(resolveColors(this.darkMode, this.currentTheme).BTN_TEXT)
              .shadow(Shadow.CARD)
              .onClick(() => {
                this.getUIContext().getRouter().pushUrl({ url: 'pages/AddEntry', params: { fromTab: 0 } });
              })
          } else {
            GlassCard() {
              Column() {
                Image($r('app.media.img_home_cloud'))
                  .width(180).height(130).objectFit(ImageFit.Contain)
                  .margin({ bottom: S.MD })
                Text('欢迎回来')
                  .fontSize(F.SUBTITLE).fontWeight(FontWeight.Bold)
                  .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_MAIN)
                Text(this.comfort)
                  .fontSize(F.CAPTION).lineHeight(22).textAlign(TextAlign.Center)
                  .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_GRAY)
                  .margin({ top: S.XS })
                Button('开始记录今天的心情')
                  .width('100%').height(48).margin({ top: S.XL })
                  .backgroundColor(resolveColors(this.darkMode, this.currentTheme).PINK)
                  .borderRadius(24)
                  .fontSize(F.BODY).fontWeight(FontWeight.Medium)
                  .fontColor(resolveColors(this.darkMode, this.currentTheme).BTN_TEXT)
                  .shadow(Shadow.CARD)
                  .onClick(() => {
                    this.getUIContext().getRouter().pushUrl({ url: 'pages/AddEntry', params: { fromTab: 0 } });
                  })
              }
              .width('100%').alignItems(HorizontalAlign.Center)
              .padding({ top: S.SM, bottom: S.SM })
            }
          }

          Row().height(S.BOTTOM_BREATH)
        }
        .padding({ left: S.LG, right: S.LG })
      }
      .layoutWeight(1).scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring)
    }
    .width('100%').height('100%')
  }
}
