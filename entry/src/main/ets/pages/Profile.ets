/**
 * Profile — v2.0 设置/我的（深色模式全适配 + 主题选择器）
 */

import { Token, R, S, F, DARK_INVERT, NORMAL_MATRIX } from '../common/styles';
import { GlassCard } from '../common/components/GlassCard';
import { enableDailyReminder, cancelReminder } from '../common/ReminderManager';
import ThemeManager, { ThemePreset, ThemePresetEntry, resolveColors } from '../common/ThemeManager';
import AuthManager from '../common/AuthManager';
import common from '@ohos.app.ability.common';
import type Want from '@ohos.app.ability.Want';

interface SItem { icon: Resource; label: string; toggle: boolean; }

interface PlanOption { label: string; value: string; }

const PLANS: PlanOption[] = [
  { label: 'Free — 基础记录', value: 'free' },
  { label: 'Pro — 每日提醒 + AI 3次/天', value: 'pro' },
  { label: 'Ultra — 无限 AI + 全功能', value: 'ultra' },
];

const ITEMS: SItem[] = [
  { icon: $r('app.media.ic_bell'),            label: '提醒设置',     toggle: true  },
  { icon: $r('app.media.ic_moon'),            label: '深色模式',     toggle: true  },
  { icon: $r('app.media.ic_message'),         label: '给我们反馈',   toggle: false },
  { icon: $r('app.media.ic_info'),            label: '关于 MoodLite',toggle: false },
];

// ========== 时间选择器弹窗 ==========

@CustomDialog
struct TimePickerDialog {
  @StorageLink('darkMode') darkMode: boolean = false;
  @StorageLink('currentTheme') currentTheme: string = 'blossomPink';
  controller: CustomDialogController = new CustomDialogController({ builder: TimePickerDialog() });
  hour: number = 20;
  minute: number = 0;
  onConfirm?: (h: number, m: number) => void;

  build() {
    Column() {
      Text('选择提醒时间').fontSize(F.BODY).fontWeight(FontWeight.Bold)
        .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_MAIN).margin({ bottom: S.MD })

      TimePicker({
        selected: new Date(2000, 0, 1, this.hour, this.minute),
        format: TimePickerFormat.HOUR_MINUTE,
      })
      .width('100%').height(160)
      .backgroundColor(resolveColors(this.darkMode, this.currentTheme).CARD)
      .selectedTextStyle({ color: resolveColors(this.darkMode, this.currentTheme).PINK, font: { size: 18, weight: FontWeight.Medium } })
      .disappearTextStyle({ color: resolveColors(this.darkMode, this.currentTheme).TEXT_GRAY, font: { size: 14 } })
      .onChange((v: TimePickerResult) => {
        if (v.hour !== undefined) this.hour = v.hour;
        if (v.minute !== undefined) this.minute = v.minute;
      })

      Button('确定')
        .width('100%').height(44).margin({ top: S.MD })
        .backgroundColor(resolveColors(this.darkMode, this.currentTheme).PINK).borderRadius(R.BUTTON)
        .fontSize(F.BODY).fontColor(resolveColors(this.darkMode, this.currentTheme).BTN_TEXT)
        .onClick(() => {
          if (this.onConfirm) this.onConfirm(this.hour, this.minute);
          this.controller.close();
        })
    }
    .width('100%').padding(S.LG)
    .backgroundColor(resolveColors(this.darkMode, this.currentTheme).CARD)
  }
}

// ========== 主题选择器弹窗 ==========

@CustomDialog
struct ThemePickerDialog {
  @StorageLink('darkMode') darkMode: boolean = false;
  @StorageLink('currentTheme') currentTheme: string = 'blossomPink';
  controller: CustomDialogController = new CustomDialogController({ builder: ThemePickerDialog() });

  build() {
    Column() {
      Text('选择主题风格').fontSize(F.BODY).fontWeight(FontWeight.Bold)
        .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_MAIN)
        .margin({ bottom: S.LG })

      ForEach(ThemeManager.getAllPresets(), (item: ThemePresetEntry) => {
        Column() {
          Row() {
            // 色块预览
            Row()
              .width(40).height(40)
              .borderRadius(R.SMALL)
              .backgroundColor(item.previewColor)
              .border({
                width: 1,
                color: 'rgba(0, 0, 0, 0.08)'
              })

            Column() {
              Text(item.displayName)
                .fontSize(F.BODY)
                .fontWeight(this.currentTheme === item.preset ? FontWeight.Bold : FontWeight.Regular)
                .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_MAIN)
            }
            .alignItems(HorizontalAlign.Start)
            .margin({ left: S.SM })

            Blank()

            // 选中态对勾
            if (this.currentTheme === item.preset) {
              Text('✓')
                .fontSize(F.SUBTITLE)
                .fontColor(resolveColors(this.darkMode, this.currentTheme).PINK)
                .fontWeight(FontWeight.Bold)
            }
          }
          .width('100%').height(56).alignItems(VerticalAlign.Center)
          .padding({ left: S.XS, right: S.XS })
          .borderRadius(R.SMALL)
          .backgroundColor(
            this.currentTheme === item.preset
              ? resolveColors(this.darkMode, this.currentTheme).PINK_LIGHT
              : 'transparent'
          )
          .onClick(() => {
            ThemeManager.setTheme(item.preset);
            this.controller.close();
          })
        }
        .width('100%')
      })
    }
    .width('100%').padding(S.LG)
    .backgroundColor(resolveColors(this.darkMode, this.currentTheme).CARD)
  }
}

