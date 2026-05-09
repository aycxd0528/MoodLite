/**
 * TimelineTab — 记录时间线
 * 月份导航 + 按日合并卡片 + 时间线竖线 + 精确设计规格
 */

import router from '@ohos.router';
import { Token, Dark, S, F } from '../common/styles';
import { GlassCard } from '../common/components/GlassCard';
import { MoodRecord, getMoodIconResource, getMoodLabel } from '../model/MoodRecord';
import { MonthGroup } from '../viewmodel/LazyDataSource';
import { heatmapColor } from '../viewmodel/StatsViewModel';

interface DayGroup {
  dateStr: string;
  records: MoodRecord[];
  dominantScore: number;
}

@Component
export struct TimelineTab {
  @Prop @Watch('onGroupsChange') groupedRecords: MonthGroup[] = [];
  @Prop totalRecords: number = 0;
  @Prop fromTab: number = 1;
  @StorageLink('darkMode') darkMode: boolean = false;
  @State currentYear: number = new Date().getFullYear();
  @State currentMonth: number = new Date().getMonth() + 1;
  @State dayGroups: DayGroup[] = [];
  onDelete: (id: string) => void = () => {};

  aboutToAppear(): void { this.refreshDays(); }
  onGroupsChange(): void { this.refreshDays(); }

  refreshDays(): void {
    const monthKey = this.currentYear + '年' + this.currentMonth + '月';
    const group = this.groupedRecords.find(g => g.monthTitle === monthKey);
    this.dayGroups = group ? this.buildDayGroups(group.records) : [];
  }

  prevMonth(): void {
    if (this.currentMonth === 1) { this.currentMonth = 12; this.currentYear--; }
    else this.currentMonth--;
    this.refreshDays();
  }

  nextMonth(): void {
    if (this.currentMonth === 12) { this.currentMonth = 1; this.currentYear++; }
    else this.currentMonth++;
    this.refreshDays();
  }

  buildDayGroups(records: MoodRecord[]): DayGroup[] {
    const map = new Map<string, DayGroup>();
    for (const r of records) {
      let dg = map.get(r.dateStr);
      if (!dg) { dg = { dateStr: r.dateStr, records: [], dominantScore: 0 }; map.set(r.dateStr, dg); }
      dg.records.push(r);
    }
    const result: DayGroup[] = [];
    map.forEach((v) => {
      let sum = 0;
      for (const r of v.records) sum += r.score;
      v.dominantScore = sum / v.records.length;
      // 同一天内按时间升序（旧→新）
      v.records.sort((a, b) => a.timestamp - b.timestamp);
      result.push(v);
    });
    // 按日期升序（旧日期在上）
    result.sort((a, b) => a.dateStr.localeCompare(b.dateStr));
    return result;
  }

  formatDate(dateStr: string): string {
    const parts = dateStr.split('-');
    return parseInt(parts[1]) + '月' + parseInt(parts[2]) + '日';
  }

  formatTime(ts: number): string {
    const d = new Date(ts);
    return String(d.getHours()).padStart(2, '0') + ':' + String(d.getMinutes()).padStart(2, '0');
  }

  getEmotionColor(score: number): string {
    const mc = score >= 0.5 ? 3 : (score <= -0.5 ? 1 : 2);
    return heatmapColor(mc, Math.abs(score) >= 1 ? 1.5 : 0.5, true, this.darkMode);
  }

  // 和 generateCalendarGrid 完全一致的 moodCode 计算
  computeMoodCode(records: MoodRecord[]): number {
    let pos = 0; let neg = 0;
    for (const r of records) {
      if (r.score >= 1) pos++;
      if (r.score <= -1) neg++;
    }
    if (pos === 0 && neg === 0) return 2;
    if (pos > 0 && neg > 0) {
      if (pos > neg) return 3;
      if (neg > pos) return 1;
      return 4;
    }
    if (pos > 0) return 3;
    return 1;
  }

