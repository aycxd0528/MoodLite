/**
 * Widget1Card — 2×4 桌面情绪小组件 (v3.0 今日摘要 + 本月概览)
 *
 * 上排：今日情绪图标 + 标签 + 连续天数
 * 下排：本月情绪概览 — 愉悦 / 低落 / 平静 / 记录天数 四栏
 */

@Entry
@Component
struct Widget1Card {
  @LocalStorageProp('todayScore') todayScore: number = 0;
  @LocalStorageProp('moodLabel') moodLabel: string = 'MoodLite';
  @LocalStorageProp('streak') streak: number = 0;
  @LocalStorageProp('recordDays') recordDays: number = 0;
  @LocalStorageProp('happyPercent') happyPercent: number = 0;
  @LocalStorageProp('sadPercent') sadPercent: number = 0;
  @LocalStorageProp('neutralPercent') neutralPercent: number = 0;
  @LocalStorageProp('darkMode') darkMode: number = 0;

  getFaceIcon(score: number): Resource {
    if (score <= -2) return $r('app.media.ic_face_terrible');
    if (score === -1) return $r('app.media.ic_face_bad');
    if (score === 0)  return $r('app.media.ic_face_neutral');
    if (score === 1)  return $r('app.media.ic_face_good');
    return $r('app.media.ic_face_awesome');
  }

  build() {
    FormLink({
      action: 'router',
      abilityName: 'EntryAbility',
      params: { targetPage: 'pages/MainPage', tab: 3 }
    }) {
      Column() {
        // ---- 上排：今日摘要 ----
        Row() {
          Image(this.getFaceIcon(this.todayScore))
            .width(36).height(36)
            .objectFit(ImageFit.Contain)

          Text(this.moodLabel)
            .fontSize(14).fontWeight(FontWeight.Bold)
            .fontColor(this.darkMode ? '#E8E8EC' : '#333333')
            .margin({ left: 8 })

          Blank()

          if (this.streak > 0) {
            Text('连续 ' + this.streak + ' 天')
              .fontSize(11).fontColor(this.darkMode ? '#AAAAAA' : '#888888')
          }
        }
        .width('100%')
        .padding({ left: 14, right: 14, top: 10, bottom: 4 })

        // ---- 下排：本月情绪概览 ----
        Row() {
          // 愉悦
          Column() {
            Image($r('app.media.ic_face_good')).width(28).height(28).objectFit(ImageFit.Contain)
            Text(this.happyPercent + '%').fontSize(18).fontWeight(FontWeight.Bold)
              .fontColor(this.darkMode ? '#E8E8EC' : '#333333').margin({ top: 2 })
            Text('愉悦').fontSize(10)
              .fontColor(this.darkMode ? '#AAAAAA' : '#999999').margin({ top: 1 })
          }.alignItems(HorizontalAlign.Center).layoutWeight(1)

          // 低落
          Column() {
            Image($r('app.media.ic_face_bad')).width(28).height(28).objectFit(ImageFit.Contain)
            Text(this.sadPercent + '%').fontSize(18).fontWeight(FontWeight.Bold)
              .fontColor(this.darkMode ? '#E8E8EC' : '#333333').margin({ top: 2 })
            Text('低落').fontSize(10)
              .fontColor(this.darkMode ? '#AAAAAA' : '#999999').margin({ top: 1 })
          }.alignItems(HorizontalAlign.Center).layoutWeight(1)

          // 平静
          Column() {
            Image($r('app.media.ic_face_neutral')).width(28).height(28).objectFit(ImageFit.Contain)
            Text(this.neutralPercent + '%').fontSize(18).fontWeight(FontWeight.Bold)
              .fontColor(this.darkMode ? '#E8E8EC' : '#333333').margin({ top: 2 })
            Text('平静').fontSize(10)
              .fontColor(this.darkMode ? '#AAAAAA' : '#999999').margin({ top: 1 })
          }.alignItems(HorizontalAlign.Center).layoutWeight(1)

          // 记录天数
          Column() {
            Image($r('app.media.bullseye')).width(28).height(28).objectFit(ImageFit.Contain)
            Text(String(this.recordDays)).fontSize(18).fontWeight(FontWeight.Bold)
              .fontColor(this.darkMode ? '#E8E8EC' : '#333333').margin({ top: 2 })
            Text('记录').fontSize(10)
              .fontColor(this.darkMode ? '#AAAAAA' : '#999999').margin({ top: 1 })
          }.alignItems(HorizontalAlign.Center).layoutWeight(1)
        }
        .width('100%').layoutWeight(1)
        .alignItems(VerticalAlign.Center)
        .padding({ left: 8, right: 8 })
      }
      .width('100%').height('100%')
      .backgroundColor(this.darkMode ? 'rgba(255, 255, 255, 0.06)' : 'rgba(255, 255, 255, 0.12)')
      .backdropBlur(16)
      .border({
        width: 0.5,
        color: this.darkMode ? 'rgba(255, 255, 255, 0.08)' : 'rgba(255, 255, 255, 0.20)',
      })
      .borderRadius(24)
    }
    .width('100%').height('100%')
  }
}
