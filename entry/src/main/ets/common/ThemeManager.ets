/**
 * ThemeManager — 响应式主题注册中心
 *
 * 职责：
 * - 读取 AppStorage('currentTheme') + AppStorage('darkMode') 解析当前生效色板
 * - 暴露 getColors() / getActiveConfig() 供全局组件消费
 * - PureMono 主题下跟随系统暗色模式自动切换，其他主题使用手动 toggle
 *
 * 使用方式：
 *   import { ThemeManager } from '../common/ThemeManager';
 *   const C = ThemeManager.getColors();
 */

import {
  ColorTokens, ShadowTokens, GlassTokens,
  BlossomPinkLight, BlossomPinkDark,
  SkyBlueLight, SkyBlueDark,
  LavenderPurpleLight, LavenderPurpleDark,
  PureMonoLight, PureMonoDark,
  Shadow, GlassLight, GlassDark,
} from './styles';

export enum ThemePreset {
  PURE_MONO = 'pureMono',
  BLOSSOM_PINK = 'blossomPink',
  SKY_BLUE = 'skyBlue',
  LAVENDER_PURPLE = 'lavenderPurple',
}

export interface ThemeConfig {
  preset: ThemePreset;
  displayName: string;
  colors: ColorTokens;
  shadow: ShadowTokens;
  glass: GlassTokens;
}

export interface ThemePresetEntry {
  preset: ThemePreset;
  displayName: string;
  previewColor: string;
}

const DISPLAY_NAMES: Record<string, string> = {
  [ThemePreset.PURE_MONO]: '纯净黑白',
  [ThemePreset.BLOSSOM_PINK]: '黑白粉',
  [ThemePreset.SKY_BLUE]: '黑白浅蓝',
  [ThemePreset.LAVENDER_PURPLE]: '黑白淡紫',
};

const LIGHT_MAP: Record<string, ColorTokens> = {
  [ThemePreset.PURE_MONO]: PureMonoLight,
  [ThemePreset.BLOSSOM_PINK]: BlossomPinkLight,
  [ThemePreset.SKY_BLUE]: SkyBlueLight,
  [ThemePreset.LAVENDER_PURPLE]: LavenderPurpleLight,
};

const DARK_MAP: Record<string, ColorTokens> = {
  [ThemePreset.PURE_MONO]: PureMonoDark,
  [ThemePreset.BLOSSOM_PINK]: BlossomPinkDark,
  [ThemePreset.SKY_BLUE]: SkyBlueDark,
  [ThemePreset.LAVENDER_PURPLE]: LavenderPurpleDark,
};

class ThemeManager {
  /** 返回当前生效的完整主题配置 */
  getActiveConfig(): ThemeConfig {
    const preset: string = (AppStorage.get('currentTheme') as string) || ThemePreset.BLOSSOM_PINK;
    const darkMode: boolean = (AppStorage.get('darkMode') as boolean) || false;
    const colors: ColorTokens = darkMode
      ? (DARK_MAP[preset] || BlossomPinkDark)
      : (LIGHT_MAP[preset] || BlossomPinkLight);
    const glass: GlassTokens = darkMode ? GlassDark : GlassLight;

    return {
      preset: preset as ThemePreset,
      displayName: DISPLAY_NAMES[preset] || '黑白粉',
      colors,
      shadow: Shadow,
      glass,
    };
  }

  /** 便捷方法：直接返回当前色板 */
  getColors(): ColorTokens {
    return this.getActiveConfig().colors;
  }

  /** 便捷方法：直接返回当前毛玻璃参数 */
  getGlass(): GlassTokens {
    return this.getActiveConfig().glass;
  }

  /** 切换主题预设（同步写入 AppStorage 触发全局重绘） */
  setTheme(preset: ThemePreset): void {
    AppStorage.set('currentTheme', preset);
  }

  /** 获取当前预设枚举值 */
  getCurrentPreset(): ThemePreset {
    return (AppStorage.get('currentTheme') as ThemePreset) || ThemePreset.BLOSSOM_PINK;
  }

  /** 获取中文显示名 */
  getDisplayName(preset: ThemePreset): string {
    return DISPLAY_NAMES[preset] || '黑白粉';
  }

  /** 所有可用主题列表（供选择器 UI 消费） */
  getAllPresets(): ThemePresetEntry[] {
    return [
      { preset: ThemePreset.PURE_MONO, displayName: '纯净黑白', previewColor: '#888888' } as ThemePresetEntry,
      { preset: ThemePreset.BLOSSOM_PINK, displayName: '黑白粉', previewColor: '#FF8BA7' } as ThemePresetEntry,
      { preset: ThemePreset.SKY_BLUE, displayName: '黑白浅蓝', previewColor: '#87CEEB' } as ThemePresetEntry,
      { preset: ThemePreset.LAVENDER_PURPLE, displayName: '黑白淡紫', previewColor: '#B39DDB' } as ThemePresetEntry,
    ];
  }
}

export default new ThemeManager();

/**
 * 纯函数：根据 darkMode + themeKey 返回当前色板。
 * 组件在 build() 中调用时，将 @StorageLink 值显式传入以确保 ArkTS 追踪到依赖：
 *   const C = resolveColors(this.darkMode, this.currentTheme);
 */
export function resolveColors(darkMode: boolean, themeKey: string): ColorTokens {
  const map: Record<string, ColorTokens> = darkMode ? DARK_MAP : LIGHT_MAP;
  return map[themeKey] || (darkMode ? BlossomPinkDark : BlossomPinkLight);
}
