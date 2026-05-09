/**
 * Profile — v2.0 设置/我的（深色模式全适配）
 */

import { Token, Dark, R, S, F } from '../common/styles';
import { GlassCard } from '../common/components/GlassCard';
import { enableDailyReminder, cancelReminder } from '../common/ReminderManager';
import common from '@ohos.app.ability.common';
import type Want from '@ohos.app.ability.Want';

interface SItem { icon: Resource; label: string; toggle: boolean; }

const ITEMS: SItem[] = [
  { icon: $r('app.media.ic_bell'),            label: '提醒设置',     toggle: true  },
  { icon: $r('app.media.ic_moon'),            label: '深色模式',     toggle: true  },
  { icon: $r('app.media.ic_message'),         label: '给我们反馈',   toggle: false },
  { icon: $r('app.media.ic_info'),            label: '关于 MoodLite',toggle: false },
];

@CustomDialog
struct TimePickerDialog {
  @StorageLink('darkMode') darkMode: boolean = false;
  controller: CustomDialogController = new CustomDialogController({ builder: TimePickerDialog() });
  hour: number = 20;
  minute: number = 0;
  onConfirm?: (h: number, m: number) => void;

  build() {
    Column() {
      Text('选择提醒时间').fontSize(F.BODY).fontWeight(FontWeight.Bold)
        .fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN).margin({ bottom: S.MD })

      TimePicker({
        selected: new Date(2000, 0, 1, this.hour, this.minute),
        format: TimePickerFormat.HOUR_MINUTE,
      })
      .width('100%').height(160)
      .backgroundColor(this.darkMode ? Dark.CARD : 'transparent')
      .selectedTextStyle({ color: Token.PINK, font: { size: 18, weight: FontWeight.Medium } })
      .disappearTextStyle({ color: this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY, font: { size: 14 } })
      .onChange((v: TimePickerResult) => {
        if (v.hour !== undefined) this.hour = v.hour;
        if (v.minute !== undefined) this.minute = v.minute;
      })

      Button('确定')
        .width('100%').height(44).margin({ top: S.MD })
        .backgroundColor(Token.PINK).borderRadius(R.BUTTON)
        .fontSize(F.BODY).fontColor(Token.TEXT_WHITE)
        .onClick(() => {
          if (this.onConfirm) this.onConfirm(this.hour, this.minute);
          this.controller.close();
        })
    }
    .width('100%').padding(S.LG)
    .backgroundColor(this.darkMode ? Dark.CARD : Token.CARD)
  }
}

@Entry
@Component
export struct Profile {
  @StorageLink('darkMode') darkMode: boolean = false;
  @StorageLink('isReminderOn') isReminderOn: boolean = false;
  @StorageLink('reminderHour') reminderHour: number = 20;
  @StorageLink('reminderMinute') reminderMinute: number = 0;

  private appContext(): Context {
    const uiCtx: UIContext = this.getUIContext();
    const hostCtx: Context | undefined = uiCtx.getHostContext();
    if (!hostCtx) {
      throw new Error('Failed to get application context');
    }
    return hostCtx;
  }

