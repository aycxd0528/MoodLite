import { readFile, readdir } from 'node:fs/promises';
import { extname, join } from 'node:path';

async function sourceFiles(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  const nested = await Promise.all(entries.map((entry) => {
    const location = join(directory, entry.name);
    return entry.isDirectory() ? sourceFiles(location) : [location];
  }));
  return nested.flat().filter((file) => extname(file) === '.ets');
}

const violations = [];
const runtimeFiles = await sourceFiles('entry/src/main/ets');
for (const file of runtimeFiles) {
  const content = await readFile(file, 'utf8');
  if (/setWindowBackgroundColor\s*\(/.test(content)) violations.push(`phone-incompatible window background API: ${file}`);
  if (/vibrator\.vibrate\s*\(/.test(content)) violations.push(`deprecated vibrator API: ${file}`);
  if (/from\s+['"]@ohos\.router['"]/.test(content)) violations.push(`deprecated global router: ${file}`);
}

const projectProfile = await readFile('build-profile.json5', 'utf8');
if (/"(?:keyPassword|storePassword|certpath|storeFile|profile)"\s*:/.test(projectProfile)) {
  violations.push('tracked build profile contains local signing material');
}

const mainPages = await readFile('entry/src/main/resources/base/profile/main_pages.json', 'utf8');
if (mainPages.includes('pages/Profile')) violations.push('embedded Profile is registered as a standalone page');

const profile = await readFile('entry/src/main/ets/pages/Profile.ets', 'utf8');
if (/@Entry\s*[\r\n]+@Component\s*[\r\n]+export struct Profile/.test(profile)) {
  violations.push('embedded Profile carries the Entry decorator');
}

const widget = await readFile('entry/src/main/ets/widget/pages/MoodWidgetCard.ets', 'utf8');
if (!widget.includes('@Entry(widgetStorage)')) violations.push('widget entry does not bind LocalStorage explicitly');

if (violations.length > 0) {
  console.error(violations.join('\n'));
  process.exit(1);
}
console.log('release hygiene verification passed');
