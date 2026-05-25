/**
 * HomeTab — 今日首页
 * 展示今日心情摘要 / 欢迎引导 / AI 建议胶囊 / 成就徽章
 */

import curves from '@ohos.curves';
import DataManager from '../data/DataManager';
import { Token, Shadow, R, S, F } from '../common/styles';
import { resolveColors } from '../common/ThemeManager';
import { GlassCard } from '../common/components/GlassCard';
import { MoodRecord, getMoodEmoji, getMoodIconResource, getMoodLabel, formatDateStr } from '../model/MoodRecord';
import { AiSuggestion } from '../common/utils/AiAgentClient';
import { ACHIEVEMENTS, AchievementItem } from '../model/Achievement';
import { computeAchievementProgress } from '../viewmodel/AchievementChecker';
import { AchievementDialog } from '../common/components/AchievementDialog';

interface AchievementUnlock {
  id: string;
  date: string;
}

@Component
export struct HomeTab {
  @Prop @Watch('onRecordsChange') records: MoodRecord[] = [];
  @StorageLink('activeIntent') activeIntent: string | null = null;
  @StorageLink('darkMode') darkMode: boolean = false;
  @StorageLink('currentTheme') currentTheme: string = 'blossomPink';
  @State emoji: string = '😐';
  @State label: string = '';
  @State score: number = 0;
  @State comfort: string = '';
  @State capsuleOpacity: number = 0;
  @State capsuleOffY: number = 20;
  @State achievementList: AchievementItem[] = [];
  @State selectedAchievementId: string | null = null;
  @State expandedAchievement: AchievementItem | null = null;
  @State expandScale: number = 0.3;
  @State expandOpacity: number = 0.0;
  private achievementDialogController: CustomDialogController | null = null;
  private isDialogShowing: boolean = false;
  private dismissTimer: number | null = null;
  private isAnimating: boolean = false;

  aboutToAppear(): void {
    this.updateMoodState();
    this.animateCapsule();
    this.achievementList = this.buildAchievementListNow();
    this.checkPendingAchievements();
  }

