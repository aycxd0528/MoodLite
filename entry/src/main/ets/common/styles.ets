/**
 * MoodLite v2.0 — 全局设计 Token (样式来源)
 *
 * 所有组件强制引用此文件，禁止在页面中硬编码样式值。
 */

// ========== 类型接口 ==========

export interface ColorTokens {
  BG: string; CARD: string; PINK: string; PINK_LIGHT: string;
  BLUE: string; BLUE_DEEP: string; BLUE_LIGHT: string;
  TEXT_MAIN: string; TEXT_GRAY: string; TEXT_WHITE: string;
  SHADOW_COLOR: string; GRADIENT_START: string; GRADIENT_END: string;
  DIVIDER: string; BAR_BG: string; DELETE_RED: string;
  INFO_TIP: string; BUBBLE_BG: string; BAR_NEUTRAL: string; HEAT_NEUTRAL: string;
}

export interface ShadowDef { radius: number; color: string; offsetY: number; }

export interface ShadowTokens { CARD: ShadowDef; PLUS: ShadowDef; }

export interface RadiusTokens { CARD: number; BUTTON: number; SMALL: number; TINY: number; FULL: number; }

export interface SpacingTokens { XS: number; SM: number; MD: number; LG: number; XL: number; BOTTOM_BREATH: number; HEADER_TOP: number; }

export interface FontTokens { TITLE: number; SUBTITLE: number; BODY: number; CAPTION: number; SMALL: number; TINY: number; }

export interface LayoutTokens { GRADIENT_H: string; TAB_BAR_H: number; CARD_PAD: number; CENTER_BTN: number; }

export interface MoodTokens { MIN: number; MAX: number; LABELS: string[]; EMOJIS: string[]; COLORS: string[]; }

// ========== 色彩 ==========
export const Token: ColorTokens = {
  BG:               '#F7F8FA',
  CARD:             '#FFFFFF',
  PINK:             '#FF8BA7',
  PINK_LIGHT:       '#FFE5EC',
  BLUE:             '#AEC6CF',
  BLUE_DEEP:        '#8FB7E8',
  BLUE_LIGHT:       '#E8F0F4',
  TEXT_MAIN:        '#1F2937',
  TEXT_GRAY:        '#9CA3AF',
  TEXT_WHITE:       '#FFFFFF',
  SHADOW_COLOR:     'rgba(0, 0, 0, 0.03)',
  GRADIENT_START:   '#FFE5EC',
  GRADIENT_END:     'rgba(255, 229, 236, 0)',
  DIVIDER:          '#F3F4F6',
  BAR_BG:           '#F3F4F6',
  DELETE_RED:       '#FF6B6B',
  INFO_TIP:         '#8FB7E8',
  BUBBLE_BG:        '#F5F7FA',
  BAR_NEUTRAL:      '#D4D4D8',
  HEAT_NEUTRAL:     '#EDE4F0',
};

// ========== 阴影（极度克制） ==========
export const Shadow: ShadowTokens = {
  CARD: { radius: 30, color: Token.SHADOW_COLOR, offsetY: 10 },
  PLUS: { radius: 12, color: 'rgba(255,139,167,0.4)', offsetY: 4 },
};

// ========== 圆角 ==========
export const R: RadiusTokens = {
  CARD: 24, BUTTON: 20, SMALL: 12, TINY: 8, FULL: 28,
};

// ========== 间距 ==========
export const S: SpacingTokens = {
  XS: 8, SM: 12, MD: 16, LG: 24, XL: 32,
  BOTTOM_BREATH: 200,
  HEADER_TOP: 56,
};

// ========== 字号 ==========
export const F: FontTokens = {
  TITLE: 28, SUBTITLE: 24, BODY: 16, CAPTION: 14, SMALL: 12, TINY: 10,
};

// ========== 布局 ==========
export const L: LayoutTokens = {
  GRADIENT_H: '35%', TAB_BAR_H: 72, CARD_PAD: 24, CENTER_BTN: 56,
};

// ========== 深色主题 ==========

export const Dark: ColorTokens = {
  BG:               '#1A1A2E',
  CARD:             '#252540',
  PINK:             '#FF8BA7',
  PINK_LIGHT:       '#3D2A3A',
  BLUE:             '#AEC6CF',
  BLUE_DEEP:        '#8FB7E8',
  BLUE_LIGHT:       '#2A3340',
  TEXT_MAIN:        '#E8E8EC',
  TEXT_GRAY:        '#7A7A8C',
  TEXT_WHITE:       '#FFFFFF',
  SHADOW_COLOR:     'rgba(0, 0, 0, 0.25)',
  GRADIENT_START:   '#3D2A3A',
  GRADIENT_END:     'rgba(61, 42, 58, 0)',
  DIVIDER:          '#353550',
  BAR_BG:           '#353550',
  DELETE_RED:       '#FF6B6B',
  INFO_TIP:         '#B0D0F0',
  BUBBLE_BG:        '#2A2A40',
  BAR_NEUTRAL:      '#5A5A6E',
  HEAT_NEUTRAL:     '#3D3D5A',
};

/** 获取当前主题色（根据 AppStorage darkMode 切换） */
export function theme(): ColorTokens {
  const dark: boolean = AppStorage.get('darkMode') as boolean;
  return dark ? Dark : Token;
}

// ========== 情绪枚举 ==========
export const Mood: MoodTokens = {
  MIN: -2, MAX: 2,
  LABELS:  ['很糟糕', '不太好', '平静', '不错', '很棒'],
  EMOJIS:  ['😢', '😔', '😐', '🙂', '😄'],
  COLORS:  ['#8FB7E8', Token.BLUE, Token.TEXT_GRAY, Token.PINK, Token.PINK],
};
