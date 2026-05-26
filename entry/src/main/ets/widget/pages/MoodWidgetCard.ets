/**
 * MoodWidgetCard — 2×2 桌面情绪小组件 (v3.0 极简今日状态)
 *
 * 仅展示今日情绪表情、标签与连续记录天数，整体点击拉起主应用。
 * 支持暗色模式自适应。
 */

@Entry
@Component
struct MoodWidgetCard {
  @LocalStorageProp('moodLabel') moodLabel: string = 'MoodLite';
  @LocalStorageProp('streak') streak: number = 0;
  @LocalStorageProp('todayScore') todayScore: number = 0;
  @LocalStorageProp('darkMode') darkMode: number = 0;

  getFaceIcon(score: number): Resource {
    if (score <= -2) return $r('app.media.ic_face_terrible');
    if (score === -1) return $r('app.media.ic_face_bad');
    if (score === 0)  return $r('app.media.ic_face_neutral');
    if (score === 1)  return $r('app.media.ic_face_good');
    return $r('app.media.ic_face_awesome');
  }

  build() {
    Stack() {
      // 装饰光晕
      Circle()
        .width('70%').height('70%')
        .fill(this.darkMode ? 'rgba(255, 255, 255, 0.04)' : 'rgba(255, 139, 167, 0.06)')
        .blendMode(BlendMode.SRC_OVER)
        .position({ x: '-15%', y: '-15%' })

      // 毛玻璃卡片
      Column() {
        Blank()

        Image(this.getFaceIcon(this.todayScore))
          .width(72).height(72)
          .objectFit(ImageFit.Contain)
          .margin({ bottom: 6 })

        Text(this.moodLabel)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.darkMode ? '#E8E8EC' : '#1A1A1A')
          .opacity(0.85)

        if (this.streak > 0) {
          Text('连续 ' + this.streak + ' 天')
            .fontSize(11)
            .fontColor(this.darkMode ? '#AAAAAA' : '#9CA3AF')
            .margin({ top: 3 })
        }

        Blank()
      }
      .width('100%').height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(this.darkMode ? 'rgba(255, 255, 255, 0.08)' : 'rgba(255, 255, 255, 0.12)')
      .backdropBlur(20)
      .border({
        width: 0.5,
        color: this.darkMode ? 'rgba(255, 255, 255, 0.10)' : 'rgba(255, 255, 255, 0.20)',
      })
      .borderRadius(24)
    }
    .width('100%').height('100%')
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: { targetPage: 'pages/MainPage' }
      });
    })
  }
}