  onRecordsChange(): void {
    this.updateMoodState();
    this.animateCapsule();
    this.achievementList = this.buildAchievementListNow();
    this.checkPendingAchievements();
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
      this.getUIContext()?.animateTo({ curve: curves.springMotion(0.4, 0.6) }, () => {
        this.capsuleOpacity = 1; this.capsuleOffY = 0;
      });
    } else {
      this.capsuleOpacity = 0; this.capsuleOffY = 20;
    }
  }

  // ========== 成就弹窗触发 ==========

  private async checkPendingAchievements(): Promise<void> {
    if (this.isDialogShowing) return;
    const ids: string[] = await DataManager.getPendingAchievementIds();
    if (ids.length === 0) return;

    const achievement = ACHIEVEMENTS.find(a => a.id === ids[0]);
    if (!achievement) return;

    const displayItem: AchievementItem = {
      id: achievement.id, title: achievement.title, desc: achievement.desc,
      icon: achievement.icon, color: achievement.color, category: achievement.category,
      unlocked: true,
      unlockedDate: formatDateStr(new Date()),
      progress: achievement.target,
      target: achievement.target,
      progressLabel: '已达成',
    };

    this.isDialogShowing = true;
    this.achievementDialogController = new CustomDialogController({
      builder: AchievementDialog({
        achievement: displayItem,
        onClaim: () => {
          this.isDialogShowing = false;
          // 异步标记已展示，等待关闭动画后检查下一个
          DataManager.markPendingAsSeen(ids[0]).then(() => {
            setTimeout(() => { this.checkPendingAchievements(); }, 500);
          });
        }
      }),
      autoCancel: false,
      customStyle: true,
      alignment: DialogAlignment.Center,
    });
    this.achievementDialogController.open();
  }

  // ========== 成就卡片展开（飞入中央） ==========

  private triggerExpand(a: AchievementItem): void {
    // 取消残留的 dismiss 定时器，防止竞态
    if (this.dismissTimer !== null) {
      clearTimeout(this.dismissTimer);
      this.dismissTimer = null;
    }

    // 如果已有展开卡片，先同步重置至关闭态，间隔一帧再展开新卡片（防止覆盖旧动画时闪烁）
    if (this.expandedAchievement !== null && this.expandedAchievement.id !== a.id) {
      this.expandScale = 0.3;
      this.expandOpacity = 0.0;
      this.expandedAchievement = null;
      this.selectedAchievementId = null;
      // 下一帧再启动新卡片展开
      setTimeout(() => { this.startExpand(a); }, 16);
      return;
    }

    this.startExpand(a);
  }

  private startExpand(a: AchievementItem): void {
    this.isAnimating = true;
    this.selectedAchievementId = a.id;
    this.expandedAchievement = a;
    this.expandScale = 0.3;
    this.expandOpacity = 0.0;

    this.getUIContext()?.animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
      this.expandOpacity = 1.0;
    });
    this.getUIContext()?.animateTo({ duration: 450, curve: curves.springMotion(0.45, 0.88) }, () => {
      this.expandScale = 1.0;
    });
  }

  private dismissExpand(): void {
    if (!this.isAnimating && this.expandedAchievement === null) return;
    this.isAnimating = false;
    // 取消残留定时器
    if (this.dismissTimer !== null) {
      clearTimeout(this.dismissTimer);
    }
    this.getUIContext()?.animateTo({ duration: 200, curve: Curve.EaseIn }, () => {
      this.expandScale = 0.3;
      this.expandOpacity = 0.0;
    });
    // 清理延迟设为动画时长的1.5倍（300ms），确保动画完成后再移除节点
    this.dismissTimer = setTimeout(() => {
      this.selectedAchievementId = null;
      this.expandedAchievement = null;
      this.dismissTimer = null;
    }, 350);
  }

  build() {
    Stack() {
      Column() {
        Column() {
          Row({ space: 8 }) {
            Text(this.isTodayRecorded() ? '今日心情' : '今天过得怎么样？')
              .fontSize(F.TITLE).fontWeight(FontWeight.Bold).fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_MAIN)
            Image($r('app.media.ic_sparkles')).width(22).height(22).objectFit(ImageFit.Contain)
          }
        }
        .width('100%').alignItems(HorizontalAlign.Start)
        .padding({ top: S.HEADER_TOP, bottom: 24, left: 24, right: 24 })

      Column({ space: S.MD }) {
        if (this.isTodayRecorded()) {
          GlassCard() {
            Column({ space: S.MD }) {
              Image(getMoodIconResource(this.score)).width(120).height(120).objectFit(ImageFit.Contain)
              Text(this.label).fontSize(22).fontWeight(FontWeight.Bold)
                .fontColor(this.score >= 1 ? resolveColors(this.darkMode, this.currentTheme).PINK : this.score <= -1 ? resolveColors(this.darkMode, this.currentTheme).BLUE : resolveColors(this.darkMode, this.currentTheme).TEXT_GRAY)
              Text(this.comfort)
                .fontSize(14).fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_GRAY)
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
                    Text('AI 温暖提示').fontSize(F.SMALL).fontWeight(FontWeight.Bold).fontColor(resolveColors(this.darkMode, this.currentTheme).PINK)
                    Text(this.parseActiveIntent()?.suggestion || '')
                      .fontSize(F.CAPTION).fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_MAIN)
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
                Text('欢迎回来').fontSize(22).fontWeight(FontWeight.Bold).fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_MAIN)
                Image($r('app.media.ic_smiling_hearts')).width(24).height(24).objectFit(ImageFit.Contain)
              }.justifyContent(FlexAlign.Center)
              Button('开始记录今天的心情')
                .width('100%').height(48).backgroundColor(resolveColors(this.darkMode, this.currentTheme).PINK).borderRadius(24)
                .fontSize(16).fontWeight(FontWeight.Medium).fontColor(resolveColors(this.darkMode, this.currentTheme).BTN_TEXT).shadow(Shadow.CARD)
                .margin({ top: 32 })
                .onClick(() => { this.getUIContext().getRouter().pushUrl({ url: 'pages/AddEntry', params: { fromTab: 0 } }); })
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
            .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_MAIN)
          Blank()
          Text(this.achievementList.filter(a => a.unlocked).length + '/7')
            .fontSize(14).fontColor(resolveColors(this.darkMode, this.currentTheme).PINK).fontWeight(FontWeight.Medium)
        }.width('100%').padding({ bottom: 16 })

        Scroll() {
          Row({ space: 12 }) {
            ForEach(this.achievementList, (a: AchievementItem) => {
              Column() {
                if (a.unlocked && a.unlockedDate === formatDateStr(new Date())) {
                  Text('今日解锁').fontSize(9).fontWeight(500).fontColor(resolveColors(this.darkMode, this.currentTheme).PINK)
                    .padding({ left: 6, right: 6, top: 1, bottom: 1 })
                    .backgroundColor(resolveColors(this.darkMode, this.currentTheme).PINK_LIGHT)
                    .borderRadius(8).margin({ bottom: 4 })
                } else {
                  Column().height(16)
                }
                Image(a.icon).width(76).height(76).objectFit(ImageFit.Contain)
                  .fillColor(a.unlocked ? a.color : resolveColors(this.darkMode, this.currentTheme).BAR_NEUTRAL)
                Text(a.title).fontSize(14).fontWeight(500)
                  .fontColor(a.unlocked
                    ? resolveColors(this.darkMode, this.currentTheme).TEXT_MAIN
                    : resolveColors(this.darkMode, this.currentTheme).TEXT_GRAY)
                  .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
                  .margin({ top: 8 })
                if (a.unlocked) {
                  Text('已解锁 · ' + a.unlockedDate).fontSize(10)
                    .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_GRAY).margin({ top: 6 })
                } else {
                  Column() {
                    Row() {
                      Column().width(Math.max(4, 90 * a.progress / a.target))
                        .height(5).backgroundColor(a.color).borderRadius(3)
                    }.width(90).height(5)
                    .backgroundColor(resolveColors(this.darkMode, this.currentTheme).BAR_BG).borderRadius(3)
                    Text(a.progressLabel).fontSize(9)
                      .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_GRAY).margin({ top: 4 })
                  }.margin({ top: 6 })
                }
              }
              .width(130).height(165).alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)
              .backgroundColor(a.unlocked
                ? resolveColors(this.darkMode, this.currentTheme).CARD
                : resolveColors(this.darkMode, this.currentTheme).BUBBLE_BG)
              .border({ width: a.unlocked ? 1.5 : 1,
                color: a.unlocked ? a.color : resolveColors(this.darkMode, this.currentTheme).DIVIDER })
              .borderRadius(16)
              .shadow(a.unlocked ? { radius: 8, color: a.color + '33', offsetY: 2 } as ShadowOptions : ShadowStyle.OUTER_DEFAULT_XS)
              .padding({ top: 10, bottom: 14, left: 10, right: 10 })
              .onClick(() => { this.triggerExpand(a); })
            }, (a: AchievementItem) => a.id + '_' + a.progress + '_' + a.unlocked)
          }.height(175)
        }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).width('100%').clip(false)
      }
      .width('100%').alignItems(HorizontalAlign.Start)
      .padding({ left: 24, right: 24 }).margin({ top: 32 })
      }
    .width('100%').height('100%')

      // ========== 全屏展开卡片遮罩 ==========
      if (this.expandedAchievement !== null) {
        Stack() {
          // 半透明背景（跟随 expandOpacity 平滑渐变）
          Column()
            .width('100%').height('100%')
            .backgroundColor('rgba(0,0,0,0.45)')
            .opacity(this.expandOpacity)
            .onClick(() => { this.dismissExpand(); })

          // 中央展开卡片（直接展示详情，无翻转）
          Stack() {
            Column() {
              // 顶部留空（为 ✕ 腾出空间）
              Column().height(24)

              // 中间内容（可滚动）
              Scroll() {
                Column({ space: 8 }) {
                  Image(this.expandedAchievement.icon)
                    .width(84).height(84).objectFit(ImageFit.Contain)
                    .fillColor(this.expandedAchievement.color)
                  Text(this.expandedAchievement.title)
                    .fontSize(22).fontWeight(FontWeight.Bold)
                    .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_MAIN)
                  Text(this.expandedAchievement.desc)
                    .fontSize(F.BODY)
                    .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_GRAY)
                    .textAlign(TextAlign.Center)

                  if (this.expandedAchievement.unlocked) {
                    Text('解锁于 ' + this.expandedAchievement.unlockedDate)
                      .fontSize(F.CAPTION).fontColor(resolveColors(this.darkMode, this.currentTheme).PINK).margin({ top: 8 })
                  } else {
                    Column() {
                      Row() {
                        Column().width(Math.max(4, 160 * this.expandedAchievement.progress / this.expandedAchievement.target))
                          .height(6).backgroundColor(this.expandedAchievement.color).borderRadius(3)
                      }.width(160).height(6)
                      .backgroundColor(resolveColors(this.darkMode, this.currentTheme).BAR_BG).borderRadius(3)
                      Text(this.expandedAchievement.progressLabel).fontSize(F.CAPTION)
                        .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_GRAY).margin({ top: 6 })
                    }.margin({ top: 8 })
                  }
                }
                .width('100%').alignItems(HorizontalAlign.Center)
              }
              .scrollBar(BarState.Off).scrollable(ScrollDirection.Vertical)
              .layoutWeight(1).edgeEffect(EdgeEffect.Spring)

              // 底部提示（固定在底部）
              Text('点击空白关闭').fontSize(F.SMALL).fontColor(resolveColors(this.darkMode, this.currentTheme).PINK).opacity(0.5)
                .margin({ bottom: 4 })
            }
            .width('100%').height('100%')
            .alignItems(HorizontalAlign.Center)
            .padding({ top: 4, bottom: 12, left: 20, right: 20 })

            // ✕ 关闭按钮（始终在最上层，热区 44×44）
            Text('✕').fontSize(18).fontWeight(FontWeight.Bold)
              .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_GRAY)
              .padding(13)
              .onClick(() => { this.dismissExpand(); })
              .position({ top: 4, right: 10 })
        }
        .width(270).height(340)
        .backgroundColor(resolveColors(this.darkMode, this.currentTheme).CARD)
        .borderRadius(R.CARD)
        .padding(0)
        .shadow({ radius: 30, color: 'rgba(0,0,0,0.15)', offsetY: 10 })
        .scale({ x: this.expandScale, y: this.expandScale })
        .opacity(this.expandOpacity)
        .onClick(() => { /* 拦截点击穿透，防止误触遮罩导致关闭 */ })
      }
      .width('100%').height('100%')
      }
    }
  }

  buildAchievementListNow(): AchievementItem[] {
    const unlocked: Record<string, string> = {};
    const map = DataManager.getUnlockedAchievements();
    const allIds: string[] = ['first_record','streak_7','total_30','palette','decoder','rainbow','calm_5'];
    for (let i: number = 0; i < allIds.length; i++) {
      const v: string = map[allIds[i]];
      if (v && v.length > 0) unlocked[allIds[i]] = v;
    }
    const progress = computeAchievementProgress(this.records);
    const result: AchievementItem[] = [];
    const todayStr = formatDateStr(new Date());

    for (const a of ACHIEVEMENTS) {
      const p = progress[a.id];
      const pv: number = p ? p.value : 0;
      const pt: number = p ? p.target : 1;
      const pl: string = p ? p.label : '';

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
}
