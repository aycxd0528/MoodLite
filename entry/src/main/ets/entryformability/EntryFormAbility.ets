/**
 * EntryFormAbility —— 桌面小组件 FormExtensionAbility
 *
 * 职责：
 * - 创建/更新/销毁桌面小组件卡片
 * - 通过 formBindingData 向卡片注入实时数据（同时服务 2x2 和 2x4）
 */

import FormExtensionAbility from '@ohos.app.form.FormExtensionAbility';
import formBindingData from '@ohos.app.form.formBindingData';
import formProvider from '@ohos.app.form.formProvider';
import dataPreferences from '@ohos.data.preferences';
import { MoodRecord, getMoodEmoji, getMoodLabel, formatDateStr } from '../model/MoodRecord';
import { calcStreak } from '../viewmodel/StatsViewModel';
import WidgetSyncManager from '../common/utils/WidgetSyncManager';

const STORE_NAME = 'moodlite_db';
const KEY_RECORDS = 'records';

interface WidgetData {
  mood: string;
  moodLabel: string;
  todayMood: string;
  streak: number;
  monthDays: number[];
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

  const data: WidgetData = {
    mood: todayRecord ? getMoodEmoji(todayRecord.score) : '😐',
    moodLabel: todayRecord ? getMoodLabel(todayRecord.score) : 'MoodLite',
    todayMood: todayRecord ? getMoodLabel(todayRecord.score) : '--',
    streak: calcStreak(records).currentStreak,
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

    // 返回初始数据，异步拉取真实数据后推送
    const initData: WidgetData = {
      mood: '😐', moodLabel: 'MoodLite', todayMood: '--', streak: 0,
      monthDays: new Array(35).fill(0),
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

  onFormEvent(formId: string, message: string): void { /* 预留 */ }

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
