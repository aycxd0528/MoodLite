/**
 * EntryDetail — 记录详情页
 */

import window from '@ohos.window';
import DataManager from '../data/DataManager';
import { Token, Dark, Shadow, R, S, F } from '../common/styles';
import { GlassCard } from '../common/components/GlassCard';
import { MoodRecord, getMoodIconResource, getMoodLabel } from '../model/MoodRecord';
import { setEditPayload } from '../common/EditBridge';

@CustomDialog
struct DeleteConfirmDialog {
  @StorageLink('darkMode') darkMode: boolean = false;
  controller: CustomDialogController = new CustomDialogController({ builder: '' });
  onConfirm: () => void = () => {};

  build() {
    Column() {
      Text('删除记录').fontSize(18).fontWeight(FontWeight.Bold)
        .fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN)
        .margin({ bottom: 12 })
      Text('确定要删除这条记录吗？').fontSize(14)
        .fontColor(this.darkMode ? Dark.TEXT_HINT : Token.TEXT_HINT)
        .margin({ bottom: 24 })
      Row({ space: 12 }) {
        Button('取消').fontSize(14)
          .backgroundColor(this.darkMode ? Dark.BAR_TRACK : Token.BAR_TRACK)
          .fontColor(this.darkMode ? Dark.TEXT_SECONDARY : Token.TEXT_SECONDARY)
          .layoutWeight(1).onClick(() => { this.controller.close(); })
        Button('删除').fontSize(14).backgroundColor(Token.DELETE_RED).fontColor(Color.White)
          .layoutWeight(1).onClick(async () => { await this.onConfirm(); this.controller.close(); })
      }
      .width('100%')
    }
    .padding(24)
    .backgroundColor(this.darkMode ? Dark.CARD : Token.CARD)
  }
}

@Entry
@Component
struct EntryDetail {
  @StorageLink('darkMode') darkMode: boolean = false;
  @State recordId: string = '';
  @State record: MoodRecord | null = null;
  @State notFound: boolean = false;
  deleteDialog: CustomDialogController | null = null;

