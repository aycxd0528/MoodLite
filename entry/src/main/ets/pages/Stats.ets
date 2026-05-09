/**
 * StatsContent — 情绪统计看板 (内嵌组件，使用 StatsViewModel 聚合层)
 */

import promptAction from '@ohos.promptAction';
import DataManager from '../data/DataManager';
import { MoodRecord, CalendarDayItem, getMoodLabel } from '../model/MoodRecord';
import { Token, Dark, R, S, F } from '../common/styles';
import { GlassCard } from '../common/components/GlassCard';
import {
  generateCalendarGrid,
  calcMonthlyStats,
  heatmapColor,
  calcTagDistribution,
  TagDistribution,
  WEEKDAY_HEADERS,
} from '../viewmodel/StatsViewModel';

const MONTH_NAMES: string[] = ['1月','2月','3月','4月','5月','6月','7月','8月','9月','10月','11月','12月'];

@Component
export struct StatsContent {
  @StorageLink('darkMode') darkMode: boolean = false;
  @State year: number = new Date().getFullYear();
  @State month: number = new Date().getMonth() + 1;
  @State calendarCells: CalendarDayItem[] = [];
  @State happyPercent: number = 0;
  @State sadPercent: number = 0;
  @State neutralPercent: number = 0;
  @State recordDays: number = 0;
  @State tagDistributions: TagDistribution[] = [];

  aboutToAppear(): void { this.refresh(); }

  async refresh(): Promise<void> {
    const records: MoodRecord[] = await DataManager.getAllRecords();

    this.calendarCells = generateCalendarGrid(this.year, this.month, records);

    const monthlyStats = calcMonthlyStats(this.year, this.month, records);
    const totalRecords = monthlyStats.happyDays + monthlyStats.neutralDays + monthlyStats.sadDays;
    if (totalRecords > 0) {
      this.happyPercent = Math.round((monthlyStats.happyDays / totalRecords) * 100);
      this.sadPercent = Math.round((monthlyStats.sadDays / totalRecords) * 100);
      this.neutralPercent = 100 - this.happyPercent - this.sadPercent;
    } else {
      this.happyPercent = 0;
      this.sadPercent = 0;
      this.neutralPercent = 0;
    }
    this.recordDays = monthlyStats.totalDays;
    this.tagDistributions = calcTagDistribution(records);
  }

  prevMonth(): void {
    if (this.month === 1) { this.month = 12; this.year--; } else this.month--;
    this.refresh();
  }

  nextMonth(): void {
    if (this.month === 12) { this.month = 1; this.year++; } else this.month++;
    this.refresh();
  }

  build() {
    Scroll() {
      Column({ space: S.MD }) {

        // ====== 1. 情绪热力图 ======
        GlassCard() {
          Column() {
            // 月份导航
            Row() {
              Button() { Text('〈').fontSize(F.BODY).fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN) }
                .width(32).height(32).backgroundColor('transparent').onClick(() => { this.prevMonth(); })
              Blank()
              Text(this.year + '年' + MONTH_NAMES[this.month - 1]).fontSize(18).fontWeight(FontWeight.Bold)
                .fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN)
              Blank()
              Button() { Text('〉').fontSize(F.BODY).fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN) }
                .width(32).height(32).backgroundColor('transparent').onClick(() => { this.nextMonth(); })
            }
            .width('100%').margin({ bottom: S.SM })

            // 星期表头
            Row() {
              ForEach(WEEKDAY_HEADERS, (day: string) => {
                Column() { Text(day).fontSize(F.SMALL).fontColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY) }
                .layoutWeight(1).alignItems(HorizontalAlign.Center)
              }, (day: string) => day)
            }
            .width('100%')

            // 热力图网格
            Grid() {
              ForEach(this.calendarCells, (cell: CalendarDayItem, index: number) => {
                GridItem() {
                  Column()
                    .width('100%').height('100%')
                    .borderRadius(4)
                    .backgroundColor(
                      !cell.isCurrentMonth
                        ? 'transparent'
                        : (cell.count === 0
                          ? (this.darkMode ? '#3D3D5A' : Token.BAR_BG)
                          : heatmapColor(cell.moodCode,
                      (cell.moodCode === 4 || cell.moodCode === 2) ? Math.min(2, cell.count * 0.5) : Math.abs(cell.avgScore),
                      cell.isCurrentMonth, this.darkMode))
                    )
                    .onClick(() => {
                      if (!cell.isCurrentMonth || cell.count === 0) return;
                      const scoreInt = Math.round(cell.avgScore);
                      const moodLabel = getMoodLabel(scoreInt);
                      const msg = cell.dateStr + '  ' + moodLabel + ' (' + cell.avgScore.toFixed(1) + ')';
                      try { promptAction.showToast({ message: msg, duration: 2000 }); } catch (_e) { /* ignore */ }
                    })
                }
              }, (cell: CalendarDayItem, index: number) => cell.dateStr + '_' + index)
            }
            .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
            .rowsTemplate('1fr 1fr 1fr 1fr 1fr 1fr')
            .columnsGap(6).rowsGap(6)
            .width('100%').aspectRatio(1.16).margin({ top: S.XS })

            // 色阶图例：2×2
            Column({ space: S.XS }) {
              Row() {
                Column() {
                  Row() {
                    Text('低落').fontSize(F.TINY).width(28).fontColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY)
                    Column().width(10).height(10).backgroundColor('#B5D8F7').borderRadius(2).margin({ left: 2 })
                    Column().width(10).height(10).backgroundColor('#90C4F0').borderRadius(2).margin({ left: 1 })
                    Column().width(10).height(10).backgroundColor('#6DADE5').borderRadius(2).margin({ left: 1 })
                    Column().width(10).height(10).backgroundColor('#5095D8').borderRadius(2).margin({ left: 1 })
                    Column().width(10).height(10).backgroundColor('#3B7EC2').borderRadius(2).margin({ left: 1 })
                  }
                }
                .layoutWeight(1)

                Column() {
                  Row() {
                    Text('愉悦').fontSize(F.TINY).width(28).fontColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY)
                    Column().width(10).height(10).backgroundColor('#FFCCDD').borderRadius(2).margin({ left: 2 })
                    Column().width(10).height(10).backgroundColor('#FAAEC7').borderRadius(2).margin({ left: 1 })
                    Column().width(10).height(10).backgroundColor('#F590AE').borderRadius(2).margin({ left: 1 })
                    Column().width(10).height(10).backgroundColor('#E87398').borderRadius(2).margin({ left: 1 })
                    Column().width(10).height(10).backgroundColor('#D0557A').borderRadius(2).margin({ left: 1 })
                  }
                }
                .layoutWeight(1)
              }
              .width('100%')

