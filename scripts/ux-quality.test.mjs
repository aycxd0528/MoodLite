import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import test from 'node:test';

const ROOT = process.cwd();

function source(path) {
  return readFileSync(join(ROOT, path), 'utf8');
}

function relativeLuminance(hex) {
  const channels = hex.slice(1).match(/../g).map((part) => parseInt(part, 16) / 255);
  const linear = channels.map((channel) => channel <= 0.04045
    ? channel / 12.92
    : ((channel + 0.055) / 1.055) ** 2.4);
  return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2];
}

function contrastRatio(foreground, background) {
  const first = relativeLuminance(foreground);
  const second = relativeLuminance(background);
  return (Math.max(first, second) + 0.05) / (Math.min(first, second) + 0.05);
}

function palettes() {
  const styles = source('entry/src/main/ets/common/styles.ets');
  const result = new Map();
  for (const match of styles.matchAll(/export const (\w+): ColorTokens = \{([\s\S]*?)\n\};/g)) {
    const colors = {};
    for (const color of match[2].matchAll(/(\w+):\s+'(#[0-9A-Fa-f]{6})'/g)) {
      colors[color[1]] = color[2];
    }
    result.set(match[1], colors);
  }
  return result;
}

function expectContrast(theme, colors, foreground, background, minimum) {
  assert.ok(colors[foreground], `${theme} is missing ${foreground}`);
  assert.ok(colors[background], `${theme} is missing ${background}`);
  const actual = contrastRatio(colors[foreground], colors[background]);
  assert.ok(
    actual >= minimum,
    `${theme} ${foreground}/${background} contrast ${actual.toFixed(2)} is below ${minimum}`,
  );
}

test('all theme text and action colors meet the cloud-test contrast thresholds', () => {
  const themes = palettes();
  assert.equal(themes.size, 8);
  for (const [theme, colors] of themes) {
    for (const background of ['BG', 'CARD']) {
      expectContrast(theme, colors, 'TEXT_GRAY', background, 4.5);
      expectContrast(theme, colors, 'TEXT_HINT', background, 4.5);
      expectContrast(theme, colors, 'ACCENT_TEXT', background, 4.5);
      expectContrast(theme, colors, 'BLUE_DEEP', background, 4.5);
    }
    expectContrast(theme, colors, 'ACCENT_TEXT', 'PINK_LIGHT', 4.5);
    expectContrast(theme, colors, 'BTN_TEXT', 'ACTION_BG', 4.5);
    expectContrast(theme, colors, 'TEXT_MAIN', 'BAR_TRACK', 4.5);
    expectContrast(theme, colors, 'DELETE_RED', 'CARD', 4.5);
    expectContrast(theme, colors, 'BTN_TEXT', 'DANGER_BG', 4.5);
  }

  const widgetSource = source('entry/src/main/ets/widget/pages/MoodWidgetCard.ets');
  const widgetColors = {};
  for (const color of widgetSource.matchAll(/const (WIDGET_\w+): string = '(#[0-9A-Fa-f]{6})'/g)) {
    widgetColors[color[1]] = color[2];
  }
  expectContrast('WidgetLight', widgetColors, 'WIDGET_LIGHT_SECONDARY', 'WIDGET_LIGHT_BG', 4.5);
  expectContrast('WidgetDark', widgetColors, 'WIDGET_DARK_SECONDARY', 'WIDGET_DARK_BG', 4.5);
});

test('decorative brand colors are not used directly for text, icons, or selected controls', () => {
  const runtime = [
    'entry/src/main/ets/pages/AboutPage.ets',
    'entry/src/main/ets/pages/AddEntry.ets',
    'entry/src/main/ets/pages/DataPrivacyPage.ets',
    'entry/src/main/ets/pages/EntryDetail.ets',
    'entry/src/main/ets/pages/HomeTab.ets',
    'entry/src/main/ets/pages/Index.ets',
    'entry/src/main/ets/pages/MainPage.ets',
    'entry/src/main/ets/pages/Profile.ets',
    'entry/src/main/ets/pages/Stats.ets',
    'entry/src/main/ets/pages/TimelineTab.ets',
    'entry/src/main/ets/pages/Welcome.ets',
    'entry/src/main/ets/widget/pages/MoodWidgetCard.ets',
  ];
  const violations = [];
  for (const path of runtime) {
    const hasDecorativeForeground = source(path).split(/\r?\n/).some((line) =>
      /\.(?:fontColor|fillColor|selectedColor|blockColor)\([^\n]*\.PINK\b/.test(line));
    if (hasDecorativeForeground) {
      violations.push(path);
    }
  }
  assert.deepEqual(violations, []);
  assert.doesNotMatch(
    runtime.map((path) => source(path)).join('\n'),
    /\.(?:fontColor|fillColor)\([^\n]*\.TEXT_SECONDARY\b/,
    'TEXT_SECONDARY is not guaranteed to meet the foreground contrast threshold',
  );
});

test('every entry page synchronizes immersive system-bar content with the active color mode', () => {
  const helper = 'entry/src/main/ets/common/SystemBarManager.ets';
  assert.ok(existsSync(join(ROOT, helper)), 'SystemBarManager.ets is missing');
  const entryPages = [
    'AboutPage.ets',
    'AddEntry.ets',
    'DataPrivacyPage.ets',
    'EntryDetail.ets',
    'Index.ets',
    'MainPage.ets',
    'Welcome.ets',
  ];
  for (const page of entryPages) {
    const content = source(`entry/src/main/ets/pages/${page}`);
    assert.match(content, /syncSystemBars\s*\(/, `${page} does not synchronize system bars`);
  }
  assert.doesNotMatch(
    source('entry/src/main/ets/entryability/EntryAbility.ets'),
    /isStatusBarLightIcon\s*:/,
  );
});

test('full-screen page transitions never run shorter than 200 ms', () => {
  const pages = [
    'entry/src/main/ets/pages/AddEntry.ets',
    'entry/src/main/ets/pages/EntryDetail.ets',
    'entry/src/main/ets/pages/MainPage.ets',
  ];
  for (const path of pages) {
    const durations = [...source(path).matchAll(/PageTransition(?:Enter|Exit)\(\{\s*duration:\s*(\d+)/g)]
      .map((match) => Number(match[1]));
    assert.ok(durations.length > 0, `${path} has no explicit page transition duration`);
    assert.ok(durations.every((duration) => duration >= 200), `${path} contains a transition below 200 ms`);
  }
});

test('every scrollable first-release screen exposes spring boundary feedback', () => {
  const scrollableScreens = [
    'entry/src/main/ets/pages/AboutPage.ets',
    'entry/src/main/ets/pages/AddEntry.ets',
    'entry/src/main/ets/pages/DataPrivacyPage.ets',
    'entry/src/main/ets/pages/EntryDetail.ets',
    'entry/src/main/ets/pages/HomeTab.ets',
    'entry/src/main/ets/pages/Profile.ets',
    'entry/src/main/ets/pages/Stats.ets',
    'entry/src/main/ets/pages/TimelineTab.ets',
  ];
  for (const path of scrollableScreens) {
    assert.match(source(path), /\.edgeEffect\(EdgeEffect\.Spring\)/, `${path} lacks spring edge feedback`);
  }
});
