/**
 * AddEntry — v2.0 记录交互页
 */

import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import curves from '@ohos.curves';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import vibrator from '@ohos.vibrator';
import DataManager from '../data/DataManager';
import { Token, Dark, Shadow, R, S, F } from '../common/styles';
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
  @State sv: number = 50;
  @State txt: string = '';
  @State saving: boolean = false;
  private readonly MOOD_SNAPS: number[] = [10, 30, 50, 70, 90];
  @State emojiScale: number = 1.0;
  @State emojiOpacity: number = 1.0;
  @State editId: string = '';
  @State isEdit: boolean = false;
  @State selectedImage: string = '';
  @State selectedTags: string[] = [];
  @State fromTab: number = 0;

  aboutToAppear(): void {
    const p = router.getParams() as Record<string, number>;
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

  triggerEmojiBounce(): void {
    animateTo({ duration: 80, curve: Curve.EaseIn }, () => {
      this.emojiScale = 0.8;
      this.emojiOpacity = 0.6;
    });
    animateTo({ curve: curves.springMotion(0.4, 0.6) }, () => {
      this.emojiScale = 1.0;
      this.emojiOpacity = 1.0;
    });
  }

  async selectImage(): Promise<void> {
    try {
      const picker = new photoAccessHelper.PhotoViewPicker();
      const result = await picker.select({
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1,
      });
      if (result && result.photoUris && result.photoUris.length > 0) {
        this.selectedImage = result.photoUris[0];
      }
    } catch (err) {
      try { promptAction.showToast({ message: '选择图片失败', duration: 1500 }); } catch (_e) { /* ignore */ }
    }
  }

  removeImage(): void { this.selectedImage = ''; }

  async done(): Promise<void> {
    if (this.saving) return;
    if (this.txt.trim().length === 0 && !this.selectedImage) {
      try { promptAction.showToast({ message: '请写点什么吧', duration: 1500 }); } catch (_e) { /* ignore */ }
      return;
    }
    this.saving = true;
    try {
      const f = findFace(this.sv);
      const useId = (this.isEdit && this.editId && this.editId.length > 0)
        ? this.editId : generateUUID();
      const images: string[] = this.selectedImage ? [this.selectedImage] : [];
      const record: MoodRecord = {
        id: useId,
        timestamp: Date.now(),
        dateStr: formatDateStr(new Date()),
        score: f.ms,
        text: this.txt,
        images: images,
        location: '',
        tags: this.selectedTags,
      };
      const ok = await DataManager.saveRecord(record);
      if (ok) {
        try { vibrator.vibrate(20); } catch (_e) { /* ignore */ }
        try { promptAction.showToast({ message: '已保存 ✅', duration: 1500, bottom: 400 }); } catch (_e) { /* ignore */ }

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

        router.replaceUrl({ url: 'pages/MainPage', params: { fromTab: this.fromTab } });
      }
    } finally {
      this.saving = false;
    }
  }

  toast(msg: string): void {
    try { promptAction.showToast({ message: msg, duration: 2000 }); } catch (_e) { /* ignore */ }
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.ic_back')).width(24).height(24).objectFit(ImageFit.Contain)
          .fillColor(this.darkMode ? '#E8E8EC' : '#1F2937')
          .colorFilter(
            this.darkMode
              ? [-1, 0, 0, 0, 255, 0, -1, 0, 0, 255, 0, 0, -1, 0, 255, 0, 0, 0, 1, 0]
              : [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0]
          )
          .onClick(() => { router.back(); })
        Blank()
        Text(this.isEdit ? '编辑记录' : '新记录')
          .fontSize(F.BODY).fontWeight(FontWeight.Medium).fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN)
        Blank()
        Row({ space: 4 }) {
          Text('完成').fontSize(14).fontWeight(FontWeight.Medium).fontColor(Token.TEXT_WHITE)
        }
        .padding({ left: 14, right: 14, top: 6, bottom: 6 })
        .backgroundColor(this.saving ? Token.TEXT_GRAY : Token.PINK).borderRadius(16)
        .shadow({ radius: 30, color: this.darkMode ? Dark.SHADOW_COLOR : Token.SHADOW_COLOR, offsetY: 10 })
        .onClick(() => { this.done(); })
      }
      .width('100%').padding({ top: S.HEADER_TOP, bottom: S.MD, left: S.MD, right: S.MD }).alignItems(VerticalAlign.Center)

      Scroll() {
        Column() {
          GlassCard() {
            Column() {
              Image(findFace(this.sv).icon).width(160).height(160).objectFit(ImageFit.Contain)
                .margin({ bottom: S.LG }).scale({ x: this.emojiScale, y: this.emojiScale }).opacity(this.emojiOpacity)
              Text(findFace(this.sv).label).fontSize(F.SUBTITLE).fontWeight(FontWeight.Bold)
                .fontColor(findFace(this.sv).color).margin({ bottom: S.MD })
              Slider({ value: this.sv, min: 0, max: 100, step: 1, style: SliderStyle.OutSet })
                .width('100%').blockColor(Token.PINK)
                .trackColor(this.darkMode ? Dark.BLUE_LIGHT : Token.BLUE_LIGHT)
                .selectedColor(Token.PINK).showTips(false).onChange((v: number, mode: SliderChangeMode) => {
                  const nearest = this.MOOD_SNAPS.reduce((prev, curr) =>
                    Math.abs(curr - v) < Math.abs(prev - v) ? curr : prev
                  );
                  if (mode === SliderChangeMode.Moving) {
                    if (nearest !== this.sv) {
                      this.sv = nearest;
                      try { vibrator.vibrate(15); } catch (_e) { /* ignore */ }
                      this.triggerEmojiBounce();
                    }
                  } else if (mode === SliderChangeMode.End) {
                    this.sv = nearest;
                  }
                })
              Row() {
                ForEach(FT, (f: FaceEntry, i: number) => {
                  Image(f.icon)
                    .width(28).height(28).objectFit(ImageFit.Contain)
                    .opacity(this.sv >= f.min && this.sv <= f.max ? 1 : 0.3)
                }, (f: FaceEntry) => String(f.min))
              }
              .width('100%').justifyContent(FlexAlign.SpaceAround).margin({ top: S.SM })
            }
            .width('100%').alignItems(HorizontalAlign.Center)
          }

          Column() {
            GlassCard() {
              Column({ space: S.SM }) {
                TextArea({ placeholder: '今天有什么想记录的吗…', text: this.txt })
                  .width('100%').height(80).backgroundColor('transparent').borderRadius(0)
                  .fontSize(F.BODY).fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN).placeholderColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY)
                  .onChange((v: string) => { this.txt = v; })

                Flex({ wrap: FlexWrap.Wrap }) {
                  ForEach(DEFAULT_TAGS, (tag: string) => {
                    Text(tag)
                      .fontSize(F.CAPTION)
                      .padding({ left: 14, right: 14, top: 6, bottom: 6 })
                      .borderRadius(R.FULL)
                      .fontColor(this.selectedTags.indexOf(tag) >= 0 ? Token.TEXT_WHITE : (this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY))
                      .backgroundColor(this.selectedTags.indexOf(tag) >= 0 ? Token.PINK : (this.darkMode ? Dark.BUBBLE_BG : Token.BAR_BG))
                      .margin({ right: S.XS, bottom: S.XS })
                      .onClick(() => {
                        const idx = this.selectedTags.indexOf(tag);
                        if (idx >= 0) {
                          this.selectedTags.splice(idx, 1);
                        } else {
                          this.selectedTags.push(tag);
                        }
                      })
                  }, (tag: string) => tag)
                }
                .width('100%')

                Row() {
                  Image($r('app.media.ic_tag'))
                    .width(22).height(22)
                    .opacity(this.selectedTags.length > 0 ? 1 : 0.35)
                    .fillColor(this.selectedTags.length > 0 ? Token.PINK : (this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY))
                  Blank()
                  Image($r('app.media.ic_image'))
                    .width(22).height(22)
                    .opacity(0.5).fillColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY)
                    .onClick(() => { this.selectImage(); })
                }
                .width('100%')
              }
              .width('100%')
            }
          }
          .margin({ top: S.MD })

          // 选中图片预览
          if (this.selectedImage) {
            Column() {
              Stack() {
                Image(this.selectedImage)
                  .width('100%').height(200).objectFit(ImageFit.Cover)
                  .borderRadius(R.SMALL)

                Row() {
                  Image($r('app.media.ic_delete')).width(20).height(20).fillColor(Color.White)
                }
                .width(32).height(32)
                .backgroundColor('rgba(0,0,0,0.45)')
                .borderRadius(16)
                .justifyContent(FlexAlign.Center)
                .position({ top: 8, right: 8 })
                .onClick(() => { this.removeImage(); })
              }
              .width('100%')
            }
            .margin({ top: S.MD })
          }

          Row()
            .width('100%')
            .height(S.BOTTOM_BREATH)
        }
        .padding({ left: S.LG, right: S.LG })
      }
      .layoutWeight(1).scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring)
    }
    .width('100%').height('100%').backgroundColor(this.darkMode ? Dark.BG : Token.BG)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

}
