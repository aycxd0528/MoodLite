import { access, readFile } from 'node:fs/promises';

const forbiddenPaths = [
  'entry/src/main/ets/model/Achievement.ets',
  'entry/src/main/ets/viewmodel/AchievementChecker.ets',
  'entry/src/main/ets/common/components/AchievementDialog.ets',
  'entry/src/main/ets/widget1',
  'entry/src/main/ets/entrybackupability',
  'entry/src/main/resources/base/profile/backup_config.json',
];
const existing = [];
for (const path of forbiddenPaths) {
  try { await access(path); existing.push(path); } catch (_) {}
}
const formConfig = await readFile('entry/src/main/resources/base/profile/form_config.json', 'utf8');
const runtime = await Promise.all([
  readFile('entry/src/main/ets/data/DataManager.ets', 'utf8'),
  readFile('entry/src/main/ets/entryformability/EntryFormAbility.ets', 'utf8'),
]);
const violations = [
  ...existing,
  ...(formConfig.includes('widget1') || formConfig.includes('2*4') ? ['2x4 form registration'] : []),
  ...(runtime.join('\n').match(/quickSaveRecord|quick_log|checkNewAchievements|pending_achievements/g) || []),
];
if (violations.length) {
  console.error(violations.join('\n'));
  process.exit(1);
}
console.log('lightweight scope verification passed');
