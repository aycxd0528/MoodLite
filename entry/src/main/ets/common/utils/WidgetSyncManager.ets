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
import { MoodRecord } from '../../model/MoodRecord';
import { buildWidgetSummary, WidgetSummary } from '../../viewmodel/WidgetViewModel';

const STORE_NAME = 'moodlite_widget';
const KEY_FORM_IDS = 'form_ids';

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

  // ========== 推送更新 ==========

  /** 将本地摘要推送到所有已注册的 2×2 桌面卡片 */
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

      const darkMode: boolean = (AppStorage.get('darkMode') as boolean) === true;
      const payload: WidgetSummary = buildWidgetSummary(records, new Date(), darkMode);
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
