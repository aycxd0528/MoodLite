/**
 * WidgetSyncManager —— 卡片数据同步管理器
 *
 * 职责：
 * - 桌面卡片 formId 的注册/注销与持久化
 * - 根据 MoodRecord[] 计算最近 28 天情绪简码
 * - 将 monthDays 数据推送到所有已注册的桌面卡片
 */

import dataPreferences from '@ohos.data.preferences';
import formProvider from '@ohos.app.form.formProvider';
import formBindingData from '@ohos.app.form.formBindingData';
import { MoodRecord, getMoodEmoji, getMoodLabel, formatDateStr } from '../../model/MoodRecord';
import { calcStreak } from '../../viewmodel/StatsViewModel';

const STORE_NAME = 'moodlite_db';
const KEY_FORM_IDS = 'form_ids';

interface WidgetPayload {
  mood: string;
  moodLabel: string;
  todayMood: string;
  streak: number;
  monthDays: number[];
}

class WidgetSyncManager {
  private static instance: WidgetSyncManager;

  static getInstance(): WidgetSyncManager {
    if (!WidgetSyncManager.instance) {
      WidgetSyncManager.instance = new WidgetSyncManager();
    }
    return WidgetSyncManager.instance;
  }

  // ========== formId 管理 ==========

  /** 注册桌面卡片 formId（由 EntryFormAbility.onAddForm 调用） */
  async addFormId(context: Context, formId: string): Promise<void> {
    try {
      const prefs = await dataPreferences.getPreferences(context, STORE_NAME);
      const raw = await prefs.get(KEY_FORM_IDS, '[]') as string;
      const formIds: string[] = JSON.parse(raw);
      if (!formIds.includes(formId)) {
        formIds.push(formId);
        await prefs.put(KEY_FORM_IDS, JSON.stringify(formIds));
        await prefs.flush();
        console.info('[WidgetSync] addFormId: ' + formId);
      }
    } catch (err) {
      console.error('[WidgetSync] addFormId failed: ' + JSON.stringify(err));
    }
  }

  /** 注销桌面卡片 formId（由 EntryFormAbility.onRemoveForm 调用） */
  async removeFormId(context: Context, formId: string): Promise<void> {
    try {
      const prefs = await dataPreferences.getPreferences(context, STORE_NAME);
      const raw = await prefs.get(KEY_FORM_IDS, '[]') as string;
      const formIds: string[] = JSON.parse(raw);
      const idx = formIds.indexOf(formId);
      if (idx >= 0) {
        formIds.splice(idx, 1);
        await prefs.put(KEY_FORM_IDS, JSON.stringify(formIds));
        await prefs.flush();
        console.info('[WidgetSync] removeFormId: ' + formId);
      }
    } catch (err) {
      console.error('[WidgetSync] removeFormId failed: ' + JSON.stringify(err));
    }
  }

  // ========== 数据转换 ==========

  /**
   * 生成本月 7×5 紧凑日历数组
   * 编码 = moodCode × 10 + intensity (0=弱, 1=中, 2=强)
   * moodCode: 0=无 1=低落 2=平静 3=愉悦 4=混合
   */
  getCompactMonthData(records: MoodRecord[]): number[] {
    const now = new Date();
    const year = now.getFullYear();
    const month = now.getMonth() + 1;
    const result: number[] = new Array(35).fill(0);

    // 每天收集：正/负/中条数、最大绝对分
    const posCnt: number[] = new Array(31).fill(0);
    const negCnt: number[] = new Array(31).fill(0);
    const neuCnt: number[] = new Array(31).fill(0);
    const maxAbs: number[] = new Array(31).fill(0);

    for (const r of records) {
      const parts = r.dateStr.split('-');
      if (parts.length !== 3) continue;
      const rYear = parseInt(parts[0]);
      const rMonth = parseInt(parts[1]);
      const rDay = parseInt(parts[2]);
      if (rYear !== year || rMonth !== month) continue;
      const idx = rDay - 1;
      if (idx < 0 || idx >= 31) continue;
      if (r.score >= 1) posCnt[idx]++;
      else if (r.score <= -1) negCnt[idx]++;
      else neuCnt[idx]++;
      const absVal = Math.abs(r.score);
      if (absVal > maxAbs[idx]) maxAbs[idx] = absVal;
    }

    for (let i = 0; i < 31; i++) {
      if (posCnt[i] === 0 && negCnt[i] === 0 && neuCnt[i] === 0) continue;

      const intensity = maxAbs[i] >= 2 ? 2 : (maxAbs[i] >= 1 ? 1 : 0);

      let moodCode = 2;
      if (posCnt[i] > 0 && negCnt[i] > 0) {
        // 正负都有：比数量，谁多就谁主导
        if (posCnt[i] > negCnt[i]) moodCode = 3;       // 开心多 → 粉色
        else if (negCnt[i] > posCnt[i]) moodCode = 1;   // 不开心多 → 蓝色
        else moodCode = 4;                               // 一样多 → 紫色
      } else if (posCnt[i] > 0) {
        moodCode = 3;
      } else if (negCnt[i] > 0) {
        moodCode = 1;
      }

      result[i] = moodCode * 10 + intensity;
    }
    return result;
  }

  // ========== 推送更新 ==========

  /** 将完整数据推送到所有已注册的桌面卡片（同时服务 2x2 和 2x4） */
  async updateWidgets(context: Context, records: MoodRecord[]): Promise<void> {
    try {
      const prefs = await dataPreferences.getPreferences(context, STORE_NAME);
      const raw = await prefs.get(KEY_FORM_IDS, '[]') as string;
      const formIds: string[] = JSON.parse(raw);
      console.info('[WidgetSync] updateWidgets — formIds count=' + formIds.length + ' ids=' + raw);

      if (formIds.length === 0) {
        console.warn('[WidgetSync] No formIds registered — widget may not be added to home screen yet');
        return;
      }

      const today = formatDateStr(new Date());
      const todayRecord = records.find((r: MoodRecord) => r.dateStr === today);

      const payload: WidgetPayload = {
        mood: todayRecord ? getMoodEmoji(todayRecord.score) : '😐',
        moodLabel: todayRecord ? getMoodLabel(todayRecord.score) : 'MoodLite',
        todayMood: todayRecord ? getMoodLabel(todayRecord.score) : '--',
        streak: calcStreak(records).currentStreak,
        monthDays: this.getCompactMonthData(records),
      };
      console.info('[WidgetSync] payload monthDays[0..4]=' + payload.monthDays.slice(0, 5).toString());

      const formData = formBindingData.createFormBindingData(payload);

      for (const fid of formIds) {
        try {
          await formProvider.updateForm(fid, formData);
          console.info('[WidgetSync] updated form: ' + fid);
        } catch (e) {
          console.error('[WidgetSync] updateForm failed for ' + fid + ': ' + JSON.stringify(e));
        }
      }
      console.info('[WidgetSync] updateWidgets done — pushed to ' + formIds.length + ' forms');
    } catch (err) {
      console.error('[WidgetSync] updateWidgets failed: ' + JSON.stringify(err));
    }
  }
}

export default WidgetSyncManager.getInstance();