  getMonthLabel(): string {
    return this.currentYear + '年' + this.currentMonth + '月';
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column() {
        // 标题
        Row() {
          Text('记录时间线').fontSize(F.TITLE).fontWeight(FontWeight.Bold)
            .fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN)
        }
        .width('100%').padding({ top: S.HEADER_TOP, bottom: S.SM, left: S.LG, right: S.LG })

        // 月份导航
        Column() {
          GlassCard() {
            Row() {
              Button() { Text('〈').fontSize(F.BODY).fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN) }
                .width(32).height(32).backgroundColor('transparent').onClick(() => { this.prevMonth(); })
              Text(this.getMonthLabel()).fontSize(F.BODY).fontWeight(FontWeight.Medium)
                .fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN)
                .layoutWeight(1).textAlign(TextAlign.Center)
              Button() { Text('〉').fontSize(F.BODY).fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN) }
                .width(32).height(32).backgroundColor('transparent').onClick(() => { this.nextMonth(); })
            }
            .width('100%').alignItems(VerticalAlign.Center)
          }
        }
        .width('100%').padding({ left: S.MD, right: S.MD, bottom: S.MD })

        // 时间线列表
        if (this.dayGroups.length > 0) {
          List({ space: 16 }) {
            ForEach(this.dayGroups, (day: DayGroup) => {
              ListItem() {
                Column() {
                  // 日期头部 — 背景与热力图同色，文字用强色确保可读
                  Row() {
                    Column().width(6).height(6)
                      .backgroundColor(heatmapColor(this.computeMoodCode(day.records), 2.0, true, this.darkMode))
                      .borderRadius(3)
                    Text(this.formatDate(day.dateStr))
                      .fontSize(14).fontWeight(500)
                      .fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN)
                      .margin({ left: 8 })
                  }
                  .width('100%').height(32)
                  .padding({ left: 16, right: 16 })
                  .backgroundColor(heatmapColor(this.computeMoodCode(day.records), Math.abs(day.dominantScore), true, this.darkMode))
                  .borderRadius({ topLeft: 12, topRight: 12, bottomLeft: 0, bottomRight: 0 })

                  // 记录项
                  Column({ space: 20 }) {
                    ForEach(day.records, (r: MoodRecord) => {
                      Row() {
                        Image(getMoodIconResource(r.score))
                          .width(24).height(24).objectFit(ImageFit.Contain)
                        Column() {
                          Row() {
                            Text(getMoodLabel(r.score))
                              .fontSize(18).fontWeight(600)
                              .fontColor(this.getEmotionColor(r.score))
                            Text('·')
                              .fontSize(14).fontColor('#999999')
                              .margin({ left: 4, right: 4 })
                            Text(this.formatTime(r.timestamp))
                              .fontSize(14).fontWeight(400)
                              .fontColor('#999999')
                          }
                          if (r.tags && r.tags.length > 0) {
                            Text(r.tags.join(' · '))
                              .fontSize(12).fontWeight(400)
                              .fontColor(this.getEmotionColor(r.score))
                              .margin({ top: 2 })
                          }
                          if (r.text) {
                            Text(r.text)
                              .fontSize(F.BODY).fontWeight(400)
                              .fontColor('#333333')
                              .margin({ top: 8 }).maxLines(3).lineHeight(22)
                              .textOverflow({ overflow: TextOverflow.Ellipsis })
                          }
                        }
                        .alignItems(HorizontalAlign.Start).margin({ left: 12 }).layoutWeight(1)
                      }
                      .width('100%').alignItems(VerticalAlign.Top)
                      .padding({ left: 16, right: 16 })
                      .onClick(() => {
                        router.pushUrl({
                          url: 'pages/EntryDetail',
                          params: {
                            recordId: r.id, recordDate: r.dateStr,
                            recordScore: r.score, recordText: r.text,
                            recordTags: r.tags || [],
                          }
                        });
                      })
                    }, (r: MoodRecord) => r.id)
                  }
                  .margin({ top: 16 })
                }
                .width('100%')
                .backgroundColor(this.darkMode ? Dark.CARD : '#FFFFFF')
                .borderRadius(12)
                .shadow({ radius: 12, color: 'rgba(0,0,0,0.08)', offsetY: 4 })
                .padding({ bottom: 16 })
              }
            }, (day: DayGroup) => day.dateStr)

            ListItem() { Row() }.height(140)
          }
          .width('100%').layoutWeight(1)
          .padding({ left: 16, right: 16 })
        }
      }
      .width('100%').height('100%')

      if (this.dayGroups.length === 0) {
        Column() {
          Image($r('app.media.img_home_cloud')).width(120).height(120).objectFit(ImageFit.Contain).opacity(0.8)
          Text('还没有记录').fontSize(F.BODY).fontColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY).margin({ top: S.MD })
          Text('点击底部 ⊕ 写下第一条心情吧').fontSize(F.CAPTION).fontColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY).margin({ top: S.XS })
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%').height('100%')
  }

}
