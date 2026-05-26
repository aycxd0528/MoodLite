/**
 * MoodLite v2.0 — 全局设计 Token + 四主题色板注册
 *
 * 所有组件强制引用此文件或 ThemeManager，禁止在页面中硬编码样式值。
 * Token / Dark 保留用于向后兼容，新代码应使用 ThemeManager.getColors()。
 */

// ========== 类型接口 ==========

export interface ColorTokens {
  BG: string; CARD: string; PINK: string; PINK_LIGHT: string;
  BLUE: string; BLUE_DEEP: string; BLUE_LIGHT: string;
  TEXT_MAIN: string; TEXT_GRAY: string; TEXT_WHITE: string; BTN_TEXT: string;
  SHADOW_COLOR: string; GRADIENT_START: string; GRADIENT_END: string;
  DIVIDER: string; BAR_BG: string; DELETE_RED: string;
  INFO_TIP: string; BUBBLE_BG: string; BAR_NEUTRAL: string; HEAT_NEUTRAL: string;
  TEXT_HINT: string; BAR_TRACK: string; TEXT_SECONDARY: string;
}

export interface ShadowDef { radius: number; color: string; offsetY: number; }

export interface ShadowTokens { CARD: ShadowDef; PLUS: ShadowDef; }

export interface RadiusTokens { CARD: number; BUTTON: number; SMALL: number; TINY: number; FULL: number; }

export interface SpacingTokens { XS: number; SM: number; MD: number; LG: number; XL: number; BOTTOM_BREATH: number; HEADER_TOP: number; }

export interface FontTokens { TITLE: number; SUBTITLE: number; BODY: number; CAPTION: number; SMALL: number; TINY: number; }

export interface LayoutTokens { GRADIENT_H: string; TAB_BAR_H: number; CARD_PAD: number; CENTER_BTN: number; }

export interface MoodTokens { MIN: number; MAX: number; LABELS: string[]; EMOJIS: string[]; COLORS: string[]; }

export interface GlassTokens {
  backdropBlur: number;
  cardOpacity: number;
  borderOpacity: number;
}

// ========== BlossomPink (经典版) — 浅色 ==========
// 即现有默认设计，全部保留

export const BlossomPinkLight: ColorTokens = {
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
  BTN_TEXT:         '#FFFFFF',
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
  TEXT_HINT:        '#999999',
  BAR_TRACK:        '#F0F0F0',
  TEXT_SECONDARY:   '#666666',
};

// ========== BlossomPink (经典版) — 深色 ==========

export const BlossomPinkDark: ColorTokens = {
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
  BTN_TEXT:         '#FFFFFF',
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
  TEXT_HINT:        '#7A7A8C',
  BAR_TRACK:        '#3D3D5A',
  TEXT_SECONDARY:   '#999999',
};

// ========== SkyBlue (浅蓝) — 浅色 ==========
// 与 BlossomPink 设计层级、阴影、透明度 100% 一致，仅色相替换：粉 -> 蓝

export const SkyBlueLight: ColorTokens = {
  BG:               '#F7F8FA',
  CARD:             '#FFFFFF',
  PINK:             '#87CEEB',
  PINK_LIGHT:       '#E6F3FA',
  BLUE:             '#AEC6CF',
  BLUE_DEEP:        '#8FB7E8',
  BLUE_LIGHT:       '#E8F0F4',
  TEXT_MAIN:        '#1F2937',
  TEXT_GRAY:        '#9CA3AF',
  TEXT_WHITE:       '#FFFFFF',
  BTN_TEXT:         '#FFFFFF',
  SHADOW_COLOR:     'rgba(0, 0, 0, 0.03)',
  GRADIENT_START:   '#E6F3FA',
  GRADIENT_END:     'rgba(230, 243, 250, 0)',
  DIVIDER:          '#F3F4F6',
  BAR_BG:           '#F3F4F6',
  DELETE_RED:       '#FF6B6B',
  INFO_TIP:         '#8FB7E8',
  BUBBLE_BG:        '#F5F7FA',
  BAR_NEUTRAL:      '#D4D4D8',
  HEAT_NEUTRAL:     '#EDE4F0',
  TEXT_HINT:        '#999999',
  BAR_TRACK:        '#F0F0F0',
  TEXT_SECONDARY:   '#666666',
};

// ========== SkyBlue (浅蓝) — 深色 ==========

