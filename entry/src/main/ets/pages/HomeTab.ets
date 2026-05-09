/**
 * HomeTab — 今日首页
 * 展示今日心情摘要 / 欢迎引导 / AI 建议胶囊 / 成就徽章
 */

import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import curves from '@ohos.curves';
import DataManager from '../data/DataManager';
import { Token, Dark, Shadow, R, S, F } from '../common/styles';
import { GlassCard } from '../common/components/GlassCard';
import { MoodRecord, getMoodEmoji, getMoodIconResource, getMoodLabel, formatDateStr } from '../model/MoodRecord';
import { AiSuggestion } from '../common/utils/AiAgentClient';
import { ACHIEVEMENTS, AchievementItem } from '../model/Achievement';

interface AchievementUnlock {
  id: string;
  date: string;
}

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
  @State achievementList: AchievementItem[] = [];

  aboutToAppear(): void {
    this.updateMoodState();
    this.animateCapsule();
    this.achievementList = this.buildAchievementListNow();
  }

  onRecordsChange(): void {
    this.updateMoodState();
    this.animateCapsule();
    this.achievementList = this.buildAchievementListNow();
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
    return this.records[0].dateStr === formatDateStr(new Date());
  }

  private parseActiveIntent(): AiSuggestion | null {
    if (!this.activeIntent) return null;
    try {
      const obj = JSON.parse(this.activeIntent) as AiSuggestion;
      return obj.dateStr === formatDateStr(new Date()) ? obj : null;
    } catch (_e) { return null; }
  }

  private animateCapsule(): void {
    const intent = this.parseActiveIntent();
    if (intent) {
      animateTo({ curve: curves.springMotion(0.4, 0.6) }, () => {
        this.capsuleOpacity = 1; this.capsuleOffY = 0;
      });
    } else {
      this.capsuleOpacity = 0; this.capsuleOffY = 20;
    }
  }

  build() {
    Column() {
      Column() {
        Row({ space: 8 }) {
          Text(this.isTodayRecorded() ? '今日心情' : '今天过得怎么样？')
            .fontSize(F.TITLE).fontWeight(FontWeight.Bold).fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN)
          Image($r('app.media.ic_sparkles')).width(22).height(22).objectFit(ImageFit.Contain)
        }
        Text('记录情绪，了解自己。')
          .fontSize(14).fontColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY).margin({ top: 6 })
      }
      .width('100%').alignItems(HorizontalAlign.Start)
      .padding({ top: S.HEADER_TOP, bottom: 24, left: 24, right: 24 })

      Column({ space: S.MD }) {
        if (this.isTodayRecorded()) {
          GlassCard() {
            Column({ space: S.MD }) {
              Image(getMoodIconResource(this.score)).width(120).height(120).objectFit(ImageFit.Contain)
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
                    Text('AI 温暖提示').fontSize(F.SMALL).fontWeight(FontWeight.Bold).fontColor(Token.PINK)
                    Text(this.parseActiveIntent()?.suggestion || '')
                      .fontSize(F.CAPTION).fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN)
                      .maxLines(3).textOverflow({ overflow: TextOverflow.Ellipsis })
                  }.layoutWeight(1)
                }.width('100%').alignItems(VerticalAlign.Top)
              }
            }
            .width('100%').opacity(this.capsuleOpacity).translate({ y: this.capsuleOffY })
          }
        } else {
          GlassCard() {
            Column() {
              Image($r('app.media.img_home_cloud')).width(180).height(130).objectFit(ImageFit.Contain).margin({ bottom: 16 })
              Row({ space: 8 }) {
                Text('欢迎回来').fontSize(22).fontWeight(FontWeight.Bold).fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN)
                Image($r('app.media.ic_smiling_hearts')).width(24).height(24).objectFit(ImageFit.Contain)
              }.justifyContent(FlexAlign.Center)
              Button('开始记录今天的心情')
                .width('100%').height(48).backgroundColor(Token.PINK).borderRadius(24)
                .fontSize(16).fontWeight(FontWeight.Medium).fontColor(Token.TEXT_WHITE).shadow(Shadow.CARD)
                .margin({ top: 32 })
                .onClick(() => { router.pushUrl({ url: 'pages/AddEntry', params: { fromTab: 0 } }); })
            }
            .width('100%').padding({ top: 24, bottom: 24, left: 20, right: 20 })
          }
        }
      }
      .width('100%').padding({ left: 24, right: 24 })

      // 心情成就模块
      Column() {
        Row() {
          Text('心情成就').fontSize(24).fontWeight(600)
            .fontColor(this.darkMode ? Dark.TEXT_MAIN : '#333333')
          Blank()
          Text(this.achievementList.filter(a => a.unlocked).length + '/7')
            .fontSize(14).fontColor(Token.PINK).fontWeight(FontWeight.Medium)
        }.width('100%').padding({ bottom: 16 })

        Scroll() {
          Row({ space: 12 }) {
            ForEach(this.achievementList, (a: AchievementItem) => {
              Column() {
                if (a.unlocked && a.unlockedDate === formatDateStr(new Date())) {
                  Text('今日解锁').fontSize(9).fontWeight(500).fontColor(Token.PINK)
                    .padding({ left: 6, right: 6, top: 1, bottom: 1 })
                    .backgroundColor(this.darkMode ? 'rgba(255,139,167,0.15)' : Token.PINK_LIGHT)
                    .borderRadius(8).margin({ bottom: 4 })
                } else {
                  Column().height(16)
                }
                Image(a.icon).width(56).height(56).objectFit(ImageFit.Contain)
                  .fillColor(a.unlocked ? a.color : '#D1D1D1')
                Text(a.title).fontSize(14).fontWeight(500)
                  .fontColor(a.unlocked
                    ? (this.darkMode ? Dark.TEXT_MAIN : '#333333')
                    : (this.darkMode ? Dark.TEXT_GRAY : '#999999'))
                  .margin({ top: 8 })
                if (a.unlocked) {
                  Text('已解锁 · ' + a.unlockedDate).fontSize(10)
                    .fontColor(this.darkMode ? Dark.TEXT_GRAY : '#999999').margin({ top: 6 })
                } else {
                  Column() {
                    Row() {
                      Column().width(Math.max(4, 90 * a.progress / a.target))
                        .height(5).backgroundColor(a.color).borderRadius(3)
                    }.width(90).height(5)
                    .backgroundColor(this.darkMode ? Dark.BAR_BG : '#EEEEEE').borderRadius(3)
                    Text(a.progressLabel).fontSize(9)
                      .fontColor(this.darkMode ? Dark.TEXT_GRAY : '#B0B0B0').margin({ top: 4 })
                  }.margin({ top: 6 })
                }
              }
              .width(130).height(165).alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)
              .backgroundColor(a.unlocked
                ? (this.darkMode ? Dark.CARD : '#FFFFFF')
                : (this.darkMode ? Dark.BUBBLE_BG : '#F8F5F2'))
              .border({ width: a.unlocked ? 1.5 : 1,
                color: a.unlocked ? a.color : (this.darkMode ? Dark.DIVIDER : '#EEEEEE') })
              .borderRadius(16)
              .shadow(a.unlocked ? { radius: 8, color: a.color + '33', offsetY: 2 } as ShadowOptions : ShadowStyle.OUTER_DEFAULT_XS)
              .padding({ top: 10, bottom: 14, left: 10, right: 10 })
              .onClick(() => {
                const msg = a.unlocked ? a.title + ' · ' + a.unlockedDate : a.title + '：' + a.desc + '（' + a.progressLabel + '）';
                try { promptAction.showToast({ message: msg, duration: 2000 }); } catch (_e) {}
              })
            }, (a: AchievementItem) => a.id + '_' + a.progress + '_' + a.unlocked)
          }.height(175)
        }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).width('100%')
      }
      .width('100%').alignItems(HorizontalAlign.Start)
      .padding({ left: 24, right: 24 }).margin({ top: 32 })
    }
    .width('100%').height('100%')
  }

  buildAchievementListNow(): AchievementItem[] {
    const unlocked: Record<string, string> = {};
    const map = DataManager.getUnlockedAchievements();
    const allIds: string[] = ['first_record','streak_7','total_30','palette','decoder','rainbow','calm_5'];
    for (let i: number = 0; i < allIds.length; i++) {
      const v: string = map[allIds[i]];
      if (v && v.length > 0) unlocked[allIds[i]] = v;
    }
    const progress = this.getProgressMap();
    const result: AchievementItem[] = [];
    const todayStr = formatDateStr(new Date());

    for (const a of ACHIEVEMENTS) {
      const p: Record<string, number | string> = progress[a.id] || {};
      const pv: number = (typeof p['value'] === 'number') ? p['value'] as number : 0;
      const pt: number = (typeof p['target'] === 'number') ? p['target'] as number : 1;
      const pl: string = (typeof p['label'] === 'string') ? p['label'] as string : '';

      let isUnlocked: boolean = false;
      let uDate: string = '';
      if (unlocked[a.id]) {
        isUnlocked = true;
        uDate = unlocked[a.id];
      } else if (pv >= pt) {
        isUnlocked = true;
        uDate = todayStr;
      }

      result.push({
        id: a.id, title: a.title, desc: a.desc, icon: a.icon, color: a.color,
        category: a.category, unlocked: isUnlocked, unlockedDate: uDate,
        progress: isUnlocked ? pt : pv, target: pt,
        progressLabel: isUnlocked ? '已达成' : pl,
      });
    }
    return result;
  }

  getProgressMap(): Record<string, Record<string, number | string>> {
    const result: Record<string, Record<string, number | string>> = {};
    const r: MoodRecord[] = this.records;
    const len: number = r ? r.length : 0;

    const daySet: string[] = [];
    for (const r0 of r) {
      let found: boolean = false;
      for (let k: number = 0; k < daySet.length; k++) { if (daySet[k] === r0.dateStr) { found = true; break; } }
      if (!found) daySet.push(r0.dateStr);
    }
    for (let a: number = 0; a < daySet.length - 1; a++) {
      for (let b: number = a + 1; b < daySet.length; b++) {
        if (daySet[a] > daySet[b]) { const t: string = daySet[a]; daySet[a] = daySet[b]; daySet[b] = t; }
      }
    }
    let maxStr: number = len > 0 ? 1 : 0;
    let curS: number = len > 0 ? 1 : 0;
    for (let i: number = 1; i < daySet.length; i++) {
      const diff: number = new Date(daySet[i]).getTime() - new Date(daySet[i-1]).getTime();
      if (diff <= 26 * 3600 * 1000) { curS++; if (curS > maxStr) maxStr = curS; }
      else { curS = 1; }
    }

    const v1: Record<string, number | string> = {}; v1['value'] = len > 0 ? 1 : 0; v1['target'] = 1; v1['label'] = len > 0 ? '已记录 1/1 次' : '已记录 0/1 次';
    result['first_record'] = v1;
    const v2: Record<string, number | string> = {}; v2['value'] = maxStr; v2['target'] = 7; v2['label'] = '连续 ' + maxStr + '/7 天';
    result['streak_7'] = v2;
    const v3: Record<string, number | string> = {}; v3['value'] = len; v3['target'] = 30; v3['label'] = '累计 ' + len + '/30 篇';
    result['total_30'] = v3;

    const weekAgo: number = Date.now() - 7 * 24 * 3600 * 1000;
    const scoreSet: number[] = [];
    for (const r0 of r) {
      if (r0.timestamp >= weekAgo) {
        let found: boolean = false;
        for (let k: number = 0; k < scoreSet.length; k++) { if (scoreSet[k] === r0.score) { found = true; break; } }
        if (!found) scoreSet.push(r0.score);
      }
    }
    const v4: Record<string, number | string> = {}; v4['value'] = scoreSet.length; v4['target'] = 4; v4['label'] = scoreSet.length + '/4 种心情';
    result['palette'] = v4;

    let hasDecoder: boolean = false;
    for (const r0 of r) {
      if (r0.tags && r0.tags.length >= 3 && r0.text.trim().length > 0) { hasDecoder = true; break; }
    }
    const v5: Record<string, number | string> = {}; v5['value'] = hasDecoder ? 1 : 0; v5['target'] = 1; v5['label'] = hasDecoder ? '已达成' : '未达成';
    result['decoder'] = v5;

    let hasRainbow: boolean = false;
    const sorted: MoodRecord[] = [];
    for (const r0 of r) sorted.push(r0);
    for (let a: number = 0; a < sorted.length - 1; a++) {
      for (let b: number = a + 1; b < sorted.length; b++) {
        if (sorted[a].timestamp > sorted[b].timestamp) {
          const t: MoodRecord = sorted[a]; sorted[a] = sorted[b]; sorted[b] = t;
        }
      }
    }
    for (let i: number = 0; i < sorted.length - 1; i++) {
      if (sorted[i].score <= -1) {
        const lowTs: number = sorted[i].timestamp;
        for (let j: number = i + 1; j < sorted.length; j++) {
          if (sorted[j].score >= 1 && sorted[j].timestamp - lowTs <= 48 * 3600 * 1000) { hasRainbow = true; break; }
        }
        if (hasRainbow) break;
      }
    }
    const v6: Record<string, number | string> = {}; v6['value'] = hasRainbow ? 1 : 0; v6['target'] = 1; v6['label'] = hasRainbow ? '已达成' : '未达成';
    result['rainbow'] = v6;

    const badDays: string[] = [];
    for (const r0 of r) {
      if (r0.score < 0) {
        let found: boolean = false;
        for (let k: number = 0; k < badDays.length; k++) { if (badDays[k] === r0.dateStr) { found = true; break; } }
        if (!found) badDays.push(r0.dateStr);
      }
    }
    const allDays: string[] = [];
    for (const r0 of r) {
      let found: boolean = false;
      for (let k: number = 0; k < allDays.length; k++) { if (allDays[k] === r0.dateStr) { found = true; break; } }
      if (!found) allDays.push(r0.dateStr);
    }
    for (let a: number = 0; a < allDays.length - 1; a++) {
      for (let b: number = a + 1; b < allDays.length; b++) {
        if (allDays[a] > allDays[b]) { const t: string = allDays[a]; allDays[a] = allDays[b]; allDays[b] = t; }
      }
    }
    let calmMax: number = 0; let calmCur: number = 0;
    for (const d of allDays) {
      let isBad: boolean = false;
      for (let k: number = 0; k < badDays.length; k++) { if (badDays[k] === d) { isBad = true; break; } }
      if (!isBad) { calmCur++; if (calmCur > calmMax) calmMax = calmCur; }
      else { calmCur = 0; }
    }
    const v7: Record<string, number | string> = {}; v7['value'] = calmMax; v7['target'] = 5; v7['label'] = '连续 ' + calmMax + '/5 天';
    result['calm_5'] = v7;

    return result;
  }
}
