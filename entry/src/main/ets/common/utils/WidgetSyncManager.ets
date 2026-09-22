/**
 * WidgetSyncManager —— 卡片数据同步管理器
 *
 * 职责：
 * - 根据 MoodRecord[] 计算桌面卡片摘要
 * - 将摘要写入支持多进程的 RDB 快照
 * - 通过系统 updateForm 立即推送到已注册桌面卡片
 */

import formProvider from '@ohos.app.form.formProvider';
import formBindingData from '@ohos.app.form.formBindingData';
import { MoodRecord } from '../../model/MoodRecord';
import { buildWidgetSummary, WidgetSummary } from '../../viewmodel/WidgetViewModel';
import { readWidgetFormIds, writeWidgetSnapshot } from './WidgetSnapshotStore';

class WidgetSyncManager {
  private static instance: WidgetSyncManager;

  static getInstance(): WidgetSyncManager {
    if (!WidgetSyncManager.instance) {
      WidgetSyncManager.instance = new WidgetSyncManager();
    }
    return WidgetSyncManager.instance;
  }

  /** 保存最新摘要并立即更新全部 MoodLite 卡片。 */
  async updateWidgets(context: Context, records: MoodRecord[]): Promise<void> {
    try {
      const darkMode: boolean = (AppStorage.get('darkMode') as boolean) === true;
      const payload: WidgetSummary = buildWidgetSummary(records, new Date(), darkMode);
      await writeWidgetSnapshot(context, payload);

      const formIds: string[] = await readWidgetFormIds(context);
      const binding: formBindingData.FormBindingData = formBindingData.createFormBindingData(payload);
      for (const formId of formIds) {
        try {
          await formProvider.updateForm(formId, binding);
        } catch (err) {
          console.error('[WidgetSync] updateForm failed for ' + formId + ': ' + JSON.stringify(err));
        }
      }
      console.info('[WidgetSync] snapshot saved; updated ' + formIds.length + ' forms');
    } catch (err) {
      console.error('[WidgetSync] updateWidgets failed: ' + JSON.stringify(err));
    }
  }
}

export default WidgetSyncManager.getInstance();
