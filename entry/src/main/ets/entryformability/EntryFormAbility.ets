/**
 * EntryFormAbility —— 桌面小组件 FormExtensionAbility
 *
 * 职责：
 * - 创建/更新/销毁桌面小组件卡片
 * - 通过 formBindingData 向卡片注入实时数据
 */

import FormExtensionAbility from '@ohos.app.form.FormExtensionAbility';
import formBindingData from '@ohos.app.form.formBindingData';
import formProvider from '@ohos.app.form.formProvider';
import dataPreferences from '@ohos.data.preferences';

const STORE_NAME = 'moodlite_db';
const KEY_RECORDS = 'records';

interface MoodRecord {
  id: string;
  timestamp: number;
  dateStr: string;
  score: number;
  text: string;
  images: string[];
  location: string;
}

function getMoodEmoji(score: number): string {
  if (score >= 2) return '😄';
  if (score === 1) return '🙂';
  if (score === 0) return '😐';
  if (score === -1) return '😔';
  return '😢';
}

function getMoodLabel(score: number): string {
  if (score >= 1) return '愉悦';
  if (score <= -1) return '低落';
  return '平静';
}

function formatDateStr(date: Date): string {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  return y + '-' + m + '-' + d;
}

function uniqueDates(arr: MoodRecord[]): string[] {
  const set = new Set<string>();
  for (const r of arr) {
    set.add(r.dateStr);
  }
  const result: string[] = [];
  set.forEach((v: string) => { result.push(v); });
  result.sort();
  return result;
}

function calcStreak(records: MoodRecord[]): number {
  if (records.length === 0) return 0;
  const uniqueDays = uniqueDates(records);
  let streak = 0;
  const now = new Date();
  let check = formatDateStr(now);
  if (!uniqueDays.includes(check)) {
    check = formatDateStr(new Date(now.getTime() - 86400000));
  }
  let cursor = new Date(check);
  for (const _day of uniqueDays) {
    if (uniqueDays.includes(formatDateStr(cursor))) {
      streak++;
      cursor = new Date(cursor.getTime() - 86400000);
    } else {
      break;
    }
  }
  return streak;
}

async function readRecords(context: Context): Promise<MoodRecord[]> {
  try {
    const prefs = await dataPreferences.getPreferences(context, STORE_NAME);
    const raw = await prefs.get(KEY_RECORDS, '[]') as string;
    return JSON.parse(raw);
  } catch (_err) {
    return [];
  }
}

export default class EntryFormAbility extends FormExtensionAbility {

  onAddForm(want: Record<string, Object>): formBindingData.FormBindingData {
    const dataMap = new Map<string, string | number>();
    dataMap.set('mood', '😐');
    dataMap.set('moodLabel', 'MoodLite');
    dataMap.set('streak', 0);
    dataMap.set('todayMood', '--');

    this.loadAndUpdate(want);

    return formBindingData.createFormBindingData(dataMap);
  }

  onUpdateForm(formId: string): void {
    const dataMap = new Map<string, string | number>();
    dataMap.set('mood', '😐');
    dataMap.set('moodLabel', 'MoodLite');
    dataMap.set('streak', 0);
    dataMap.set('todayMood', '--');

    readRecords(this.context).then((records: MoodRecord[]) => {
      const today = formatDateStr(new Date());
      const todayRecord = records.find(r => r.dateStr === today);

      if (todayRecord) {
        dataMap.set('mood', getMoodEmoji(todayRecord.score));
        dataMap.set('moodLabel', getMoodLabel(todayRecord.score));
        dataMap.set('todayMood', getMoodLabel(todayRecord.score));
      }

      const streakVal = calcStreak(records);
      dataMap.set('streak', streakVal);

      const formInfo = formBindingData.createFormBindingData(dataMap);
      formProvider.updateForm(formId, formInfo);
    });
  }

  onFormEvent(formId: string, message: string): void { /* 预留 */ }
  onRemoveForm(formId: string): void { /* 清理 */ }
  onDestroy(): void { /* 销毁 */ }

  private async loadAndUpdate(want: Record<string, Object>): Promise<void> {
    const records = await readRecords(this.context);
    const today = formatDateStr(new Date());
    const todayRecord = records.find(r => r.dateStr === today);

    const dataMap = new Map<string, string | number>();
    if (todayRecord) {
      dataMap.set('mood', getMoodEmoji(todayRecord.score));
      dataMap.set('moodLabel', getMoodLabel(todayRecord.score));
      dataMap.set('todayMood', getMoodLabel(todayRecord.score));
    } else {
      dataMap.set('mood', '😐');
      dataMap.set('moodLabel', 'MoodLite');
      dataMap.set('todayMood', '--');
    }
    dataMap.set('streak', calcStreak(records));

    const formInfo = formBindingData.createFormBindingData(dataMap);
  }
}