export const SkyBlueDark: ColorTokens = {
  BG:               '#1A1A2E',
  CARD:             '#252540',
  PINK:             '#7BB8D6',
  PINK_LIGHT:       '#2A3D50',
  BLUE:             '#AEC6CF',
  BLUE_DEEP:        '#8FB7E8',
  BLUE_LIGHT:       '#2A3340',
  TEXT_MAIN:        '#E8E8EC',
  TEXT_GRAY:        '#7A7A8C',
  TEXT_WHITE:       '#FFFFFF',
  BTN_TEXT:         '#FFFFFF',
  SHADOW_COLOR:     'rgba(0, 0, 0, 0.25)',
  GRADIENT_START:   '#2A3D50',
  GRADIENT_END:     'rgba(42, 61, 80, 0)',
  DIVIDER:          '#353550',
  BAR_BG:           '#353550',
  DELETE_RED:       '#FF6B6B',
  INFO_TIP:         '#B0D0F0',
  BUBBLE_BG:        '#2A2A40',
  BAR_NEUTRAL:      '#5A5A6E',
  HEAT_NEUTRAL:     '#3D3D5A',
  TEXT_HINT:        '#7A7A8C',
  BAR_TRACK:        '#3D3D5A',
  TEXT_SECONDARY:   '#999999',
};

// ========== LavenderPurple (淡紫) — 浅色 ==========

export const LavenderPurpleLight: ColorTokens = {
  BG:               '#F7F8FA',
  CARD:             '#FFFFFF',
  PINK:             '#B39DDB',
  PINK_LIGHT:       '#EDE0F5',
  BLUE:             '#AEC6CF',
  BLUE_DEEP:        '#8FB7E8',
  BLUE_LIGHT:       '#E8F0F4',
  TEXT_MAIN:        '#1F2937',
  TEXT_GRAY:        '#9CA3AF',
  TEXT_WHITE:       '#FFFFFF',
  BTN_TEXT:         '#FFFFFF',
  SHADOW_COLOR:     'rgba(0, 0, 0, 0.03)',
  GRADIENT_START:   '#EDE0F5',
  GRADIENT_END:     'rgba(237, 224, 245, 0)',
  DIVIDER:          '#F3F4F6',
  BAR_BG:           '#F3F4F6',
  DELETE_RED:       '#FF6B6B',
  INFO_TIP:         '#8FB7E8',
  BUBBLE_BG:        '#F5F7FA',
  BAR_NEUTRAL:      '#D4D4D8',
  HEAT_NEUTRAL:     '#EDE4F0',
  TEXT_HINT:        '#999999',
  BAR_TRACK:        '#F0F0F0',
  TEXT_SECONDARY:   '#666666',
};

// ========== LavenderPurple (淡紫) — 深色 ==========

export const LavenderPurpleDark: ColorTokens = {
  BG:               '#1A1A2E',
  CARD:             '#252540',
  PINK:             '#9C7EC4',
  PINK_LIGHT:       '#352D42',
  BLUE:             '#AEC6CF',
  BLUE_DEEP:        '#8FB7E8',
  BLUE_LIGHT:       '#2A3340',
  TEXT_MAIN:        '#E8E8EC',
  TEXT_GRAY:        '#7A7A8C',
  TEXT_WHITE:       '#FFFFFF',
  BTN_TEXT:         '#FFFFFF',
  SHADOW_COLOR:     'rgba(0, 0, 0, 0.25)',
  GRADIENT_START:   '#352D42',
  GRADIENT_END:     'rgba(53, 45, 66, 0)',
  DIVIDER:          '#353550',
  BAR_BG:           '#353550',
  DELETE_RED:       '#FF6B6B',
  INFO_TIP:         '#B0D0F0',
  BUBBLE_BG:        '#2A2A40',
  BAR_NEUTRAL:      '#5A5A6E',
  HEAT_NEUTRAL:     '#3D3D5A',
  TEXT_HINT:        '#7A7A8C',
  BAR_TRACK:        '#3D3D5A',
  TEXT_SECONDARY:   '#999999',
};

// ========== PureMono (纯净黑白) — 浅色 ==========
// 极简无彩色：强调色、情绪色全部映射为灰度，维持高对比度纯粹性

