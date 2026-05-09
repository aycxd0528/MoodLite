/**
 * EditBridge — 页面间编辑数据传递桥
 * 用于 MainPage ↔ AddEntry 的双向通信
 */

export interface EditPayload {
  id: string;
  text: string;
  score: number;
  tags: string[];
}

let _payload: EditPayload | null = null;
let _needsRefresh: boolean = false;

/** 设置编辑数据 */
export function setEditPayload(p: EditPayload): void { _payload = p; }

/** 读取并清除编辑数据 */
export function getEditPayload(): EditPayload | null {
  const p = _payload; _payload = null; return p;
}

/** AddEntry 保存成功后调用，通知 MainPage 刷新 */
export function signalRefresh(): void { _needsRefresh = true; }

/** MainPage onPageShow 中检查，消费后自动清除 */
export function consumeRefresh(): boolean {
  if (_needsRefresh) { _needsRefresh = false; return true; }
  return false;
}
