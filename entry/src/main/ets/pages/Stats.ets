/**
 * StatsContent — 情绪统计看板 (内嵌组件，实时数据)
 */

import DataManager from '../data/DataManager';
import { MoodRecord } from '../model/MoodRecord';
import { Token, Dark, R, S, F } from '../common/styles';
import { GlassCard } from '../common/components/GlassCard';

interface HeatCell { day: number; score: number | null; active: boolean; }

function hColor(c: HeatCell, isDark: boolean): string {
  if (!c.active) return 'transparent';
  if (c.score === null) return isDark ? '#3D3D5A' : Token.BAR_BG;
  if (c.score === 0) return isDark ? '#4A4A6A' : Token.HEAT_NEUTRAL;
  if (c.score > 0) return 'rgba(255,139,167,' + (0.25 + c.score * 0.375).toFixed(2) + ')';
  return 'rgba(143,183,232,' + (0.25 + Math.abs(c.score) * 0.375).toFixed(2) + ')';
}

const WD: string[] = ['日', '一', '二', '三', '四', '五', '六'];
const MN: string[] = ['1月','2月','3月','4月','5月','6月','7月','8月','9月','10月','11月','12月'];

@Component
export struct StatsContent {
  @StorageLink('darkMode') darkMode: boolean = false;
  @State y: number = new Date().getFullYear();
  @State m: number = new Date().getMonth() + 1;
  @State cells: HeatCell[] = [];
  @State overviewHp: number = 0;
  @State overviewSp: number = 0;
  @State overviewNp: number = 0;
  @State recordDays: number = 0;

  aboutToAppear(): void { this.refresh(); }

  async refresh(): Promise<void> {
    const records = await DataManager.getAllRecords();
    this.cells = this.buildHeatmap(records);
    this.buildOverview(records);
  }

  buildHeatmap(records: MoodRecord[]): HeatCell[] {
    const byDay = new Map<string, MoodRecord[]>();
    for (const r of records) {
      let arr = byDay.get(r.dateStr);
      if (!arr) { arr = []; byDay.set(r.dateStr, arr); }
      arr.push(r);
    }
    const fd = new Date(this.y, this.m - 1, 1);
    const sw = fd.getDay();
    const dim = new Date(this.y, this.m, 0).getDate();
    const arr: HeatCell[] = [];
    for (let i = 0; i < sw; i++) arr.push({ day: 0, score: null, active: false });
    for (let d = 1; d <= dim; d++) {
      const ds = this.y + '-' + String(this.m).padStart(2, '0') + '-' + String(d).padStart(2, '0');
      const dayRecs = byDay.get(ds);
      if (!dayRecs || dayRecs.length === 0) {
        arr.push({ day: d, score: null, active: true });
      } else {
        const sum = dayRecs.reduce((s, r) => s + r.score, 0);
        arr.push({ day: d, score: sum / dayRecs.length, active: true });
      }
    }
    while (arr.length < 42) arr.push({ day: 0, score: null, active: false });
    return arr;
  }

  buildOverview(records: MoodRecord[]): void {
    const yStr = String(this.y);
    const mStr = String(this.m).padStart(2, '0');
    const monthRecords: MoodRecord[] = [];
    for (const r of records) {
      const parts = r.dateStr.split('-');
      if (parts.length === 3 && parts[0] === yStr && parts[1] === mStr) monthRecords.push(r);
    }
    if (monthRecords.length === 0) {
      this.overviewHp = 0; this.overviewSp = 0; this.overviewNp = 0; this.recordDays = 0;
      return;
    }
    let h = 0; let s = 0; let n = 0;
    const daysSet = new Set<string>();
    for (const r of monthRecords) {
      if (r.score >= 1) h++; else if (r.score <= -1) s++; else n++;
      daysSet.add(r.dateStr);
    }
    const total = monthRecords.length;
    this.overviewHp = Math.round((h / total) * 100);
    this.overviewSp = Math.round((s / total) * 100);
    this.overviewNp = 100 - this.overviewHp - this.overviewSp;
    this.recordDays = daysSet.size;
  }

  prv(): void { if (this.m === 1) { this.m = 12; this.y--; } else this.m--; this.refresh(); }
  nxt(): void { if (this.m === 12) { this.m = 1; this.y++; } else this.m++; this.refresh(); }

