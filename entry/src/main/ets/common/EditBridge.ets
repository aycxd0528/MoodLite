/**
 * EditBridge — 页面间编辑数据传递桥
 * 用于 MainPage ↔ AddEntry 的双向通信
 */

import { MoodRecord } from '../model/MoodRecord';

export interface EditPayload {
  record: MoodRecord;
}

let _payload: EditPayload | null = null;
let _skipNextPageShowRefresh: boolean = false;
export type RefreshHandler = () => void | Promise<void>;
let _refreshHandler: RefreshHandler | null = null;

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
export function setEditPayload(p: EditPayload): EditPayload {
  const pending: EditPayload = { record: copyRecord(p.record) };
  _payload = pending;
  return pending;
}

/** 路由失败只撤销该次请求，不能清除后续页面的编辑数据。 */
export function clearEditPayload(pending: EditPayload): void {
  if (_payload === pending) _payload = null;
}

/** 读取并清除编辑数据 */
export function getEditPayload(): EditPayload | null {
  const p = _payload; _payload = null; return p;
}

/** 注册当前 MainPage 的记录刷新处理器。 */
export function setRefreshHandler(handler: RefreshHandler): void {
  _refreshHandler = handler;
}

/** 由 MainPage 销毁生命周期调用。 */
export function clearRefreshHandler(handler: RefreshHandler): void {
  if (_refreshHandler === handler) {
    _refreshHandler = null;
  }
}

/** AddEntry 保存成功后调用，通知 MainPage 刷新 */
export async function signalRefresh(): Promise<boolean> {
  _skipNextPageShowRefresh = false;
  const handler = _refreshHandler;
  if (handler === null) return false;
  try {
    await handler();
    if (_refreshHandler !== handler) return false;
    _skipNextPageShowRefresh = true;
    return true;
  } catch (err) {
    console.error('[MoodLite] immediate refresh failed: ' + JSON.stringify(err));
    return false;
  }
}

/** MainPage 返回时判断是否需要执行回退刷新。 */
export function consumeRefresh(): boolean {
  if (_skipNextPageShowRefresh) {
    _skipNextPageShowRefresh = false;
    return false;
  }
  return true;
}
