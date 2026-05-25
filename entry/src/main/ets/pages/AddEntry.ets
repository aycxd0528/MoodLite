/**
 * AddEntry — v2.0 记录交互页
 */

import curves from '@ohos.curves';
import vibrator from '@ohos.vibrator';
import window from '@ohos.window';
import DataManager from '../data/DataManager';
import { Token, Shadow, R, S, F } from '../common/styles';
import { resolveColors } from '../common/ThemeManager';
import { GlassCard } from '../common/components/GlassCard';
import { MoodRecord, generateUUID, formatDateStr, DEFAULT_TAGS } from '../model/MoodRecord';
import { getEditPayload } from '../common/EditBridge';
import { analyzeMood } from '../common/utils/AiAgentClient';

interface FaceEntry {
  min: number; max: number; icon: Resource; label: string; color: string; ms: number;
}

const FT: FaceEntry[] = [
  { min: 0,  max: 20, icon: $r('app.media.ic_face_terrible'), label: '很糟糕', color: '#8FB7E8', ms: -2 },
  { min: 21, max: 40, icon: $r('app.media.ic_face_bad'),      label: '不太好', color: Token.BLUE,  ms: -1 },
  { min: 41, max: 60, icon: $r('app.media.ic_face_neutral'),   label: '平静',   color: Token.TEXT_GRAY, ms:  0 },
  { min: 61, max: 80, icon: $r('app.media.ic_face_good'),      label: '不错',   color: Token.PINK, ms:  1 },
  { min: 81, max: 100,icon: $r('app.media.ic_face_awesome'),   label: '很棒',   color: Token.PINK, ms:  2 },
];

function findFace(v: number): FaceEntry {
  for (const e of FT) { if (v >= e.min && v <= e.max) return e; }
  return FT[2];
}

@Entry
@Component
struct AddEntry {
  @StorageLink('darkMode') darkMode: boolean = false;
  @StorageLink('currentTheme') currentTheme: string = 'blossomPink';
  @State sv: number = 50;
  @State txt: string = '';
  @State saving: boolean = false;
  private readonly MOOD_SNAPS: number[] = [10, 30, 50, 70, 90];
  @State emojiScale: number = 1.0;
  @State emojiOpacity: number = 1.0;
  @State editId: string = '';
  @State isEdit: boolean = false;
  @State selectedTags: string[] = [];
  @State customTag: string = '';
  @State showCustomInput: boolean = false;
  @State fromTab: number = 0;
  @State showSuccessOverlay: boolean = false;
  @State successScale: number = 0.3;
  @State successOpacity: number = 0.0;
  @State successFloat: number = 0;
  private successTimer1: number = -1;
  private successTimer2: number = -1;

  aboutToDisappear(): void {
    if (this.successTimer1 !== -1) { clearTimeout(this.successTimer1); this.successTimer1 = -1; }
    if (this.successTimer2 !== -1) { clearTimeout(this.successTimer2); this.successTimer2 = -1; }
  }

  aboutToAppear(): void {
    this.syncWindow();
    const p = this.getUIContext().getRouter().getParams() as Record<string, Object>;
    if (p && typeof p['fromTab'] === 'number') {
      this.fromTab = p['fromTab'];
    }
    const payload = getEditPayload();
    if (payload) {
      this.isEdit = true;
      this.editId = payload.id;
      this.txt = payload.text || '';
      this.selectedTags = payload.tags || [];
      const s = payload.score;
      if (s <= -2) this.sv = 10;
      else if (s === -1) this.sv = 30;
      else if (s === 0) this.sv = 50;
      else if (s === 1) this.sv = 70;
      else this.sv = 90;
      return;
    }
    if (p && typeof p['score'] === 'number') {
      const sc = p['score'];
      if (sc <= -2) this.sv = 10; else if (sc === -1) this.sv = 30;
      else if (sc === 0) this.sv = 50; else if (sc === 1) this.sv = 70;
      else this.sv = 90;
    }
  }

  syncWindow(): void {
    const ctx = this.getUIContext().getHostContext();
    window.getLastWindow(ctx).then((wc) => {
      wc.setWindowBackgroundColor(resolveColors(this.darkMode, this.currentTheme).BG);
    }).catch((err: Error) => {
      console.error('[MoodLite] syncWindow failed: ' + JSON.stringify(err));
    });
  }

