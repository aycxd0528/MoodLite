/**
 * GlassCard — 全局毛玻璃卡片组件 (v2.0)
 *
 * 视觉：半透明卡片背景 + backdropBlur + 弱边框高光线。
 * 颜色自动跟随主题 CARD 色值，不再硬编码 BlossomPink 特定色。
 */

import { R, L } from '../styles';
import { resolveColors } from '../ThemeManager';

@Component
export struct GlassCard {
  @StorageLink('darkMode') darkMode: boolean = false;
  @StorageLink('currentTheme') currentTheme: string = 'blossomPink';
  cardPadding: number = L.CARD_PAD;
  cardRadius: number = R.CARD;
  blurRadius: number = 16;
  bgOpacity: number = 0.75;

  @BuilderParam content: () => void = this.empty;

  @Builder empty() {}

  build() {
    Column() { this.content() }
      .width('100%')
      .backgroundColor(resolveColors(this.darkMode, this.currentTheme).CARD)
      .borderRadius(this.cardRadius)
      .border({
        width: 0.5,
        color: this.darkMode
          ? 'rgba(255, 255, 255, 0.08)'
          : 'rgba(255, 255, 255, 0.40)'
      })
      .backdropBlur(this.blurRadius)
      .shadow({
        radius: 30,
        color: resolveColors(this.darkMode, this.currentTheme).SHADOW_COLOR,
        offsetY: 10
      })
      .padding(this.cardPadding)
  }
}
