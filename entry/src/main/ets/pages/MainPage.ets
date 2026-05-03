/**
 * MainPage — v2.0 五宫格悬浮底导
 *
 * 导航顺序：今日(0) | 记录(1) | 发布(2) | 统计(3) | 我的(4)
 * 中心 ⊕(索引2) 凸起圆球 + offset({y:-15}) → router.pushUrl(AddEntry)
 */

import router from '@ohos.router';
import DataManager from '../data/DataManager';
import { Token, Dark, Shadow, R, S, F, L } from '../common/styles';
import { GlassCard } from '../common/components/GlassCard';
import { MoodRecord, getMoodEmoji, getMoodIconResource, getMoodLabel } from '../model/MoodRecord';
import { Profile } from './Profile';
import { StatsContent } from './Stats';
import { setEditPayload } from '../common/EditBridge';

interface MonthGroup {
  monthTitle: string;
  records: MoodRecord[];
}

@Entry
@Component
struct MainPage {
  @State tab: number = 0;
  @StorageLink('darkMode') darkMode: boolean = false;
  @State records: MoodRecord[] = [];
  @State groupedRecords: MonthGroup[] = [];
  @State emoji: string = '😐';
  @State label: string = '';
  @State score: number = 0;
  @State comfort: string = '';

  aboutToAppear(): void {
    this.reload();
    const savedTab = AppStorage.get('moodlite_tab') as number;
    if (typeof savedTab === 'number') {
      this.tab = savedTab;
      AppStorage.delete('moodlite_tab');
    }
  }
  onPageShow(): void { this.reload(); }
  async reload(): Promise<void> {
    this.records = await DataManager.getAllRecords();
    this.groupRecords();
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

  async del(id: string): Promise<void> {
    await DataManager.deleteRecord(id);
    this.records = await DataManager.getAllRecords();
    this.groupRecords();
    if (this.records.length > 0) {
      const r = this.records[0];
      this.emoji = getMoodEmoji(r.score);
      this.label = getMoodLabel(r.score);
      this.score = r.score;
      if (r.score >= 1) this.comfort = '心情不错！把这份快乐传递给身边的人吧 ✨';
      else if (r.score <= -1) this.comfort = '看起来今天有些疲惫，给你一个温暖的拥抱，好好休息一下吧 ☁️';
      else this.comfort = '平平淡淡也是一种难得的幸福 🍵';
    } else {
      this.emoji = '😐'; this.label = '还没有记录'; this.score = 0;
      this.comfort = '写下今天的第一条心情吧 🌱';
    }
  }

  groupRecords(): void {
    const map = new Map<string, MoodRecord[]>();
    for (const r of this.records) {
      const parts = r.dateStr.split('-');
      const key = parts[0] + '年' + parts[1] + '月';
      let arr = map.get(key);
      if (!arr) { arr = []; map.set(key, arr); }
      arr.push(r);
    }
    const groups: MonthGroup[] = [];
    map.forEach((v: MoodRecord[], k: string) => {
      groups.push({ monthTitle: k, records: v });
    });
    this.groupedRecords = groups;
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // ===== 渐变呼吸背景 =====
      Column()
        .width('100%').height('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: this.darkMode
            ? [[Dark.PINK_LIGHT, 0.0], [Dark.BG, 1.0]]
            : [[Token.PINK_LIGHT, 0.0], [Token.TEXT_WHITE, 1.0]],
        })

      // ===== Tabs (5个 TabContent) =====
      Column() {
        Tabs({ index: this.tab, barPosition: BarPosition.End }) {
          TabContent() { this.Tab0() } .tabBar('今日')   // 0
          TabContent() { this.Tab1() } .tabBar('记录')   // 1
          TabContent() { Column() }    .tabBar('+')      // 2 占位
          TabContent() { this.Tab3() } .tabBar('统计')   // 3
          TabContent() { Profile() }   .tabBar('我的')   // 4
        }
        .barHeight(0).barWidth('100%')
        .scrollable(false)
        .animationDuration(0)
        .onChange((i: number) => { this.tab = i; })
      }
      .width('100%').height('100%')

      // ===== 悬浮胶囊底导 =====
      Row() {
        this.Btn(0, '今日', 'ic_today', 'ic_today_active')
        this.Btn(1, '记录', 'ic_tab_record', 'ic_tab_record')
        this.CenterPlus()
        this.Btn(3, '统计', 'ic_stats', 'ic_stats_active')
        this.Btn(4, '我的', 'ic_profile', 'ic_profile_active')
      }
      .width('92%').height(L.TAB_BAR_H)
      .backgroundColor(this.darkMode ? Dark.CARD : Token.CARD).borderRadius(R.CARD)
      .shadow(Shadow.CARD)
      .justifyContent(FlexAlign.SpaceEvenly).alignItems(VerticalAlign.Center)
      .margin({ bottom: S.MD, left: '4%', right: '4%' })
    }
    .width('100%').height('100%')
  }

  // ========== Tab 按钮 ==========
  @Builder Btn(i: number, lbl: string, ni: string, ai: string) {
    Column() {
      Image($r('app.media.' + (this.tab === i ? ai : ni)))
        .width(24).height(24).objectFit(ImageFit.Contain)
        .fillColor(this.tab === i ? Token.PINK : Token.TEXT_GRAY)
      Text(lbl).fontSize(F.SMALL)
        .fontColor(this.tab === i ? Token.PINK : Token.TEXT_GRAY).margin({ top: 2 })
    }
    .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
    .layoutWeight(1).onClick(() => { this.tab = i; })
  }

  // ========== 中心 ⊕ ==========
  @Builder CenterPlus() {
    Column() {
      Button() {
        Image($r('app.media.ic_plus')).width(28).height(28).fillColor(Color.White)
      }
      .width(L.CENTER_BTN).height(L.CENTER_BTN).borderRadius(R.FULL)
      .backgroundColor(Token.PINK).shadow(Shadow.PLUS).offset({ y: -15 })
      .onClick(() => {
        AppStorage.setOrCreate('moodlite_tab', this.tab);
        router.pushUrl({ url: 'pages/AddEntry' });
      })
    }
    .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center).layoutWeight(1)
  }

  // ==================== Tab 0: 今日 — 治愈首页 ====================
  @Builder Tab0() {
    Column() {
      // 1. 顶部 Header (替换文本 Emoji 为 3D 图片)
      Column() {
        Row({ space: 8 }) {
          Text('今天过得怎么样？')
            .fontSize(24).fontWeight(FontWeight.Bold).fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN)
          Image($r('app.media.ic_sparkles'))
            .width(22).height(22).objectFit(ImageFit.Contain)
        }
        Text('记录情绪，了解自己。')
          .fontSize(14).fontColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY).margin({ top: 6 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ top: 32, bottom: 24, left: 24, right: 24 })

      // 2. 主卡片
      Column() {
        GlassCard() {
          Column() {

            // [插画]
            Image($r('app.media.img_home_cloud'))
              .width(180).height(130).objectFit(ImageFit.Contain)
              .margin({ top: -10, bottom: 16 })

            // [欢迎语]
            Row({ space: 8 }) {
              Text('欢迎回来').fontSize(22).fontWeight(FontWeight.Bold).fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN)
              Image($r('app.media.ic_smiling_hearts')).width(24).height(24).objectFit(ImageFit.Contain)
            }
            .justifyContent(FlexAlign.Center)

            // [副文案] top:16 将自己下移，bottom:50 将下方的按钮往下压
            Text('每一次记录\n都是你关心自己的方式')
              .fontSize(14).fontColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY)
              .textAlign(TextAlign.Center).lineHeight(22)
              .margin({ top: 16, bottom: 50 })

            // [底部气泡与按钮]
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
        AppStorage.setOrCreate('moodlite_tab', this.tab);
        router.pushUrl({ url: 'pages/AddEntry' });
      })
            }
            .width('100%')
          }
          .width('100%')
          .padding({ top: 24, bottom: 24, left: 20, right: 20 })
        }
      }
      .width('100%').padding({ left: 24, right: 24 })
    }
    .width('100%').height('100%')
  }

  // ==================== Tab 1: 记录 — 时间线 ====================
  @Builder GroupHeader(title: string) {
    Row() {
      Text(title)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.darkMode ? Dark.PINK : Token.PINK)
    }
    .width('100%')
    .padding({ top: 10, bottom: 10, left: 16, right: 16 })
    .backgroundColor(this.darkMode ? Dark.BUBBLE_BG : Token.BUBBLE_BG)
    .backdropBlur(25)
    .borderRadius(12)
    .margin({ bottom: 8 })
  }

  @Builder Tab1() {
    Column() {
      Row() {
        Text('记录时间线').fontSize(F.TITLE).fontWeight(FontWeight.Bold).fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN)
      }
      .width('100%').padding({ top: 32, bottom: S.MD, left: S.LG, right: S.LG })

      if (this.records.length === 0) {
        Column() {
          Image($r('app.media.img_home_cloud'))
            .width(120).height(120).objectFit(ImageFit.Contain)
            .opacity(0.8).margin({ bottom: S.MD })
          Text('还没有记录').fontSize(F.BODY).fontColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY)
          Text('点击底部 ⊕ 写下第一条心情吧').fontSize(F.CAPTION).fontColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY).margin({ top: S.XS })
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      } else {
        List({ space: S.MD }) {
          ForEach(this.groupedRecords, (group: MonthGroup) => {
            ListItemGroup({ header: this.GroupHeader(group.monthTitle), space: 12 }) {
              ForEach(group.records, (r: MoodRecord) => {
                ListItem() {
                  GlassCard() {
                    Row() {
                      Image(getMoodIconResource(r.score)).width(36).height(36).objectFit(ImageFit.Contain)
                      Column() {
                        Row() {
                          Text(r.dateStr).fontSize(F.CAPTION).fontColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY)
                          Blank()
                          Text(getMoodLabel(r.score)).fontSize(F.CAPTION)
                            .fontColor(r.score >= 1 ? Token.PINK : r.score <= -1 ? Token.BLUE : Token.TEXT_GRAY)
                        }
                        .width('100%')
                        if (r.text) {
                          Text(r.text).fontSize(F.BODY).fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN)
                            .margin({ top: S.XS }).maxLines(2)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                        }
                      }
                      .alignItems(HorizontalAlign.Start).margin({ left: S.MD }).layoutWeight(1)
                    }
                    .width('100%').alignItems(VerticalAlign.Top)
                  }
                }
                .onClick(() => {
                  AppStorage.setOrCreate('moodlite_tab', this.tab);
                  router.pushUrl({
                    url: 'pages/EntryDetail',
                    params: {
                      recordId: r.id,
                      recordDate: r.dateStr,
                      recordScore: r.score,
                      recordText: r.text,
                    }
                  });
                })
                .swipeAction({
                  end: {
                    builder: () => { this.SwipeBtns(r) },
                    onAction: () => {},
                  },
                })
              }, (r: MoodRecord) => r.id)
            }
          }, (group: MonthGroup) => group.monthTitle)
        }
        .width('100%').layoutWeight(1).padding({ left: S.LG, right: S.LG, bottom: 120 })
        .sticky(StickyStyle.Header)
      }
    }
    .width('100%').height('100%')
  }

  @Builder SwipeBtns(r: MoodRecord) {
    Row() {
      // 编辑按钮
      Column() {
        Image($r('app.media.ic_edit')).width(20).height(20).fillColor(Color.White)
        Text('编辑').fontSize(12).fontColor(Color.White).margin({ top: 4 })
      }
      .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      .width(72).height('100%').backgroundColor(Token.BLUE)
      .onClick(() => {
        setEditPayload({ id: r.id, text: r.text, score: r.score });
        AppStorage.setOrCreate('moodlite_tab', this.tab);
        router.pushUrl({ url: 'pages/AddEntry' });
      })

      // 删除按钮
      Column() {
        Image($r('app.media.ic_delete')).width(20).height(20).fillColor(Color.White)
        Text('删除').fontSize(12).fontColor(Color.White).margin({ top: 4 })
      }
      .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      .width(72).height('100%').backgroundColor(Token.DELETE_RED)
      .onClick(() => { this.del(r.id); })
    }
  }

  // ==================== Tab 3: 统计看板 ====================
  @Builder Tab3() {
    Column() {
      Column() {
        Row({ space: 6 }) {
          Text('情绪统计').fontSize(F.TITLE).fontWeight(FontWeight.Bold).fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN)
          Image($r('app.media.ic_sparkles')).width(20).height(20).objectFit(ImageFit.Contain)
            .translate({ y: -4 })
        }
        Text('用数据看见你的情绪变化').fontSize(12).fontColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY).margin({ top: S.XS })
      }
      .width('100%').alignItems(HorizontalAlign.Start)
      .padding({ top: 32, bottom: S.XS, left: S.LG, right: S.LG })

      StatsContent()
    }
    .width('100%').height('100%')
  }
}
