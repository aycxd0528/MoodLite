/**
 * MainPage — v2.0 五宫格悬浮底导
 *
 * 导航顺序：今日(0) | 记录(1) | 发布(2) | 统计(3) | 我的(4)
 * 中心 ⊕(索引2) 凸起圆球 + offset({y:-15}) → router.pushUrl(AddEntry)
 */

import router from '@ohos.router';
import window from '@ohos.window';
import DataManager from '../data/DataManager';
import { Token, Dark, Shadow, R, S, F, L } from '../common/styles';
import { MoodRecord } from '../model/MoodRecord';
import { HomeTab } from './HomeTab';
import { TimelineTab } from './TimelineTab';
import { Profile } from './Profile';
import { StatsContent } from './Stats';
import { MonthGroup } from '../viewmodel/LazyDataSource';

const TAB_ICONS: Record<number, [Resource, Resource]> = {
  0: [$r('app.media.ic_today'), $r('app.media.ic_today_active')],
  1: [$r('app.media.ic_tab_record'), $r('app.media.ic_tab_record')],
  3: [$r('app.media.ic_stats'), $r('app.media.ic_stats_active')],
  4: [$r('app.media.ic_profile'), $r('app.media.ic_profile_active')],
};

@Entry
@Component
struct MainPage {
  @State tab: number = 0;
  @StorageLink('darkMode') darkMode: boolean = false;
  @State records: MoodRecord[] = [];
  @State groupedRecords: MonthGroup[] = [];

  aboutToAppear(): void {
    this.reload();
    const rp = router.getParams() as Record<string, number>;
    if (rp && typeof rp['fromTab'] === 'number') {
      this.tab = rp['fromTab'];
    } else {
      const savedTab = AppStorage.get('moodlite_tab') as number;
      if (typeof savedTab === 'number') {
        this.tab = savedTab;
        AppStorage.delete('moodlite_tab');
      }
    }
    window.getLastWindow(getContext(this)).then((wc) => {
      wc.setWindowSystemBarProperties({
        statusBarContentColor: this.darkMode ? '#FFFFFF' : '#000000',
      });
    });
  }

  onPageShow(): void { this.reload(); }

  async reload(): Promise<void> {
    await DataManager.ensureInitialized();
    this.records = await DataManager.getAllRecords();
    this.groupRecords();
  }

  async del(id: string): Promise<void> {
    const ok = await DataManager.deleteRecord(id);
    console.info('[MoodLite] del record ' + id + ' result=' + String(ok));
    if (ok) {
      this.records = this.records.filter(r => r.id !== id);
      this.groupRecords();
    }
  }

  groupRecords(): void {
    const map = new Map<string, MoodRecord[]>();
    for (const r of this.records) {
      const parts = r.dateStr.split('-');
      const y = parseInt(parts[0]);
      const m = parseInt(parts[1]);
      const key = y + '年' + m + '月';
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
      Column()
        .width('100%').height('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: this.darkMode
            ? [[Dark.PINK_LIGHT, 0.0], [Dark.BG, 1.0]]
            : [[Token.PINK_LIGHT, 0.0], [Token.TEXT_WHITE, 1.0]],
        })
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

      Column() {
        Tabs({ index: this.tab, barPosition: BarPosition.End }) {
          TabContent() {
            HomeTab({ records: this.records })
          }.tabBar('今日')

          TabContent() {
            TimelineTab({
              groupedRecords: this.groupedRecords,
              totalRecords: this.records.length,
              fromTab: 1,
              onDelete: (id: string) => { this.del(id); }
            })
          }.tabBar('记录')

          TabContent() { Column() }.tabBar('+')

          TabContent() { this.Tab3() }.tabBar('统计')

          TabContent() { Profile() }.tabBar('我的')
        }
        .barHeight(0).barWidth('100%')
        .scrollable(false)
        .animationDuration(200)
        .onChange((i: number) => { this.tab = i; })
      }
      .width('100%').height('100%')

      Row() {
        this.Btn(0, '今日', TAB_ICONS[0][0], TAB_ICONS[0][1])
        this.Btn(1, '记录', TAB_ICONS[1][0], TAB_ICONS[1][1])
        this.CenterPlus()
        this.Btn(3, '统计', TAB_ICONS[3][0], TAB_ICONS[3][1])
        this.Btn(4, '我的', TAB_ICONS[4][0], TAB_ICONS[4][1])
      }
      .width('92%').height(L.TAB_BAR_H)
      .backgroundColor(this.darkMode ? Dark.CARD : Token.CARD).borderRadius(R.CARD)
      .shadow(Shadow.CARD)
      .justifyContent(FlexAlign.SpaceEvenly).alignItems(VerticalAlign.Center)
      .margin({ bottom: S.MD, left: '4%', right: '4%' })
    }
    .width('100%').height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  @Builder Btn(i: number, lbl: string, normalIcon: Resource, activeIcon: Resource) {
    Stack({ alignContent: Alignment.Center }) {
      Row()
        .width(56).height(56)
        .backgroundColor(this.tab === i ? (this.darkMode ? 'rgba(255,139,167,0.18)' : 'rgba(255,139,167,0.12)') : 'transparent')
        .borderRadius(28)
        .animation({ duration: 250, curve: Curve.EaseInOut })

      Column() {
        Image(this.tab === i ? activeIcon : normalIcon)
          .width(24).height(24).objectFit(ImageFit.Contain)
          .fillColor(this.tab === i ? Token.PINK : Token.TEXT_GRAY)
          .animation({ duration: 200, curve: Curve.EaseOut })
        Text(lbl).fontSize(F.SMALL)
          .fontColor(this.tab === i ? Token.PINK : Token.TEXT_GRAY).margin({ top: 2 })
          .animation({ duration: 200, curve: Curve.EaseOut })
      }
      .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
    }
    .layoutWeight(1).onClick(() => { this.tab = i; })
  }

  @Builder CenterPlus() {
    Column() {
      Button() {
        Image($r('app.media.ic_plus')).width(28).height(28).fillColor(Color.White)
      }
      .width(L.CENTER_BTN).height(L.CENTER_BTN).borderRadius(R.FULL)
      .backgroundColor(Token.PINK)
      .shadow({ radius: 16, color: 'rgba(255,139,167,0.45)', offsetY: 6 })
      .offset({ y: -18 })
      .onClick(() => {
        router.pushUrl({ url: 'pages/AddEntry', params: { fromTab: this.tab } });
      })
    }
    .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center).layoutWeight(1)
  }

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
      .padding({ top: S.HEADER_TOP, bottom: S.XS, left: S.LG, right: S.LG })

      StatsContent()
    }
    .width('100%').height('100%')
  }
}
