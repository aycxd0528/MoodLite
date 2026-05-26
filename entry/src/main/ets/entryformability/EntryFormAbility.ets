/**
 * EntryFormAbility —— 桌面小组件 FormExtensionAbility
 *
 * 职责：
 * - 创建/更新/销毁桌面小组件卡片
 * - 通过 formBindingData 向卡片注入实时数据（同时服务 2x2 和 2x4）
 * - 拦截 postCardAction message 事件，实现无感快捷记录（不拉起主应用）
 */

import FormExtensionAbility from '@ohos.app.form.FormExtensionAbility';
import formBindingData from '@ohos.app.form.formBindingData';
import formProvider from '@ohos.app.form.formProvider';
import dataPreferences from '@ohos.data.preferences';
import { MoodRecord, getMoodEmoji, getMoodLabel, formatDateStr, generateUUID } from '../model/MoodRecord';
import { calcStreak } from '../viewmodel/StatsViewModel';
import WidgetSyncManager from '../common/utils/WidgetSyncManager';
import { quickSaveRecord } from '../data/DataManager';

const STORE_NAME = 'moodlite_db';
const KEY_RECORDS = 'records';

interface WidgetData {
  mood: string;
  moodLabel: string;
  todayMood: string;
  todayScore: number;
  streak: number;
  recordDays: number;
  happyPercent: number;
  sadPercent: number;
  neutralPercent: number;
  darkMode: number;
  monthDays: number[];
}

interface QuickLogMessage {
  action: string;
  score: number;
}

async function readRecords(context: Context): Promise<MoodRecord[]> {
  try {
    const prefs = await dataPreferences.getPreferences(context, STORE_NAME);
    const raw = await prefs.get(KEY_RECORDS, '[]') as string;
    return JSON.parse(raw) as MoodRecord[];
  } catch (_err) {
    return [];
  }
}

function buildWidgetData(records: MoodRecord[]): WidgetData {
  const today = formatDateStr(new Date());
  const todayRecord = records.find((r: MoodRecord) => r.dateStr === today);

  const now = new Date();
  const monthKey = now.getFullYear() + '-' + String(now.getMonth() + 1).padStart(2, '0');
  let recordDays = 0;
  let happy = 0, sad = 0, neutral = 0;
  for (const r of records) {
    if (r.dateStr.startsWith(monthKey)) {
      recordDays++;
      if (r.score >= 1) happy++;
      else if (r.score <= -1) sad++;
      else neutral++;
    }
  }
  const total = happy + sad + neutral || 1;
  const happyPercent = Math.round(happy * 100 / total);
  const sadPercent = Math.round(sad * 100 / total);
  const neutralPercent = Math.round(neutral * 100 / total);

  const data: WidgetData = {
    mood: todayRecord ? getMoodEmoji(todayRecord.score) : '😐',
    moodLabel: todayRecord ? getMoodLabel(todayRecord.score) : 'MoodLite',
    todayMood: todayRecord ? getMoodLabel(todayRecord.score) : '--',
    todayScore: todayRecord ? todayRecord.score : 0,
    streak: calcStreak(records).currentStreak,
    recordDays: recordDays,
    happyPercent: happyPercent,
    sadPercent: sadPercent,
    neutralPercent: neutralPercent,
    darkMode: (AppStorage.get('darkMode') as boolean) ? 1 : 0,
    monthDays: WidgetSyncManager.getCompactMonthData(records),
  };
  return data;
}

export default class EntryFormAbility extends FormExtensionAbility {

  onAddForm(want: Record<string, Object>): formBindingData.FormBindingData {
    const formId = this.extractFormId(want);
    if (formId) {
      WidgetSyncManager.addFormId(this.context, formId);
    }

    const initData: WidgetData = {
      mood: '😐', moodLabel: 'MoodLite', todayMood: '--', todayScore: 0, streak: 0,
      recordDays: 0, happyPercent: 0, sadPercent: 0, neutralPercent: 0,
      darkMode: 0, monthDays: new Array(35).fill(0),
    };
    const result = formBindingData.createFormBindingData(initData);

    this.loadAndUpdate(want);

    return result;
  }

  onUpdateForm(formId: string): void {
    readRecords(this.context).then((records: MoodRecord[]) => {
      const data = buildWidgetData(records);
      formProvider.updateForm(formId, formBindingData.createFormBindingData(data));
    });
  }

  /**
   * 拦截卡片 message 事件 — 无感快捷记录。
   * Widget 通过 postCardAction({ action: 'message', params: { action: 'quick_log', score: N } }) 触发。
   * 直接写入 Preferences 并刷新卡片，不拉起主应用。
   */
  onFormEvent(formId: string, message: string): void {
    console.info('[MoodLite] onFormEvent formId=' + formId + ' message=' + message);
    try {
      const parsed: QuickLogMessage = JSON.parse(message) as QuickLogMessage;
      if (parsed.action !== 'quick_log') {
        return;
      }

      const score: number = typeof parsed.score === 'number' ? parsed.score : 0;
      const record: MoodRecord = {
        id: generateUUID(),
        timestamp: Date.now(),
        dateStr: formatDateStr(new Date()),
        score: score,
        text: '',
        images: [],
        location: '',
        tags: [],
      };

      quickSaveRecord(this.context, record).then((ok: boolean) => {
        if (!ok) {
          console.error('[MoodLite] onFormEvent quickSaveRecord 写入失败');
          return;
        }
        // 立即刷新当前卡片显示
        readRecords(this.context).then((records: MoodRecord[]) => {
          const data = buildWidgetData(records);
          formProvider.updateForm(formId, formBindingData.createFormBindingData(data));
        });
        console.info('[MoodLite] onFormEvent quick_log 完成，score=' + score);
      });
    } catch (err) {
      console.error('[MoodLite] onFormEvent 解析失败: ' + JSON.stringify(err));
    }
  }

  onRemoveForm(formId: string): void {
    WidgetSyncManager.removeFormId(this.context, formId);
  }

  onDestroy(): void { /* 销毁 */ }

  private extractFormId(want: Record<string, Object>): string {
    const params = want['parameters'] as Record<string, Object>;
    return (params?.['ohos.extra.param.key.formIdentity'] as string) || '';
  }

  private async loadAndUpdate(want: Record<string, Object>): Promise<void> {
    try {
      const records = await readRecords(this.context);
      const data = buildWidgetData(records);
      const formInfo = formBindingData.createFormBindingData(data);
      const params = want['parameters'] as Record<string, Object>;
      const formId = params?.['ohos.extra.param.key.formIdentity'] as string;
      if (formId) {
        formProvider.updateForm(formId, formInfo);
      }
    } catch (err) {
      console.error('[MoodLite] loadAndUpdate failed: ' + JSON.stringify(err));
    }
  }
}