  triggerEmojiBounce(): void {
    this.getUIContext()?.animateTo({ duration: 80, curve: Curve.EaseIn }, () => {
      this.emojiScale = 0.8;
      this.emojiOpacity = 0.6;
    });
    this.getUIContext()?.animateTo({ curve: curves.springMotion(0.4, 0.6) }, () => {
      this.emojiScale = 1.0;
      this.emojiOpacity = 1.0;
    });
  }

  async done(): Promise<void> {
    if (this.saving) return;
    if (this.txt.trim().length === 0) {
      try { this.getUIContext().getPromptAction().showToast({ message: '请写点什么吧', duration: 1500 }); } catch (_e) { console.debug('[MoodLite] toast failed: ' + JSON.stringify(_e)); }
      return;
    }
    this.saving = true;
    try {
      const f = findFace(this.sv);
      const useId = (this.isEdit && this.editId && this.editId.length > 0)
        ? this.editId : generateUUID();
      const record: MoodRecord = {
        id: useId,
        timestamp: Date.now(),
        dateStr: formatDateStr(new Date()),
        score: f.ms,
        text: this.txt,
        images: [],
        location: '',
        tags: this.selectedTags,
      };
      const ok = await DataManager.saveRecord(record);
      this.saving = false;
      if (ok) {
        // 触觉反馈
        try { vibrator.vibrate(15); } catch (_e) { console.debug('[MoodLite] vibrate skipped: ' + JSON.stringify(_e)); }

        // 沉浸式成功动画
        this.showSuccessOverlay = true;
        this.getUIContext()?.animateTo({ curve: curves.springMotion(0.4, 0.6) }, () => {
          this.successScale = 1.0;
          this.successOpacity = 1.0;
        });
        // 徽章微浮动动画（呼吸感）
        this.getUIContext()?.animateTo({ duration: 1200, curve: Curve.EaseInOut, iterations: -1 }, () => {
          this.successFloat = 6;
        });

        // 异步触发 AI 分析（非阻塞）
        if (record.score <= -1 && this.txt.trim().length > 0) {
          analyzeMood(this.txt).then((suggestion) => {
            if (suggestion) {
              AppStorage.setOrCreate('activeIntent', JSON.stringify(suggestion));
            }
          });
        } else {
          AppStorage.setOrCreate('activeIntent', null);
        }

        // 沉浸式过渡：展示 800ms → 退出动画 300ms → 跳转
        this.successTimer1 = setTimeout(() => {
          this.successTimer1 = -1;
          this.getUIContext()?.animateTo({ duration: 300, curve: Curve.EaseIn }, () => {
            this.successScale = 0.5;
            this.successOpacity = 0.0;
            this.emojiScale = 0.8;
          });
          this.successTimer2 = setTimeout(() => {
            this.successTimer2 = -1;
            this.showSuccessOverlay = false;
            AppStorage.setOrCreate('moodlite_tab', this.fromTab);
            this.getUIContext().getRouter().back();
          }, 350);
        }, 800);
      } else {
        console.error('[MoodLite] saveRecord returned false');
        try {
          this.getUIContext().getPromptAction().showToast({ message: '保存失败，请重试', duration: 2000 });
        } catch (_e) { console.debug('[MoodLite] toast failed: ' + JSON.stringify(_e)); }
      }
    } finally {
      this.saving = false;
    }
  }

  toast(msg: string): void {
    try { this.getUIContext().getPromptAction().showToast({ message: msg, duration: 2000 }); } catch (_e) { console.debug('[MoodLite] toast failed: ' + JSON.stringify(_e)); }
  }

  addCustomTag(): void {
    const t = this.customTag.trim();
    if (t && this.selectedTags.indexOf(t) < 0) {
      this.selectedTags.push(t);
      this.customTag = '';
    }
  }

  hasCustomTags(): string[] {
    return this.selectedTags.filter(t => DEFAULT_TAGS.indexOf(t) < 0);
  }