  build() {
    Scroll() {
      Column({ space: S.MD }) {

        // ====== 1. 情绪热力图 ======
        GlassCard() {
          Column() {
            Row() {
              Button() { Text('〈').fontSize(F.BODY).fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN) }
                .width(32).height(32).backgroundColor('transparent').onClick(() => { this.prv(); })
              Blank()
              Text(this.y + '年' + MN[this.m - 1]).fontSize(18).fontWeight(FontWeight.Bold)
                .fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN)
              Blank()
              Button() { Text('〉').fontSize(F.BODY).fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN) }
                .width(32).height(32).backgroundColor('transparent').onClick(() => { this.nxt(); })
            }
            .width('100%').margin({ bottom: S.SM })

            Row() {
              ForEach(WD, (d: string) => {
                Column() { Text(d).fontSize(F.SMALL).fontColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY) }
                .layoutWeight(1).alignItems(HorizontalAlign.Center)
              }, (d: string) => d)
            }
            .width('100%')

            Grid() {
              ForEach(this.cells, (c: HeatCell, i: number) => {
                GridItem() {
                  Column()
                    .width('100%').height('100%')
                    .borderRadius(4).backgroundColor(hColor(c, this.darkMode))
                }
              }, (c: HeatCell, i: number) => this.y + '_' + this.m + '_' + i + '_' + c.score)
            }
            .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
            .rowsTemplate('1fr 1fr 1fr 1fr 1fr 1fr')
            .columnsGap(6).rowsGap(6)
            .width('100%').aspectRatio(1.16).margin({ top: S.XS })

            Row() {
              Text('低').fontSize(F.TINY).fontColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY)
              Column().width(12).height(12).backgroundColor('rgba(143,183,232,0.25)').borderRadius(2).margin({ left: 2 })
              Column().width(12).height(12).backgroundColor('rgba(143,183,232,0.62)').borderRadius(2).margin({ left: 2 })
              Column().width(12).height(12).backgroundColor('rgba(143,183,232,1)').borderRadius(2).margin({ left: 2 })
              Column().width(12).height(12).backgroundColor(this.darkMode ? '#3D3D5A' : Token.BAR_BG).borderRadius(2).margin({ left: 6 })
              Column().width(12).height(12).backgroundColor('rgba(255,139,167,0.25)').borderRadius(2).margin({ left: 6 })
              Column().width(12).height(12).backgroundColor('rgba(255,139,167,0.62)').borderRadius(2).margin({ left: 2 })
              Column().width(12).height(12).backgroundColor('rgba(255,139,167,1)').borderRadius(2).margin({ left: 2 })
              Text('高').fontSize(F.TINY).fontColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY).margin({ left: 2 })
            }
            .width('100%').justifyContent(FlexAlign.Center).margin({ top: S.SM })

            Row() {
              Image($r('app.media.ic_sparkles')).width(14).height(14).objectFit(ImageFit.Contain)
              Text('颜色深浅代表情绪强度，点击日期可查看当天记录')
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
              Column() {
                Image($r('app.media.ic_face_good')).width(32).height(32).objectFit(ImageFit.Contain)
                Text(this.overviewHp + '%').fontSize(20).fontWeight(FontWeight.Bold)
                  .fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN).margin({ top: S.XS })
                Text('愉悦').fontSize(12).fontColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY).margin({ top: 2 })
                Stack({ alignContent: Alignment.Start }) {
                  Column().width(40).height(4).backgroundColor(this.darkMode ? '#3D3D5A' : '#F0F0F0').borderRadius(2)
                  Column().width(40 * this.overviewHp / 100).height(4).backgroundColor(Token.PINK).borderRadius(2)
                }.margin({ top: S.XS })
              }.alignItems(HorizontalAlign.Center).layoutWeight(1)

              Divider().vertical(true).height(60).color(this.darkMode ? Dark.DIVIDER : Token.DIVIDER)

              Column() {
                Image($r('app.media.ic_face_bad')).width(32).height(32).objectFit(ImageFit.Contain)
                Text(this.overviewSp + '%').fontSize(20).fontWeight(FontWeight.Bold)
                  .fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN).margin({ top: S.XS })
                Text('低落').fontSize(12).fontColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY).margin({ top: 2 })
                Stack({ alignContent: Alignment.Start }) {
                  Column().width(40).height(4).backgroundColor(this.darkMode ? '#3D3D5A' : '#F0F0F0').borderRadius(2)
                  Column().width(40 * this.overviewSp / 100).height(4).backgroundColor(Token.BLUE_DEEP).borderRadius(2)
                }.margin({ top: S.XS })
              }.alignItems(HorizontalAlign.Center).layoutWeight(1)

              Divider().vertical(true).height(60).color(this.darkMode ? Dark.DIVIDER : Token.DIVIDER)

              Column() {
                Image($r('app.media.ic_face_neutral')).width(32).height(32).objectFit(ImageFit.Contain)
                Text(this.overviewNp + '%').fontSize(20).fontWeight(FontWeight.Bold)
                  .fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN).margin({ top: S.XS })
                Text('平静').fontSize(12).fontColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY).margin({ top: 2 })
                Stack({ alignContent: Alignment.Start }) {
                  Column().width(40).height(4).backgroundColor(this.darkMode ? '#3D3D5A' : '#F0F0F0').borderRadius(2)
                  Column().width(40 * this.overviewNp / 100).height(4).backgroundColor(this.darkMode ? Dark.BAR_NEUTRAL : Token.BAR_NEUTRAL).borderRadius(2)
                }.margin({ top: S.XS })
              }.alignItems(HorizontalAlign.Center).layoutWeight(1)

              Divider().vertical(true).height(60).color(this.darkMode ? Dark.DIVIDER : Token.DIVIDER)

              Column() {
                Image($r('app.media.bullseye')).width(32).height(32).objectFit(ImageFit.Contain)
                Text(String(this.recordDays)).fontSize(20).fontWeight(FontWeight.Bold)
                  .fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN).margin({ top: S.XS })
                Text('记录天数').fontSize(12).fontColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY).margin({ top: 2 })
              }.alignItems(HorizontalAlign.Center).layoutWeight(1)
            }
            .width('100%')
          }
          .width('100%')
        }

        Row().width('100%').height(S.BOTTOM_BREATH)
      }
      .padding({ left: S.LG, right: S.LG, top: S.XS })
    }
    .width('100%').scrollBar(BarState.Off).align(Alignment.TopStart)
  }
}
