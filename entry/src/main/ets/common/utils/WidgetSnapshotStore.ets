/**
 * 桌面卡片跨进程快照。
 *
 * Preferences 不支持多进程访问；RDB 在应用默认沙箱中可由主进程与 Form
 * 进程共享。只保存卡片展示所需的最小摘要，不复制完整日记。
 */

import relationalStore from '@ohos.data.relationalStore';
import { WidgetSummary } from '../../viewmodel/WidgetViewModel';

const DATABASE_NAME: string = 'moodlite_widget.db';
const TABLE_NAME: string = 'widget_snapshot';
const FORMS_TABLE_NAME: string = 'widget_forms';
const SNAPSHOT_ID: number = 1;
const CREATE_TABLE_SQL: string =
  'CREATE TABLE IF NOT EXISTS widget_snapshot (id INTEGER PRIMARY KEY, payload TEXT NOT NULL)';
const CREATE_FORMS_TABLE_SQL: string =
  'CREATE TABLE IF NOT EXISTS widget_forms (form_id TEXT PRIMARY KEY)';

let storePromise: Promise<relationalStore.RdbStore | null> | null = null;

async function createStore(context: Context): Promise<relationalStore.RdbStore | null> {
  try {
    const config: relationalStore.StoreConfig = {
      name: DATABASE_NAME,
      securityLevel: relationalStore.SecurityLevel.S1,
    };
    const store: relationalStore.RdbStore = await relationalStore.getRdbStore(context, config);
    await store.executeSql(CREATE_TABLE_SQL);
    await store.executeSql(CREATE_FORMS_TABLE_SQL);
    return store;
  } catch (err) {
    storePromise = null;
    console.error('[WidgetStore] open failed: ' + JSON.stringify(err));
    return null;
  }
}

async function openStore(context: Context): Promise<relationalStore.RdbStore | null> {
  if (storePromise !== null) return storePromise;
  storePromise = createStore(context);
  return storePromise;
}

/** Form 进程注册系统分配的 ID，主进程用它调用 updateForm。 */
export async function addWidgetFormId(context: Context, formId: string): Promise<void> {
  if (formId.length === 0) return;
  const store: relationalStore.RdbStore | null = await openStore(context);
  if (store === null) return;
  try {
    const values: relationalStore.ValuesBucket = { form_id: formId };
    await store.insert(FORMS_TABLE_NAME, values, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
  } catch (err) {
    console.error('[WidgetStore] add form failed: ' + JSON.stringify(err));
  }
}

export async function removeWidgetFormId(context: Context, formId: string): Promise<void> {
  if (formId.length === 0) return;
  const store: relationalStore.RdbStore | null = await openStore(context);
  if (store === null) return;
  try {
    await store.executeSql('DELETE FROM widget_forms WHERE form_id = ?', [formId]);
  } catch (err) {
    console.error('[WidgetStore] remove form failed: ' + JSON.stringify(err));
  }
}

export async function readWidgetFormIds(context: Context): Promise<string[]> {
  const formIds: string[] = [];
  const store: relationalStore.RdbStore | null = await openStore(context);
  if (store === null) return formIds;
  let resultSet: relationalStore.ResultSet | null = null;
  try {
    resultSet = await store.querySql('SELECT form_id FROM widget_forms');
    if (!resultSet.goToFirstRow()) return formIds;
    const formIdColumn: number = resultSet.getColumnIndex('form_id');
    do {
      formIds.push(resultSet.getString(formIdColumn));
    } while (resultSet.goToNextRow());
    return formIds;
  } catch (err) {
    console.error('[WidgetStore] read forms failed: ' + JSON.stringify(err));
    return formIds;
  } finally {
    if (resultSet !== null) {
      try {
        resultSet.close();
      } catch (err) {
        console.error('[WidgetStore] close forms result failed: ' + JSON.stringify(err));
      }
    }
  }
}

export async function writeWidgetSnapshot(context: Context, summary: WidgetSummary): Promise<void> {
  const store: relationalStore.RdbStore | null = await openStore(context);
  if (store === null) return;
  try {
    const values: relationalStore.ValuesBucket = {
      id: SNAPSHOT_ID,
      payload: JSON.stringify(summary),
    };
    await store.insert(TABLE_NAME, values, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
  } catch (err) {
    console.error('[WidgetStore] write snapshot failed: ' + JSON.stringify(err));
  }
}

export async function readWidgetSnapshot(context: Context): Promise<WidgetSummary | null> {
  const store: relationalStore.RdbStore | null = await openStore(context);
  if (store === null) return null;
  let resultSet: relationalStore.ResultSet | null = null;
  try {
    resultSet = await store.querySql(
      'SELECT payload FROM widget_snapshot WHERE id = ?',
      [SNAPSHOT_ID]
    );
    if (!resultSet.goToFirstRow()) return null;
    const payloadColumn: number = resultSet.getColumnIndex('payload');
    const raw: string = resultSet.getString(payloadColumn);
    return JSON.parse(raw) as WidgetSummary;
  } catch (err) {
    console.error('[WidgetStore] read snapshot failed: ' + JSON.stringify(err));
    return null;
  } finally {
    if (resultSet !== null) {
      try {
        resultSet.close();
      } catch (err) {
        console.error('[WidgetStore] close snapshot result failed: ' + JSON.stringify(err));
      }
    }
  }
}