  @Builder tagChip(tag: string) {
    Text(tag)
      .fontSize(F.CAPTION)
      .padding({ left: 14, right: 14, top: 6, bottom: 6 })
      .borderRadius(R.FULL)
      .fontColor(this.selectedTags.indexOf(tag) >= 0 ? resolveColors(this.darkMode, this.currentTheme).PINK : resolveColors(this.darkMode, this.currentTheme).TEXT_MAIN)
      .backgroundColor(this.selectedTags.indexOf(tag) >= 0
        ? resolveColors(this.darkMode, this.currentTheme).PINK_LIGHT
        : resolveColors(this.darkMode, this.currentTheme).BAR_BG)
      .margin({ right: S.SM })
      .onClick(() => {
        const idx = this.selectedTags.indexOf(tag);
        if (idx >= 0) {
          this.selectedTags.splice(idx, 1);
        } else {
          this.selectedTags.push(tag);
        }
      })
  }

  pageTransition() {
    PageTransitionEnter({ duration: 200, curve: Curve.EaseOut })
      .opacity(0.6)
    PageTransitionExit({ duration: 150, curve: Curve.EaseIn })
      .opacity(0)
  }

  build() {
    Stack() {
      // === 底层：输入界面 ===
      Column() {
        // 头部（Stack 居中标题，两侧分别放置返回和完成按钮）
        Stack({ alignContent: Alignment.Center }) {
          Text(this.isEdit ? '编辑记录' : '新记录')
            .fontSize(F.BODY).fontWeight(FontWeight.Medium).fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_MAIN)

          Row() {
            Image($r('app.media.ic_back')).width(24).height(24).objectFit(ImageFit.Contain)
              .fillColor(resolveColors(this.darkMode, this.currentTheme).TEXT_MAIN)
              .onClick(() => { this.getUIContext().getRouter().back(); })
            Blank()
            Text('完成').fontSize(14).fontWeight(FontWeight.Medium).fontColor(resolveColors(this.darkMode, this.currentTheme).BTN_TEXT)
              .padding({ left: 16, right: 16, top: 7, bottom: 7 })
              .backgroundColor(this.saving ? resolveColors(this.darkMode, this.currentTheme).TEXT_GRAY : resolveColors(this.darkMode, this.currentTheme).PINK).borderRadius(R.FULL)
              .shadow(Shadow.CARD)
              .onClick(() => { this.done(); })
          }
          .width('100%')
        }
        .width('100%').padding({ top: S.HEADER_TOP, bottom: S.MD, left: S.LG, right: S.LG })

        Scroll() {
          Column({ space: S.MD }) {
            GlassCard() {
              Column() {
                Image(findFace(this.sv).icon).width(120).height(120).objectFit(ImageFit.Contain)
                  .margin({ bottom: S.MD }).scale({ x: this.emojiScale, y: this.emojiScale }).opacity(this.emojiOpacity)
                Text(findFace(this.sv).label).fontSize(F.SUBTITLE).fontWeight(FontWeight.Bold)
                  .fontColor(findFace(this.sv).color).margin({ bottom: S.MD })
                Slider({ value: this.sv, min: 0, max: 100, step: 1, style: SliderStyle.OutSet })
                  .width('100%').blockColor(resolveColors(this.darkMode, this.currentTheme).PINK)
                  .trackColor(resolveColors(this.darkMode, this.currentTheme).BLUE_LIGHT)
                  .selectedColor(resolveColors(this.darkMode, this.currentTheme).PINK).showTips(false).onChange((v: number, mode: SliderChangeMode) => {
                    const nearest = this.MOOD_SNAPS.reduce((prev, curr) =>
                      Math.abs(curr - v) < Math.abs(prev - v) ? curr : prev
                    );
                    if (mode === SliderChangeMode.Moving) {
                      if (nearest !== this.sv) {
                        this.sv = nearest;
                        this.triggerEmojiBounce();
                      }
                    } else if (mode === SliderChangeMode.End) {
                      this.sv = nearest;
                      try { vibrator.vibrate(10); } catch (_e) { console.debug('[MoodLite] vibrate skipped: ' + JSON.stringify(_e)); }
                    }
                  })
                Row() {
                  ForEach(FT, (f: FaceEntry) => {
                    Image(f.icon)
                      .width(24).height(24).objectFit(ImageFit.Contain)
                      .opacity(this.sv >= f.min && this.sv <= f.max ? 1 : 0.3)
                  }, (f: FaceEntry) => String(f.min))
                }
                .width('100%').justifyContent(FlexAlign.SpaceAround).margin({ top: S.SM })
              }
              .width('100%').alignItems(HorizontalAlign.Center)
            }

            GlassCard() {
              Column({ space: S.SM }) {
                Text('选择场景标签')
                  .fontSize(F.CAPTION).fontWeight(FontWeight.Medium)
                  .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_GRAY)

                Column({ space: S.XS }) {
                  Row() {
                    ForEach(DEFAULT_TAGS.slice(0, 3), (tag: string) => {
                      this.tagChip(tag)
                    }, (tag: string) => tag)
                  }
                  Row() {
                    ForEach(DEFAULT_TAGS.slice(3, 6), (tag: string) => {
                      this.tagChip(tag)
                    }, (tag: string) => tag)
                    ForEach(this.hasCustomTags(), (tag: string) => {
                      this.tagChip(tag)
                    }, (tag: string) => tag)
                  }
                }

                if (this.showCustomInput) {
                  Row({ space: S.XS }) {
                    TextInput({ placeholder: '输入自定义标签', text: this.customTag })
                      .height(36).layoutWeight(1)
                      .fontSize(F.CAPTION).fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_MAIN)
                      .placeholderColor(resolveColors(this.darkMode, this.currentTheme).TEXT_GRAY)
                      .backgroundColor(resolveColors(this.darkMode, this.currentTheme).BAR_BG)
                      .borderRadius(R.TINY)
                      .onChange((v: string) => { this.customTag = v; })
                      .onSubmit(() => { this.addCustomTag(); })

                    Button('确定')
                      .height(36).fontSize(F.CAPTION)
                      .backgroundColor(resolveColors(this.darkMode, this.currentTheme).PINK).borderRadius(R.TINY)
                      .fontColor(resolveColors(this.darkMode, this.currentTheme).BTN_TEXT)
                      .onClick(() => { this.addCustomTag(); })
                  }
                  .width('100%')
                } else {
                  Text('+ 自定义标签')
                    .fontSize(F.CAPTION).fontColor(resolveColors(this.darkMode, this.currentTheme).PINK)
                    .padding({ top: 2 })
                    .onClick(() => { this.showCustomInput = true; })
                }
              }
              .width('100%')
            }

            GlassCard() {
              TextArea({ placeholder: '今天有什么想记录的吗…', text: this.txt })
                .width('100%').height(100).backgroundColor('transparent').borderRadius(0)
                .fontSize(F.BODY).fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_MAIN).placeholderColor(resolveColors(this.darkMode, this.currentTheme).TEXT_GRAY)
                .onChange((v: string) => { this.txt = v; })
            }

            Row().height(S.BOTTOM_BREATH)
          }
          .padding({ left: S.LG, right: S.LG })
        }
        .layoutWeight(1).scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring)
      }
      .width('100%').height('100%')
      .linearGradient({
        direction: GradientDirection.Bottom,
        colors: [[resolveColors(this.darkMode, this.currentTheme).PINK_LIGHT, 0.0],
                 [resolveColors(this.darkMode, this.currentTheme).BG, 1.0]],
      })
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

      // === 顶层：沉浸式成功遮罩 ===
      if (this.showSuccessOverlay) {
        Column() {
          Blank()
          Column({ space: S.MD }) {
            Image(findFace(this.sv).icon)
              .width(120).height(120).objectFit(ImageFit.Contain)
              .scale({ x: this.successScale, y: this.successScale })
              .translate({ y: this.successFloat })

            Text('已保存')
              .fontSize(24).fontWeight(FontWeight.Bold)
              .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_MAIN)

            Text('记录已安全存储')
              .fontSize(F.CAPTION)
              .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_GRAY)
          }
          .alignItems(HorizontalAlign.Center)
          Blank()
        }
        .width('100%').height('100%')
        .backdropBlur(20)
        .backgroundColor(this.darkMode ? 'rgba(0,0,0,0.7)' : 'rgba(255,255,255,0.8)')
        .alignItems(HorizontalAlign.Center)
        .opacity(this.successOpacity)
        .onClick(() => { /* 拦截点击穿透 */ })
      }
    }
    .width('100%').height('100%')
  }

}