              Row() {
                Column() {
                  Row() {
                    Text('平静').fontSize(F.TINY).width(28).fontColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY)
                    Column().width(10).height(10).backgroundColor('#FFFAE0').borderRadius(2).margin({ left: 2 })
                    Column().width(10).height(10).backgroundColor('#FFF5B3').borderRadius(2).margin({ left: 1 })
                    Column().width(10).height(10).backgroundColor('#FFED80').borderRadius(2).margin({ left: 1 })
                    Column().width(10).height(10).backgroundColor('#FFE44D').borderRadius(2).margin({ left: 1 })
                    Column().width(10).height(10).backgroundColor('#FFD700').borderRadius(2).margin({ left: 1 })
                  }
                }
                .layoutWeight(1)

                Column() {
                  Row() {
                    Text('混合').fontSize(F.TINY).width(28).fontColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY)
                    Column().width(10).height(10).backgroundColor('#D49DE4').borderRadius(2).margin({ left: 2 })
                    Column().width(10).height(10).backgroundColor('#C265D2').borderRadius(2).margin({ left: 1 })
                    Column().width(10).height(10).backgroundColor('#AB47BC').borderRadius(2).margin({ left: 1 })
                    Column().width(10).height(10).backgroundColor('#8E24AA').borderRadius(2).margin({ left: 1 })
                    Column().width(10).height(10).backgroundColor('#6A1B9A').borderRadius(2).margin({ left: 1 })
                  }
                }
                .layoutWeight(1)
              }
              .width('100%')
            }
            .width('100%').margin({ top: S.SM })

            // 提示
            Row() {
              Image($r('app.media.ic_sparkles')).width(14).height(14).objectFit(ImageFit.Contain)
              Text('颜色深浅代表情绪强度')
                .fontSize(11).fontColor(this.darkMode ? Dark.INFO_TIP : Token.INFO_TIP).margin({ left: S.XS })
            }
            .width('100%')
            .padding({ top: 10, bottom: 10 })
            .backgroundColor(this.darkMode ? Dark.BUBBLE_BG : Token.BUBBLE_BG).borderRadius(R.TINY)
            .justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center)
            .margin({ top: S.SM })
          }
          .width('100%')
        }

        // ====== 2. 本月情绪概览 ======
        GlassCard() {
          Column() {
            Text('本月情绪概览').fontSize(F.BODY).fontWeight(FontWeight.Bold)
              .fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN).margin({ bottom: S.MD })

            Row() {
              // 愉悦
              Column() {
                Image($r('app.media.ic_face_good')).width(32).height(32).objectFit(ImageFit.Contain)
                Text(this.happyPercent + '%').fontSize(20).fontWeight(FontWeight.Bold)
                  .fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN).margin({ top: S.XS })
                Text('愉悦').fontSize(12).fontColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY).margin({ top: 2 })
                Stack({ alignContent: Alignment.Start }) {
                  Column().width(40).height(4).backgroundColor(this.darkMode ? '#3D3D5A' : '#F0F0F0').borderRadius(2)
                  Column().width(40 * this.happyPercent / 100).height(4).backgroundColor(Token.PINK).borderRadius(2)
                }.margin({ top: S.XS })
              }.alignItems(HorizontalAlign.Center).layoutWeight(1)

              Divider().vertical(true).height(60).color(this.darkMode ? Dark.DIVIDER : Token.DIVIDER)

              // 低落
              Column() {
                Image($r('app.media.ic_face_bad')).width(32).height(32).objectFit(ImageFit.Contain)
                Text(this.sadPercent + '%').fontSize(20).fontWeight(FontWeight.Bold)
                  .fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN).margin({ top: S.XS })
                Text('低落').fontSize(12).fontColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY).margin({ top: 2 })
                Stack({ alignContent: Alignment.Start }) {
                  Column().width(40).height(4).backgroundColor(this.darkMode ? '#3D3D5A' : '#F0F0F0').borderRadius(2)
                  Column().width(40 * this.sadPercent / 100).height(4).backgroundColor(Token.BLUE_DEEP).borderRadius(2)
                }.margin({ top: S.XS })
              }.alignItems(HorizontalAlign.Center).layoutWeight(1)

              Divider().vertical(true).height(60).color(this.darkMode ? Dark.DIVIDER : Token.DIVIDER)

              // 平静
              Column() {
                Image($r('app.media.ic_face_neutral')).width(32).height(32).objectFit(ImageFit.Contain)
                Text(this.neutralPercent + '%').fontSize(20).fontWeight(FontWeight.Bold)
                  .fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN).margin({ top: S.XS })
                Text('平静').fontSize(12).fontColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY).margin({ top: 2 })
                Stack({ alignContent: Alignment.Start }) {
                  Column().width(40).height(4).backgroundColor(this.darkMode ? '#3D3D5A' : '#F0F0F0').borderRadius(2)
                  Column().width(40 * this.neutralPercent / 100).height(4).backgroundColor(this.darkMode ? Dark.BAR_NEUTRAL : Token.BAR_NEUTRAL).borderRadius(2)
                }.margin({ top: S.XS })
              }.alignItems(HorizontalAlign.Center).layoutWeight(1)

              Divider().vertical(true).height(60).color(this.darkMode ? Dark.DIVIDER : Token.DIVIDER)

              // 记录天数
              Column() {
                Image($r('app.media.bullseye')).width(32).height(32).objectFit(ImageFit.Contain)
                Text(String(this.recordDays)).fontSize(20).fontWeight(FontWeight.Bold)
                  .fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN).margin({ top: S.XS })
                Text('记录天数').fontSize(12).fontColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY).margin({ top: 2 })
              }.alignItems(HorizontalAlign.Center).layoutWeight(1)
            }
            .width('100%').alignItems(VerticalAlign.Top)
          }
          .width('100%')
        }

        // ====== 3. 情绪场景分布 ======
        if (this.tagDistributions.length > 0) {
          GlassCard() {
            Column() {
              Text('情绪场景分布').fontSize(F.BODY).fontWeight(FontWeight.Bold)
                .fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN).margin({ bottom: S.MD })

              ForEach(this.tagDistributions, (td: TagDistribution) => {
                Row() {
                  Text(td.tag)
                    .fontSize(F.CAPTION).fontWeight(FontWeight.Medium)
                    .fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN)
                    .width(48)

                  Column() {
                    Row() {
                      Column()
                        .height(8)
                        .width(Math.max(4, 140 * td.count / this.tagDistributions[0].count))
                        .backgroundColor(
                          td.avgScore >= 0.5 ? Token.PINK
                          : td.avgScore <= -0.5 ? Token.BLUE_DEEP
                          : (this.darkMode ? Dark.BAR_NEUTRAL : Token.BAR_NEUTRAL)
                        )
                        .borderRadius(4)
                    }
                    .width(140).height(8)
                    .backgroundColor(this.darkMode ? '#3D3D5A' : '#F0F0F0')
                    .borderRadius(4)
                  }
                  .margin({ left: S.SM }).layoutWeight(1)

                  Column() {
                    Text(td.count + '次').fontSize(F.SMALL).fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN)
                    Text((td.avgScore >= 0 ? '+' : '') + td.avgScore.toFixed(1))
                      .fontSize(F.TINY)
                      .fontColor(
                        td.avgScore >= 0.5 ? Token.PINK
                        : td.avgScore <= -0.5 ? Token.BLUE_DEEP
                        : Token.TEXT_GRAY
                      )
                  }
                  .alignItems(HorizontalAlign.End).width(48)
                }
                .width('100%').margin({ bottom: S.SM })
              }, (td: TagDistribution) => td.tag)
            }
            .width('100%')
          }
        }

        Row().width('100%').height(S.BOTTOM_BREATH)
      }
      .padding({ left: S.LG, right: S.LG, top: S.XS })
    }
    .width('100%').scrollBar(BarState.Off).align(Alignment.TopStart)
  }
}
