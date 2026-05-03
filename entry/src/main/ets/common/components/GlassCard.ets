/**
 * GlassCard — 全局毛玻璃卡片组件 (v2.0)
 *
 * 视觉：纯白 #FFFFFF, 24vp 圆角, 极弱弥散阴影
 */

import { Token, Dark, Shadow, R, L } from '../styles';

@Component
export struct GlassCard {
  @StorageLink('darkMode') darkMode: boolean = false;
  cardPadding: number = L.CARD_PAD;
  cardRadius: number = R.CARD;
  shadowOffY: number = Shadow.CARD.offsetY;
  shadowRad: number = Shadow.CARD.radius;

  @BuilderParam content: () => void = this.empty;

  @Builder empty() {}

  build() {
    Column() { this.content() }
      .width('100%')
      .backgroundColor(this.darkMode ? Dark.CARD : Token.CARD)
      .borderRadius(this.cardRadius)
      .shadow({ radius: this.shadowRad, color: this.darkMode ? Dark.SHADOW_COLOR : Token.SHADOW_COLOR, offsetY: this.shadowOffY })
      .padding(this.cardPadding)
  }
}