  aboutToAppear(): void {
    this.syncWindow();
    this.deleteDialog = new CustomDialogController({
      builder: DeleteConfirmDialog({
        onConfirm: () => { this.doDelete(); }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Center,
    });
    const p = this.getUIContext().getRouter().getParams() as Record<string, Object>;
    if (p && typeof p['recordId'] === 'string') {
      this.recordId = p['recordId'] as string;
      this.loadRecord();
    }
  }

  async loadRecord(): Promise<void> {
    const r = await DataManager.getRecordById(this.recordId);
    if (r) {
      this.record = r;
    } else {
      this.notFound = true;
    }
  }

  syncWindow(): void {
    const ctx = this.getUIContext().getHostContext();
    window.getLastWindow(ctx).then((wc) => {
      wc.setWindowBackgroundColor(this.darkMode ? '#1A1A2E' : '#F7F8FA');
    }).catch((err: Error) => {
      console.error('[MoodLite] syncWindow failed: ' + JSON.stringify(err));
    });
  }

  onEdit(): void {
    if (!this.record) return;
    setEditPayload({
      id: this.record.id,
      text: this.record.text,
      score: this.record.score,
      tags: this.record.tags,
    });
    AppStorage.setOrCreate('moodlite_tab', 1);
    AppStorage.setOrCreate('moodlite_nav_to_add', true);
    this.getUIContext().getRouter().back();
  }

  onDelete(): void {
    this.deleteDialog?.open();
  }

  async doDelete(): Promise<void> {
    await DataManager.deleteRecord(this.recordId);
    AppStorage.setOrCreate('moodlite_tab', 1);
    this.getUIContext().getRouter().back();
  }

  formatDate(dateStr: string): string {
    const parts = dateStr.split('-');
    return parseInt(parts[1]) + '月' + parseInt(parts[2]) + '日';
  }

  pageTransition() {
    PageTransitionEnter({ duration: 200, curve: Curve.EaseOut })
      .opacity(0.6)
    PageTransitionExit({ duration: 150, curve: Curve.EaseIn })
      .opacity(0)
  }

  build() {
    Column() {
      // 头部（Stack 居中标题，两侧分别放置返回和编辑按钮）
      Stack({ alignContent: Alignment.Center }) {
        Text('详情').fontSize(F.BODY).fontWeight(FontWeight.Medium)
          .fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN)

        Row() {
          Image($r('app.media.ic_back')).width(24).height(24).objectFit(ImageFit.Contain)
            .fillColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN)
            .onClick(() => { this.getUIContext().getRouter().back(); })
          Blank()
          Row({ space: 6 }) {
            Image($r('app.media.ic_edit')).width(16).height(16).fillColor(Token.TEXT_WHITE)
            Text('编辑').fontSize(14).fontWeight(FontWeight.Medium).fontColor(Token.TEXT_WHITE)
          }
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .backgroundColor(Token.PINK).borderRadius(R.FULL)
          .shadow(Shadow.CARD)
          .onClick(() => { this.onEdit(); })
        }
        .width('100%')
      }
      .width('100%')
      .padding({ top: S.HEADER_TOP, bottom: S.SM, left: S.LG, right: S.LG })

      if (this.notFound) {
        Column() {
          Text('记录不存在').fontSize(F.BODY)
            .fontColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY)
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.record !== null) {
        Scroll() {
          Column({ space: S.MD }) {
            GlassCard() {
              Column() {
                Image(getMoodIconResource(this.record.score))
                  .width(80).height(80).objectFit(ImageFit.Contain)
                  .margin({ bottom: 12 })

                Text(getMoodLabel(this.record.score))
                  .fontSize(22).fontWeight(FontWeight.Bold)
                  .fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN)

                Text(this.formatDate(this.record.dateStr))
                  .fontSize(14)
                  .fontColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY)
                  .margin({ top: 4, bottom: 20 })

                if (this.record.tags && this.record.tags.length > 0) {
                  Row() {
                    ForEach(this.record.tags, (t: string) => {
                      Text(t)
                        .fontSize(F.CAPTION).padding({ left: 10, right: 10, top: 3, bottom: 3 })
                        .borderRadius(R.FULL)
                        .fontColor(Token.PINK)
                        .backgroundColor(this.darkMode ? 'rgba(255,139,167,0.15)' : Token.PINK_LIGHT)
                        .margin({ right: 6 })
                    }, (t: string) => t)
                  }
                  .margin({ bottom: 16 })
                }

                Text(this.record.text || '没有记录文字')
                  .fontSize(F.BODY)
                  .fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN)
                  .lineHeight(26).textAlign(TextAlign.Center)
                  .width('100%')
              }
              .width('100%').alignItems(HorizontalAlign.Center).padding(20)
            }

            // 删除按钮
            Button() {
              Row({ space: 6 }) {
                Image($r('app.media.ic_delete')).width(16).height(16).fillColor(Token.DELETE_RED)
                Text('删除记录').fontSize(F.BODY).fontColor(Token.DELETE_RED)
              }
              .justifyContent(FlexAlign.Center)
            }
            .width('100%').height(44)
            .backgroundColor(this.darkMode ? Dark.CARD : Token.CARD)
            .borderRadius(12)
            .shadow({ radius: 12, color: 'rgba(0,0,0,0.08)', offsetY: 4 })
            .onClick(() => { this.onDelete(); })
          }
          .padding({ left: S.LG, right: S.LG, top: S.XS })
        }
        .layoutWeight(1).scrollBar(BarState.Off)
      }
    }
    .width('100%').height('100%')
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: this.darkMode
        ? [[Dark.PINK_LIGHT, 0.0], [Dark.BG, 1.0]]
        : [[Token.PINK_LIGHT, 0.0], [Token.TEXT_WHITE, 1.0]],
    })
  }
}
