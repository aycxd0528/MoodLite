@Entry
@Component
struct Widget1Card {
  @LocalStorageProp('monthDays') monthDays: number[] = new Array(35).fill(0);

  getHeatColor(val: number): string {
    if (val === 0) return '#F5F6F8';                          // 无记录
    const moodCode = Math.floor(val / 10);                    // 1=低落 2=平静 3=愉悦 4=混合
    const inten = val % 10;                                   // 0=弱 1=中 2=强

    if (moodCode === 1) { // 低落 → 蓝色 由浅到深
      if (inten === 2) return '#8BA9B8';
      if (inten === 1) return '#AEC6CF';
      return '#D6E6F2';
    }
    if (moodCode === 2) return '#E8E8E8';                     // 平静

    if (moodCode === 3) { // 愉悦 → 粉色 由浅到深
      if (inten === 2) return '#FF8BA7';
      if (inten === 1) return '#FFB3C5';
      return '#FFDCE5';
    }
    if (moodCode === 4) { // 混合 → 紫色 由浅到深
      if (inten === 2) return '#A78BBA';
      if (inten === 1) return '#C4A0D8';
      return '#E0CCF0';
    }
    return '#F5F6F8';
  }

  build() {
    FormLink({
      action: 'router',
      abilityName: 'EntryAbility',
      params: { targetPage: 'pages/MainPage', tab: 3 }
    }) {
      Stack() {
        Column()
          .width('100%').height('100%')
          .linearGradient({
            direction: GradientDirection.Bottom,
            colors: [['#FFF5F7', 0.0], ['#FFFFFF', 1.0]]
          })

        Column() {
          // 顶部标题行
          Row() {
            Text('本月情绪轨迹').fontSize(13).fontWeight(FontWeight.Medium).fontColor('#444444')
            Blank()
            Image($r('app.media.ic_sparkles')).width(12).height(12).opacity(0.5)
          }
          .width('100%').padding({ left: 12, right: 12, top: 10 })

          // 左右分栏主体
          Row() {
            // 左侧：云朵插图区
            Column() {
              Image($r('app.media.img_home_cloud'))
                .width(56).height(56)
                .objectFit(ImageFit.Contain)
            }
            .layoutWeight(4)
            .height('100%')
            .justifyContent(FlexAlign.Center)

            // 右侧：7x5 热力图网格
            Column({ space: 5 }) {
              Row({ space: 5 }) {
                ForEach(this.monthDays.slice(0, 7), (v: number) => {
                  Column().width(12).height(12).borderRadius(3).backgroundColor(this.getHeatColor(v))
                })
              }.width('100%').justifyContent(FlexAlign.Center)

              Row({ space: 5 }) {
                ForEach(this.monthDays.slice(7, 14), (v: number) => {
                  Column().width(12).height(12).borderRadius(3).backgroundColor(this.getHeatColor(v))
                })
              }.width('100%').justifyContent(FlexAlign.Center)

              Row({ space: 5 }) {
                ForEach(this.monthDays.slice(14, 21), (v: number) => {
                  Column().width(12).height(12).borderRadius(3).backgroundColor(this.getHeatColor(v))
                })
              }.width('100%').justifyContent(FlexAlign.Center)

              Row({ space: 5 }) {
                ForEach(this.monthDays.slice(21, 28), (v: number) => {
                  Column().width(12).height(12).borderRadius(3).backgroundColor(this.getHeatColor(v))
                })
              }.width('100%').justifyContent(FlexAlign.Center)

              Row({ space: 5 }) {
                ForEach(this.monthDays.slice(28, 35), (v: number) => {
                  Column().width(12).height(12).borderRadius(3).backgroundColor(this.getHeatColor(v))
                })
              }.width('100%').justifyContent(FlexAlign.Center)
            }
            .layoutWeight(6)
            .height('100%')
            .padding({ left: 8, right: 10 })
            .justifyContent(FlexAlign.Center)
          }
          .width('100%').layoutWeight(1)
        }
        .width('100%').height('100%')
      }
    }
    .width('100%').height('100%')
  }
}
