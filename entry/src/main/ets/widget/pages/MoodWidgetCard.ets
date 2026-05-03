/**
 * MoodWidgetCard —— 桌面小组件卡片 (2x2)
 *
 * 设计：轻量毛玻璃卡片，展示当前情绪 + 连续天数
 * 严格贯彻 MoodLite 视觉规范。
 */

import { Token, Dark } from '../../common/styles';

@Entry
@Component
struct MoodWidgetCard {
  @LocalStorageProp('mood') mood: string = '😐';
  @LocalStorageProp('moodLabel') moodLabel: string = 'MoodLite';
  @LocalStorageProp('streak') streak: number = 0;
  @LocalStorageProp('todayMood') todayMood: string = '--';
  @LocalStorageProp('darkMode') darkMode: boolean = false;

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: this.darkMode
            ? [[Dark.PINK_LIGHT, 0.0], [Dark.CARD, 1.0]]
            : [[Token.PINK_LIGHT, 0.0], [Token.CARD, 1.0]],
        })

      Column() {
        Text('MoodLite')
          .fontSize(12)
          .fontColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY)
          .margin({ bottom: 8 })

        Text(this.mood)
          .fontSize(48)
          .margin({ bottom: 6 })

        Text(this.moodLabel)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN)

        Row() {
          Text('🔥')
            .fontSize(14)
          Text('连续 ' + this.streak + ' 天')
            .fontSize(13)
            .fontColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY)
            .margin({ left: 4 })
        }
        .margin({ top: 10 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .padding(16)
    }
    .width('100%')
    .height('100%')
    .borderRadius(20)
    .backgroundColor(this.darkMode ? Dark.CARD : Token.CARD)
    .shadow({
      radius: 16,
      color: this.darkMode ? Dark.SHADOW_COLOR : Token.SHADOW_COLOR,
      offsetY: 4,
    })
  }
}