export const PureMonoLight: ColorTokens = {
  BG:               '#FFFFFF',
  CARD:             '#FAFAFA',
  PINK:             '#999999',
  PINK_LIGHT:       '#F8F8F8',
  BLUE:             '#999999',
  BLUE_DEEP:        '#777777',
  BLUE_LIGHT:       '#F0F0F0',
  TEXT_MAIN:        '#1A1A1A',
  TEXT_GRAY:        '#BBBBBB',
  TEXT_WHITE:       '#FFFFFF',
  BTN_TEXT:         '#FFFFFF',
  SHADOW_COLOR:     'rgba(0, 0, 0, 0.04)',
  GRADIENT_START:   '#FFFFFF',
  GRADIENT_END:     'rgba(255, 255, 255, 0)',
  DIVIDER:          '#EEEEEE',
  BAR_BG:           '#F5F5F5',
  DELETE_RED:       '#CC3333',
  INFO_TIP:         '#888888',
  BUBBLE_BG:        '#F5F5F5',
  BAR_NEUTRAL:      '#D4D4D4',
  HEAT_NEUTRAL:     '#E0E0E0',
  TEXT_HINT:        '#999999',
  BAR_TRACK:        '#EEEEEE',
  TEXT_SECONDARY:   '#777777',
};

// ========== PureMono (纯净黑白) — 深色 ==========

export const PureMonoDark: ColorTokens = {
  BG:               '#000000',
  CARD:             '#1A1A1A',
  PINK:             '#FFFFFF',
  PINK_LIGHT:       '#0A0A0A',
  BLUE:             '#AAAAAA',
  BLUE_DEEP:        '#BBBBBB',
  BLUE_LIGHT:       '#1A1A1A',
  TEXT_MAIN:        '#F0F0F0',
  TEXT_GRAY:        '#AAAAAA',
  TEXT_WHITE:       '#FFFFFF',
  BTN_TEXT:         '#000000',
  SHADOW_COLOR:     'rgba(0, 0, 0, 0.30)',
  GRADIENT_START:   '#000000',
  GRADIENT_END:     'rgba(0, 0, 0, 0)',
  DIVIDER:          '#2A2A2A',
  BAR_BG:           '#1A1A1A',
  DELETE_RED:       '#FF4444',
  INFO_TIP:         '#BBBBBB',
  BUBBLE_BG:        '#1A1A1A',
  BAR_NEUTRAL:      '#666666',
  HEAT_NEUTRAL:     '#333333',
  TEXT_HINT:        '#AAAAAA',
  BAR_TRACK:        '#1A1A1A',
  TEXT_SECONDARY:   '#AAAAAA',
};

// ========== 向后兼容别名 ==========
/** @deprecated 使用 ThemeManager.getColors() 或直接引用 BlossomPinkLight */
export const Token: ColorTokens = BlossomPinkLight;
/** @deprecated 使用 ThemeManager.getColors() 或直接引用 BlossomPinkDark */
export const Dark: ColorTokens = BlossomPinkDark;

// ========== 毛玻璃参数 ==========

export const GlassLight: GlassTokens = {
  backdropBlur: 16,
  cardOpacity: 0.75,
  borderOpacity: 0.40,
};

export const GlassDark: GlassTokens = {
  backdropBlur: 16,
  cardOpacity: 0.60,
  borderOpacity: 0.08,
};

// ========== 阴影（极度克制） ==========

export const Shadow: ShadowTokens = {
  CARD: { radius: 30, color: BlossomPinkLight.SHADOW_COLOR, offsetY: 10 },
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

// ========== 图标色彩矩阵 ==========

export const DARK_INVERT: number[] = [-1, 0, 0, 0, 255, 0, -1, 0, 0, 255, 0, 0, -1, 0, 255, 0, 0, 0, 1, 0];
export const NORMAL_MATRIX: number[] = [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0];

// ========== 情绪枚举（表情与标签固定，不随主题变化） ==========

export const Mood: MoodTokens = {
  MIN: -2, MAX: 2,
  LABELS:  ['很糟糕', '不太好', '平静', '不错', '很棒'],
  EMOJIS:  ['😢', '😔', '😐', '🙂', '😄'],
  COLORS:  ['#8FB7E8', BlossomPinkLight.BLUE, BlossomPinkLight.TEXT_GRAY, BlossomPinkLight.PINK, BlossomPinkLight.PINK],
};

/**
 * 获取当前主题色。
 * @deprecated 新代码应使用 ThemeManager.getColors()，此函数保留用于向后兼容。
 */
export function theme(): ColorTokens {
  const dark: boolean = AppStorage.get('darkMode') as boolean;
  return dark ? BlossomPinkDark : BlossomPinkLight;
}
