/**
 * EntryFormAbility —— 桌面小组件 FormExtensionAbility
 *
 * 职责：
 * - 创建/更新/销毁桌面小组件卡片
 * - 通过 formBindingData 向 2×2 卡片注入本地摘要数据
 */

import FormExtensionAbility from '@ohos.app.form.FormExtensionAbility';
import formBindingData from '@ohos.app.form.formBindingData';
import formProvider from '@ohos.app.form.formProvider';
import dataPreferences from '@ohos.data.preferences';
import { MoodRecord } from '../model/MoodRecord';
import { parseMoodRecords } from '../model/MoodRecordPolicy';
import { buildWidgetSummary, WidgetSummary } from '../viewmodel/WidgetViewModel';
import WidgetSyncManager from '../common/utils/WidgetSyncManager';

const STORE_NAME = 'moodlite_db';
const KEY_RECORDS = 'records';

async function readRecords(context: Context): Promise<MoodRecord[]> {
  try {
    const prefs = await dataPreferences.getPreferences(context, STORE_NAME);
    const raw = await prefs.get(KEY_RECORDS, '[]') as string;
    return parseMoodRecords(raw);
  } catch (_err) {
    return [];
  }
}

export default class EntryFormAbility extends FormExtensionAbility {

  onAddForm(want: Record<string, Object>): formBindingData.FormBindingData {
    const formId = this.extractFormId(want);
    if (formId) {
      WidgetSyncManager.addFormId(this.context, formId);
    }

    const initData: WidgetSummary = buildWidgetSummary([], new Date(), false);
    const result = formBindingData.createFormBindingData(initData);

    this.loadAndUpdate(want);

    return result;
  }

  onUpdateForm(formId: string): void {
    readRecords(this.context).then((records: MoodRecord[]) => {
      const data: WidgetSummary = buildWidgetSummary(records, new Date(), this.isDarkMode());
      formProvider.updateForm(formId, formBindingData.createFormBindingData(data));
    });
  }

  onRemoveForm(formId: string): void {
    WidgetSyncManager.removeFormId(this.context, formId);
  }

  onDestroy(): void { /* 销毁 */ }

  private extractFormId(want: Record<string, Object>): string {
    const params = want['parameters'] as Record<string, Object>;
    return (params?.['ohos.extra.param.key.formIdentity'] as string) || '';
  }

  private isDarkMode(): boolean {
    return (AppStorage.get('darkMode') as boolean) === true;
  }

  private async loadAndUpdate(want: Record<string, Object>): Promise<void> {
    try {
      const records = await readRecords(this.context);
      const data: WidgetSummary = buildWidgetSummary(records, new Date(), this.isDarkMode());
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
