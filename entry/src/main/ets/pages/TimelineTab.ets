/**
 * TimelineTab — 记录时间线
 * 按月分组展示所有心情记录，支持左滑编辑/删除
 * 外层使用 LazyForEach 按需渲染分组，内层 ForEach 渲染组内记录
 */

import router from '@ohos.router';
import { Token, Dark, S, F } from '../common/styles';
import { GlassCard } from '../common/components/GlassCard';
import { MoodRecord, getMoodIconResource, getMoodLabel } from '../model/MoodRecord';
import { setEditPayload } from '../common/EditBridge';
import { GroupDataSource, MonthGroup } from '../viewmodel/LazyDataSource';

@Component
export struct TimelineTab {
  @Prop @Watch('onGroupsChange') groupedRecords: MonthGroup[] = [];
  @Prop totalRecords: number = 0;
  @Prop fromTab: number = 1;
  @StorageLink('darkMode') darkMode: boolean = false;
  onDelete: (id: string) => void = () => {};

  private groupDataSource: GroupDataSource = new GroupDataSource();

  aboutToAppear(): void {
    this.groupDataSource.setData(this.groupedRecords);
  }

  onGroupsChange(): void {
    this.groupDataSource.setData(this.groupedRecords);
  }

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

  @Builder SwipeBtns(r: MoodRecord) {
    Row() {
      Button() {
        Column() {
          Image($r('app.media.ic_edit')).width(20).height(20).fillColor(Color.White)
          Text('编辑').fontSize(12).fontColor(Color.White).margin({ top: 4 })
        }
        .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      }
      .width(72).height('100%').backgroundColor(this.darkMode ? Dark.BLUE : Token.BLUE)
      .borderRadius({ topLeft: 12, bottomLeft: 12 })
      .onClick(() => {
        setEditPayload({ id: r.id, text: r.text, score: r.score });
        router.pushUrl({ url: 'pages/AddEntry', params: { fromTab: this.fromTab } });
      })

      Button() {
        Column() {
          Image($r('app.media.ic_delete')).width(20).height(20).fillColor(Color.White)
          Text('删除').fontSize(12).fontColor(Color.White).margin({ top: 4 })
        }
        .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      }
      .width(72).height('100%').backgroundColor(this.darkMode ? Dark.DELETE_RED : Token.DELETE_RED)
      .borderRadius({ topRight: 12, bottomRight: 12 })
      .onClick(() => { this.onDelete(r.id); })
    }
    .height('100%')
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column() {
        Row() {
          Text('记录时间线').fontSize(F.TITLE).fontWeight(FontWeight.Bold).fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN)
        }
        .width('100%').padding({ top: S.HEADER_TOP, bottom: S.MD, left: S.LG, right: S.LG })

        if (this.totalRecords > 0) {
          List({ space: S.MD }) {
            LazyForEach(this.groupDataSource, (group: MonthGroup) => {
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

            ListItem() { Row() }.height(140) // 底部留白: 悬浮TabBar(72) + margin(16) + 系统导航条(~36)
          }
          .width('100%').layoutWeight(1).padding({ left: S.LG, right: S.LG })
          .sticky(StickyStyle.Header)
        }
      }
      .width('100%').height('100%')

      if (this.totalRecords === 0) {
        Column() {
          Image($r('app.media.img_home_cloud'))
            .width(120).height(120).objectFit(ImageFit.Contain)
            .opacity(0.8)
          Text('还没有记录').fontSize(F.BODY).fontColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY)
            .margin({ top: S.MD })
          Text('点击底部 ⊕ 写下第一条心情吧').fontSize(F.CAPTION).fontColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY).margin({ top: S.XS })
        }
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%').height('100%')
  }
}
