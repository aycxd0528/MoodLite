/**
 * MoodWidgetCard — 2×2 桌面情绪小组件
 *
 * 通过 @LocalStorageProp 接收 EntryFormAbility 推送的实时数据。
 * 数据由 WidgetSyncManager.updateWidgets() 在每次保存/删除记录后触发更新。
 */

@Entry
@Component
struct MoodWidgetCard {
  @LocalStorageProp('mood') mood: string = '😐';
  @LocalStorageProp('moodLabel') moodLabel: string = 'MoodLite';
  @LocalStorageProp('streak') streak: number = 0;

  build() {
    Stack() {
      Column()
        .width('100%').height('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [['#FFF5F7', 0.0], ['#FFFFFF', 1.0]]
        })

      Column() {
        Text(this.mood)
          .fontSize(48)
          .margin({ bottom: 6 })

        Text(this.moodLabel)
          .fontSize(14).fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')

        if (this.streak > 0) {
          Text('连续 ' + this.streak + ' 天')
            .fontSize(10).fontColor('#9CA3AF')
            .margin({ top: 3 })
        }
      }
      .width('100%').height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
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