// ========== 会员升级弹窗 ==========

@CustomDialog
struct UpgradeDialog {
  @StorageLink('darkMode') darkMode: boolean = false;
  @StorageLink('currentTheme') currentTheme: string = 'blossomPink';
  @StorageLink('memberType') memberType: string = 'free';
  controller: CustomDialogController = new CustomDialogController({ builder: UpgradeDialog({}) });
  currentMember: string = 'free';

  build() {
    Column() {
      Text('选择会员方案').fontSize(F.BODY).fontWeight(FontWeight.Bold)
        .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_MAIN)
        .margin({ bottom: S.LG })

      ForEach(PLANS, (item: PlanOption) => {
        Row() {
          Text(item.label).fontSize(F.BODY)
            .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_MAIN)
            .layoutWeight(1)
          if (this.memberType === item.value) {
            Text('✓').fontSize(F.SUBTITLE).fontColor(resolveColors(this.darkMode, this.currentTheme).PINK)
          }
        }
        .width('100%').height(48).padding({ left: S.XS, right: S.XS })
        .backgroundColor(this.memberType === item.value
          ? resolveColors(this.darkMode, this.currentTheme).PINK_LIGHT
          : 'transparent')
        .borderRadius(R.SMALL)
        .onClick(() => {
          AuthManager.upgradeMember(item.value);
          this.controller.close();
        })
      })
    }
    .width('100%').padding(S.LG)
    .backgroundColor(resolveColors(this.darkMode, this.currentTheme).CARD)
  }
}

// ========== Profile 主页面 ==========

@Entry
@Component
export struct Profile {
  @StorageLink('darkMode') darkMode: boolean = false;
  @StorageLink('isReminderOn') isReminderOn: boolean = false;
  @StorageLink('reminderHour') reminderHour: number = 20;
  @StorageLink('reminderMinute') reminderMinute: number = 0;
  @StorageLink('currentTheme') currentTheme: string = 'blossomPink';
  @StorageLink('memberType') memberType: string = 'free';

  private appContext(): Context {
    const uiCtx: UIContext = this.getUIContext();
    const hostCtx: Context | undefined = uiCtx.getHostContext();
    if (!hostCtx) {
      throw new Error('Failed to get application context');
    }
    return hostCtx;
  }

  private timeDialog: CustomDialogController | null = null;

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

  private themeDialog: CustomDialogController = new CustomDialogController({
    builder: ThemePickerDialog(),
    autoCancel: true,
    alignment: DialogAlignment.Bottom,
  });

  showThemeDialog(): void {
    this.themeDialog.open();
  }

  private upgradeDialog: CustomDialogController = new CustomDialogController({
    builder: UpgradeDialog({ currentMember: this.memberType }),
    autoCancel: true,
    alignment: DialogAlignment.Bottom,
  });

  showUpgradeDialog(): void {
    this.upgradeDialog.open();
  }

  fmtTime(): string {
    return String(this.reminderHour).padStart(2, '0') + ':' + String(this.reminderMinute).padStart(2, '0');
  }

  build() {
    Column() {
      Column() {
        Text('设置').fontSize(F.TITLE).fontWeight(FontWeight.Bold)
          .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_MAIN)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ top: S.HEADER_TOP, bottom: S.MD, left: S.LG, right: S.LG })

      Scroll() {
        Column() {
          // 会员卡片
          GlassCard() {
            Row() {
              Image($r('app.media.ic_sparkles')).width(28).height(28)
                .objectFit(ImageFit.Contain)
              Column() {
                if (this.memberType === 'ultra') {
                  Text('Ultra').fontSize(F.BODY).fontWeight(FontWeight.Bold).fontColor('#8B5CF6')
                } else if (this.memberType === 'pro') {
                  Text('Pro').fontSize(F.BODY).fontWeight(FontWeight.Bold).fontColor('#FFD700')
                } else {
                  Text('Free').fontSize(F.BODY).fontWeight(FontWeight.Bold)
                    .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_MAIN)
                }
                Text(this.memberType === 'free' ? '升级解锁更多功能' : '已解锁高级功能')
                  .fontSize(F.TINY).fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_HINT)
                  .margin({ top: 2 })
              }
              .alignItems(HorizontalAlign.Start).margin({ left: S.SM }).layoutWeight(1)
              Row({ space: 4 }) {
                Text('升级').fontSize(F.CAPTION).fontColor(resolveColors(this.darkMode, this.currentTheme).PINK)
                Image($r('app.media.ic_right_arrow')).width(14).height(14)
                  .fillColor(resolveColors(this.darkMode, this.currentTheme).PINK)
              }
              .padding({ left: S.SM, right: S.XS, top: S.XS, bottom: S.XS })
              .onClick(() => { this.showUpgradeDialog(); })
            }
            .width('100%').alignItems(VerticalAlign.Center)
            .padding({ top: S.SM, bottom: S.SM, left: S.MD, right: S.MD })
          }

