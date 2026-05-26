/**
 * Widget1Card — 2×4 桌面情绪小组件 (v3.0 今日摘要 + 全宽热力图)
 *
 * 上排：今日情绪图标 + 标签 + 连续天数 + 本月记录天数
 * 下排：7×5 全宽热力图网格，毛玻璃背景，暗色模式自适应。
 */

@Entry
@Component
struct Widget1Card {
  @LocalStorageProp('monthDays') monthDays: number[] = new Array(35).fill(0);
  @LocalStorageProp('todayScore') todayScore: number = 0;
  @LocalStorageProp('moodLabel') moodLabel: string = 'MoodLite';
  @LocalStorageProp('streak') streak: number = 0;
  @LocalStorageProp('recordDays') recordDays: number = 0;
  @LocalStorageProp('darkMode') darkMode: number = 0;

  getFaceIcon(score: number): Resource {
    if (score <= -2) return $r('app.media.ic_face_terrible');
    if (score === -1) return $r('app.media.ic_face_bad');
    if (score === 0)  return $r('app.media.ic_face_neutral');
    if (score === 1)  return $r('app.media.ic_face_good');
    return $r('app.media.ic_face_awesome');
  }

  getHeatColor(val: number): string {
    const dk = this.darkMode !== 0;
    if (val === 0) return dk ? '#2A2A2A' : '#F0F0F0';
    const moodCode = Math.floor(val / 10);
    const inten = val % 10;

    if (moodCode === 1) {
      if (inten === 4) return dk ? '#5A7A90' : '#8BA9B8';
      if (inten === 3) return dk ? '#6A8EA6' : '#AEC6CF';
      return dk ? '#3A5060' : '#D6E6F2';
    }
    if (moodCode === 2) return dk ? '#3D3D3D' : '#E8E8E8';

    if (moodCode === 3) {
      if (inten === 4) return dk ? '#B36A7A' : '#FF8BA7';
      if (inten === 3) return dk ? '#8A5060' : '#FFB3C5';
      return dk ? '#5A3040' : '#FFDCE5';
    }
    if (moodCode === 4) {
      if (inten === 4) return dk ? '#7A5A8A' : '#A78BBA';
      if (inten === 3) return dk ? '#5A3A6A' : '#C4A0D8';
      return dk ? '#3A204A' : '#E0CCF0';
    }
    return dk ? '#2A2A2A' : '#F0F0F0';
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

          Column() {
            if (this.streak > 0) {
              Text('连续 ' + this.streak + ' 天')
                .fontSize(11).fontColor(this.darkMode ? '#AAAAAA' : '#888888')
            }
            Text('本月 ' + this.recordDays + ' 条')
              .fontSize(11).fontColor(this.darkMode ? '#AAAAAA' : '#888888')
          }
          .alignItems(HorizontalAlign.End)
        }
        .width('100%')
        .padding({ left: 14, right: 14, top: 10, bottom: 6 })

        // ---- 下排：全宽热力图 (layoutWeight 自适应) ----
        Column({ space: 6 }) {
          ForEach([0, 1, 2, 3, 4], (row: number) => {
            Row({ space: 6 }) {
              ForEach(this.monthDays.slice(row * 7, (row + 1) * 7), (v: number) => {
                Column()
                  .layoutWeight(1).height('100%')
                  .borderRadius(4)
                  .backgroundColor(this.getHeatColor(v))
                  .border({
                    width: 0.5,
                    color: this.darkMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.04)'
                  })
              })
            }.width('100%').layoutWeight(1)
          }, (row: number) => row.toString())
        }
        .width('100%').layoutWeight(1)
        .padding({ left: 14, right: 14, top: 4, bottom: 8 })
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
