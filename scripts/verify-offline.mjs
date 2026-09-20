import { readFile, readdir, stat } from 'node:fs/promises';
import { extname, join, relative } from 'node:path';

const root = new URL('..', import.meta.url);
const scanRoots = [
  'entry/src/main/ets',
  'entry/src/main/module.json5',
  'entry/src/main/resources/base/profile/main_pages.json',
  'entry/build-profile.json5',
];
const forbidden = [
  ['network API', /@ohos\.net|@kit\.NetworkKit/],
  ['remote URL', /https?:\/\//],
  ['AI configuration', /DIFY|DEEPSEEK|API_KEY|AiAgentClient|analyzeMood|activeIntent/],
  ['internet permission', /ohos\.permission\.INTERNET/],
  ['media read permission', /ohos\.permission\.READ_IMAGEVIDEO/],
  ['account residue', /AuthManager|LoginPage|memberType|AIAgentChatPage/],
  ['deferred reminder residue', /@ohos\.reminderAgentManager|@ohos\.notificationManager|ohos\.permission\.PUBLISH_AGENT_REMINDER|ReminderManager|ReminderState|isReminderOn|reminderHour|reminderMinute|mood_reminder_id|提醒设置|选择提醒时间/],
];

async function filesAt(path) {
  const url = new URL(path, root);
  const metadata = await stat(url);
  if (metadata.isFile()) return [url];
  const entries = await readdir(url, { withFileTypes: true });
  const nested = await Promise.all(entries.map(entry =>
    entry.isDirectory() ? filesAt(join(path, entry.name)) : [new URL(join(path, entry.name), root)]));
  return nested.flat().filter(file => ['.ets', '.ts', '.json5', '.json'].includes(extname(file.pathname)));
}

const files = (await Promise.all(scanRoots.map(filesAt))).flat();
const violations = [];
for (const file of files) {
  const content = await readFile(file, 'utf8');
  for (const [label, pattern] of forbidden) {
    if (pattern.test(content)) violations.push(`${label}: ${relative(root.pathname, file.pathname)}`);
  }
}
if (violations.length > 0) {
  console.error(violations.join('\n'));
  process.exit(1);
}
console.log(`offline verification passed (${files.length} files scanned)`);
