/**
 * Profile — v2.0 设置/我的（深色模式全适配 + 主题选择器）
 */

import { R, S, F } from '../common/styles';
import { GlassCard } from '../common/components/GlassCard';
import ThemeManager, { ThemePreset, ThemePresetEntry, resolveColors } from '../common/ThemeManager';

interface SItem { icon: Resource; label: string; toggle: boolean; }

const ITEMS: SItem[] = [
  { icon: $r('app.media.ic_moon'),            label: '深色模式',     toggle: true  },
  { icon: $r('app.media.ic_shield'),          label: '数据与隐私',   toggle: false },
  { icon: $r('app.media.ic_info'),            label: '关于 MoodLite',toggle: false },
];

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

// ========== Profile 主页面 ==========

@Component
export struct Profile {
  @StorageLink('darkMode') darkMode: boolean = false;
  @StorageLink('currentTheme') currentTheme: string = 'blossomPink';

  private themeDialog: CustomDialogController = new CustomDialogController({
    builder: ThemePickerDialog(),
    autoCancel: true,
    alignment: DialogAlignment.Bottom,
  });

  showThemeDialog(): void {
    this.themeDialog = new CustomDialogController({
      builder: ThemePickerDialog(),
      autoCancel: true,
      alignment: DialogAlignment.Bottom,
    });
    this.themeDialog.open();
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
                      .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_MAIN)
                      .margin({ left: S.SM })
                    Blank()

                    if (it.toggle) {
                      if (it.label === '深色模式') {
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
                    if (it.label === '数据与隐私') {
                      this.getUIContext().getRouter().pushUrl({ url: 'pages/DataPrivacyPage' });
                    } else if (it.label === '关于 MoodLite') {
                      this.getUIContext().getRouter().pushUrl({ url: 'pages/AboutPage' });
                    }
                  })
                }
              })

              // ---- 主题风格（独立 ListItem，在 ForEach 之后） ----
              ListItem() {
                Row() {
                  Image($r('app.media.ic_moon'))
                    .width(24).height(24).objectFit(ImageFit.Contain)
                    .colorFilter(
                      this.darkMode
                        ? [-1, 0, 0, 0, 255, 0, -1, 0, 0, 255, 0, 0, -1, 0, 255, 0, 0, 0, 1, 0]
                        : [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0]
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
                      this.darkMode
                        ? [-1, 0, 0, 0, 255, 0, -1, 0, 0, 255, 0, 0, -1, 0, 255, 0, 0, 0, 1, 0]
                        : [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0]
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

          Row().width('100%').height(S.BOTTOM_BREATH)
        }
        .padding({ left: S.LG, right: S.LG, top: S.XS })
      }
      .layoutWeight(1).scrollBar(BarState.Off)
    }
    .width('100%').height('100%')
  }
}
