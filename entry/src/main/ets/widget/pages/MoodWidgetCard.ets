/**
 * MoodWidgetCard — 2×2 桌面情绪小组件 (v2.0 毛玻璃 + 无感快捷记录)
 *
 * 视觉：Glassmorphism 毛玻璃规范 — 半透明背景 + backdropBlur + 极弱边框高光线
 * 交互：卡片整体点击拉起主应用；底部五个快捷按钮通过 postCardAction message 静默记录
 *
 * 表情图标使用与主应用完全一致的 ic_face_*.png 资源，不再使用 Unicode emoji。
 */

interface QuickAction {
  icon: Resource;
  score: number;
}

// 与 AddEntry 页滑块顺序严格一致：很糟糕 → 不太好 → 平静 → 不错 → 很棒
const QUICK_ACTIONS: QuickAction[] = [
  { icon: $r('app.media.ic_face_terrible'), score: -2 },
  { icon: $r('app.media.ic_face_bad'),      score: -1 },
  { icon: $r('app.media.ic_face_neutral'),  score: 0 },
  { icon: $r('app.media.ic_face_good'),     score: 1 },
  { icon: $r('app.media.ic_face_awesome'),  score: 2 },
];

/** 根据 score 返回与 app 完全一致的表情资源 */
function getFaceIcon(score: number): Resource {
  if (score <= -2) return $r('app.media.ic_face_terrible');
  if (score === -1) return $r('app.media.ic_face_bad');
  if (score === 0)  return $r('app.media.ic_face_neutral');
  if (score === 1)  return $r('app.media.ic_face_good');
  return $r('app.media.ic_face_awesome');
}

@Entry
@Component
struct MoodWidgetCard {
  @LocalStorageProp('moodLabel') moodLabel: string = 'MoodLite';
  @LocalStorageProp('streak') streak: number = 0;
  @LocalStorageProp('todayScore') todayScore: number = 0;

  build() {
    Stack() {
      // ---- 底层：装饰光晕 ----
      Circle()
        .width('65%').height('65%')
        .fill('rgba(255, 139, 167, 0.06)')
        .blendMode(BlendMode.SRC_OVER)
        .position({ x: '-15%', y: '-15%' })

      // ---- 中层：毛玻璃卡片主体 ----
      Column() {
        // 主情绪展示区（与 App 中 ic_face_*.png 完全一致）
        Column() {
          Image(getFaceIcon(this.todayScore))
            .width(64).height(64)
            .objectFit(ImageFit.Contain)
            .margin({ bottom: 4 })

          Text(this.moodLabel)
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
            .opacity(0.85)

          if (this.streak > 0) {
            Text('连续 ' + this.streak + ' 天')
              .fontSize(10)
              .fontColor('#9CA3AF')
              .margin({ top: 2 })
          }
        }
        .width('100%').layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        // ---- 底部快捷记录栏（五个表情图片） ----
        Row() {
          ForEach(QUICK_ACTIONS, (item: QuickAction) => {
            Column() {
              Image(item.icon)
                .width(28).height(28)
                .objectFit(ImageFit.Contain)
            }
            .width(32).height(32)
            .borderRadius(16)
            .backgroundColor('rgba(255, 255, 255, 0.45)')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .onClick(() => {
              postCardAction(this, {
                action: 'message',
                params: {
                  action: 'quick_log',
                  score: item.score,
                }
              });
            })
          }, (item: QuickAction) => item.score.toString())
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceEvenly)
        .alignItems(VerticalAlign.Center)
        .padding({ top: 6, bottom: 10, left: 8, right: 8 })
      }
      .width('100%').height('100%')
      .backgroundColor('rgba(255, 255, 255, 0.12)')
      .backdropBlur(20)
      .border({
        width: 0.5,
        color: 'rgba(255, 255, 255, 0.20)',
      })
      .borderRadius(24)
      .onClick(() => {
        postCardAction(this, {
          action: 'router',
          abilityName: 'EntryAbility',
          params: { targetPage: 'pages/MainPage' }
        });
      })
    }
    .width('100%').height('100%')
  }
}
