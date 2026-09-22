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
import formInfo from '@ohos.app.form.formInfo';
import { buildWidgetSummary, WidgetSummary } from '../viewmodel/WidgetViewModel';
import {
  addWidgetFormId,
  readWidgetSnapshot,
  removeWidgetFormId,
} from '../common/utils/WidgetSnapshotStore';

export default class EntryFormAbility extends FormExtensionAbility {

  onAddForm(want: Record<string, Object>): formBindingData.FormBindingData {
    const formId: string = this.extractFormId(want);
    if (formId.length > 0) {
      addWidgetFormId(this.context, formId).catch((err: Error) => {
        console.error('[MoodLite] addWidgetFormId failed: ' + JSON.stringify(err));
      });
    }

    const initData: WidgetSummary = buildWidgetSummary([], new Date(), false);
    const result = formBindingData.createFormBindingData(initData);

    this.loadAndUpdate(want);

    return result;
  }

  onUpdateForm(formId: string): void {
    addWidgetFormId(this.context, formId).then(() => readWidgetSnapshot(this.context))
      .then((snapshot: WidgetSummary | null) => {
        const data: WidgetSummary = snapshot ?? buildWidgetSummary([], new Date(), false);
        return formProvider.updateForm(formId, formBindingData.createFormBindingData(data));
      }).catch((err: Error) => {
        console.error('[MoodLite] onUpdateForm failed: ' + JSON.stringify(err));
      });
  }

  onRemoveForm(formId: string): void {
    removeWidgetFormId(this.context, formId).catch((err: Error) => {
      console.error('[MoodLite] removeWidgetFormId failed: ' + JSON.stringify(err));
    });
  }

  onDestroy(): void { /* 销毁 */ }

  private extractFormId(want: Record<string, Object>): string {
    const params = want['parameters'] as Record<string, Object>;
    return (params?.[formInfo.FormParam.IDENTITY_KEY] as string) || '';
  }

  private async loadAndUpdate(want: Record<string, Object>): Promise<void> {
    try {
      const snapshot: WidgetSummary | null = await readWidgetSnapshot(this.context);
      const data: WidgetSummary = snapshot ?? buildWidgetSummary([], new Date(), false);
      const binding = formBindingData.createFormBindingData(data);
      const formId = this.extractFormId(want);
      if (formId) {
        await formProvider.updateForm(formId, binding);
      }
    } catch (err) {
      console.error('[MoodLite] loadAndUpdate failed: ' + JSON.stringify(err));
    }
  }
}