  private timeDialog: CustomDialogController = new CustomDialogController({
    builder: TimePickerDialog({
      hour: this.reminderHour,
      minute: this.reminderMinute,
      onConfirm: (h: number, m: number) => {
        this.reminderHour = h;
        this.reminderMinute = m;
        enableDailyReminder(this.appContext(), h, m);
      }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Bottom,
  });

  showTimeDialog(): void {
    this.timeDialog = new CustomDialogController({
      builder: TimePickerDialog({
        hour: this.reminderHour,
        minute: this.reminderMinute,
        onConfirm: (h: number, m: number) => {
          this.reminderHour = h;
          this.reminderMinute = m;
          enableDailyReminder(this.appContext(), h, m);
        }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Bottom,
    });
    this.timeDialog.open();
  }

  fmtTime(): string {
    return String(this.reminderHour).padStart(2, '0') + ':' + String(this.reminderMinute).padStart(2, '0');
  }

  build() {
    Column() {
      Column() {
        Text('设置').fontSize(F.TITLE).fontWeight(FontWeight.Bold)
          .fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ top: S.HEADER_TOP, bottom: S.MD, left: S.LG, right: S.LG })

      Scroll() {
        Column() {
          GlassCard() {
            List() {
              ForEach(ITEMS, (it: SItem) => {
                ListItem() {
                  Row() {
                    Image(it.icon)
                      .width(24).height(24).objectFit(ImageFit.Contain)
                      .colorFilter(
                        this.darkMode
                          ? [
                              -1,  0,  0,  0, 255,
                               0, -1,  0,  0, 255,
                               0,  0, -1,  0, 255,
                               0,  0,  0,  1,   0
                            ]
                          : [
                               1,  0,  0,  0,   0,
                               0,  1,  0,  0,   0,
                               0,  0,  1,  0,   0,
                               0,  0,  0,  1,   0
                            ]
                      )
                    Text(it.label).fontSize(F.BODY)
                      .fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN)
                      .margin({ left: S.SM })
                    Blank()

                    if (it.toggle) {
                      if (it.label === '提醒设置') {
                        if (this.isReminderOn) {
                          Text(this.fmtTime())
                            .fontSize(F.BODY).fontWeight(FontWeight.Medium)
                            .fontColor(Token.PINK).margin({ right: S.SM })
                            .padding({ left: S.SM, right: S.SM, top: 4, bottom: 4 })
                            .backgroundColor('#1AFF8BA7').borderRadius(12)
                            .onClick(() => { this.showTimeDialog(); })
                        }

                        Toggle({ type: ToggleType.Switch, isOn: this.isReminderOn })
                          .selectedColor(Token.PINK)
                          .onChange((v: boolean) => {
                            this.isReminderOn = v;
                            if (v) this.showTimeDialog();
                            else cancelReminder();
                          })
                      } else if (it.label === '深色模式') {
                        Toggle({ type: ToggleType.Switch, isOn: this.darkMode })
                          .selectedColor(Token.PINK)
                          .onChange((v: boolean) => { this.darkMode = v; })
                      }
                    } else {
                      Image($r('app.media.ic_right_arrow')).width(16).height(16)
                        .objectFit(ImageFit.Contain)
                        .fillColor(this.darkMode ? '#E8E8EC' : '#9CA3AF')
                        .colorFilter(
                          this.darkMode
                            ? [-1, 0, 0, 0, 255, 0, -1, 0, 0, 255, 0, 0, -1, 0, 255, 0, 0, 0, 1, 0]
                            : [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0]
                        )
                    }
                  }
                  .width('100%').height(56).alignItems(VerticalAlign.Center)
                  .onClick(() => {
                    if (it.label === '给我们反馈') {
                      const want: Want = {
                        action: 'ohos.want.action.viewData',
                        entities: ['entity.system.browsable'],
                        uri: 'https://qcnvafay57br.feishu.cn/share/base/form/shrcnYp5ebjhkpaHKc6FA0Lw1me'
                      };
                      const ctx = getContext(this) as common.UIAbilityContext;
                      ctx.startAbility(want);
                    } else if (it.label === '关于 MoodLite') {
                      const want: Want = {
                        action: 'ohos.want.action.viewData',
                        entities: ['entity.system.browsable'],
                        uri: 'https://qcnvafay57br.feishu.cn/wiki/JVzvwaxhmiRMv4kyv8Rcyjz9nBe'
                      };
                      const ctx = getContext(this) as common.UIAbilityContext;
                      ctx.startAbility(want);
                    }
                  })
                }
              })
            }
            .width('100%').divider({ strokeWidth: 0.5,
              color: this.darkMode ? Dark.DIVIDER : Token.DIVIDER,
              startMargin: 48, endMargin: 0 })
          }

          Row().width('100%').height(S.BOTTOM_BREATH)
        }
        .padding({ left: S.LG, right: S.LG, top: S.XS })
      }
      .layoutWeight(1).scrollBar(BarState.Off)
    }
    .width('100%').height('100%')
  }
}
