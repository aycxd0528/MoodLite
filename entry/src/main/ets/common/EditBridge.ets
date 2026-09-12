/**
 * EditBridge — 页面间编辑数据传递桥
 * 用于 MainPage ↔ AddEntry 的双向通信
 */

import { MoodRecord } from '../model/MoodRecord';

export interface EditPayload {
  record: MoodRecord;
}

let _payload: EditPayload | null = null;
let _needsRefresh: boolean = false;
let _refreshHandler: (() => void) | null = null;

function copyRecord(record: MoodRecord): MoodRecord {
  return {
    id: record.id,
    timestamp: record.timestamp,
    dateStr: record.dateStr,
    score: record.score,
    text: record.text,
    images: [...record.images],
    location: record.location,
    tags: [...record.tags],
  };
}

/** 设置编辑数据，并隔离页面间的数组引用。 */
export function setEditPayload(p: EditPayload): void {
  _payload = { record: copyRecord(p.record) };
}

/** 读取并清除编辑数据 */
export function getEditPayload(): EditPayload | null {
  const p = _payload; _payload = null; return p;
}

/** 注册当前 MainPage 的记录刷新处理器。 */
export function setRefreshHandler(handler: () => void): void {
  _refreshHandler = handler;
}

/** AddEntry 保存成功后调用，通知 MainPage 刷新 */
export function signalRefresh(): void {
  _needsRefresh = true;
  _refreshHandler?.();
}

/** MainPage onPageShow 中检查，消费后自动清除 */
export function consumeRefresh(): boolean {
  if (_needsRefresh) { _needsRefresh = false; return true; }
  return false;
}