          Row().width('100%').height(S.MD)

          GlassCard() {
            List() {
              ForEach(ITEMS, (it: SItem) => {
                ListItem() {
                  Row() {
                    Image(it.icon)
                      .width(24).height(24).objectFit(ImageFit.Contain)
                      .colorFilter(
                        this.darkMode ? DARK_INVERT : NORMAL_MATRIX
                      )
                    Text(it.label).fontSize(F.BODY)
                      .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_MAIN)
                      .margin({ left: S.SM })
                    Blank()

                    if (it.toggle) {
                      if (it.label === '提醒设置') {
                        if (this.isReminderOn) {
                          Text(this.fmtTime())
                            .fontSize(F.BODY).fontWeight(FontWeight.Medium)
                            .fontColor(resolveColors(this.darkMode, this.currentTheme).PINK).margin({ right: S.SM })
                            .padding({ left: S.SM, right: S.SM, top: 4, bottom: 4 })
                            .backgroundColor(resolveColors(this.darkMode, this.currentTheme).PINK_LIGHT).borderRadius(12)
                            .onClick(() => { this.showTimeDialog(); })
                        }

                        Toggle({ type: ToggleType.Switch, isOn: this.isReminderOn })
                          .selectedColor(resolveColors(this.darkMode, this.currentTheme).PINK)
                          .onChange((v: boolean) => {
                            this.isReminderOn = v;
                            if (v) this.showTimeDialog();
                            else cancelReminder();
                          })
                      } else if (it.label === '深色模式') {
                        Toggle({ type: ToggleType.Switch, isOn: this.darkMode })
                          .selectedColor(resolveColors(this.darkMode, this.currentTheme).PINK)
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
                      const ctx = this.appContext() as common.UIAbilityContext;
                      ctx.startAbility(want);
                    } else if (it.label === '关于 MoodLite') {
                      const want: Want = {
                        action: 'ohos.want.action.viewData',
                        entities: ['entity.system.browsable'],
                        uri: 'https://qcnvafay57br.feishu.cn/wiki/JVzvwaxhmiRMv4kyv8Rcyjz9nBe'
                      };
                      const ctx = this.appContext() as common.UIAbilityContext;
                      ctx.startAbility(want);
                    }
                  })
                }
              })

              // ---- 主题风格（独立 ListItem，在 ForEach 之后） ----
              ListItem() {
                Row() {
                  Image($r('app.media.ic_system'))
                    .width(24).height(24).objectFit(ImageFit.Contain)
                    .colorFilter(
                      this.darkMode ? DARK_INVERT : NORMAL_MATRIX
                    )
                  Text('主题风格').fontSize(F.BODY)
                    .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_MAIN)
                    .margin({ left: S.SM })
                  Blank()

                  Text(ThemeManager.getDisplayName(this.currentTheme as ThemePreset))
                    .fontSize(F.BODY).fontWeight(FontWeight.Medium)
                    .fontColor(resolveColors(this.darkMode, this.currentTheme).PINK).margin({ right: S.SM })
                    .padding({ left: S.SM, right: S.SM, top: 4, bottom: 4 })
                    .backgroundColor(resolveColors(this.darkMode, this.currentTheme).PINK_LIGHT).borderRadius(12)

                  Image($r('app.media.ic_right_arrow')).width(16).height(16)
                    .objectFit(ImageFit.Contain)
                    .fillColor(this.darkMode ? '#E8E8EC' : '#9CA3AF')
                    .colorFilter(
                      this.darkMode ? DARK_INVERT : NORMAL_MATRIX
                    )
                }
                .width('100%').height(56).alignItems(VerticalAlign.Center)
                .onClick(() => { this.showThemeDialog(); })
              }
            }
            .width('100%').divider({ strokeWidth: 0.5,
              color: resolveColors(this.darkMode, this.currentTheme).DIVIDER,
              startMargin: 48, endMargin: 0 })
          }

          // 退出登录
          GlassCard() {
            Row() {
              Text('退出登录').fontSize(F.BODY).fontColor(Token.DELETE_RED)
            }
            .width('100%').height(48).justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              AuthManager.logout();
              this.getUIContext().getRouter().replaceUrl({ url: 'pages/LoginPage' });
            })
          }

          Row().width('100%').height(S.LG)

          Row().width('100%').height(S.BOTTOM_BREATH)
        }
        .padding({ left: S.LG, right: S.LG, top: S.XS })
      }
      .layoutWeight(1).scrollBar(BarState.Off)
    }
    .width('100%').height('100%')
  }
}
