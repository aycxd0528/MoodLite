@Entry
@Component
struct MoodWidgetCard {
  build() {
    Stack() {
      Column()
        .width('100%').height('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [['#FFF5F7', 0.0], ['#FFFFFF', 1.0]]
        })

      Column() {
        Image($r('app.media.ic_face_good'))
          .width(52).height(52)
          .margin({ bottom: 8 })

        Text('MoodLite').fontSize(14).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
        Text('点击记心情').fontSize(10).fontColor('#999999').margin({ top: 4 })
      }
      .width('100%').height('100%')
      .justifyContent(FlexAlign.Center)
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
