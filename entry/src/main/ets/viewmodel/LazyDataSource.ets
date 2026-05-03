/**
 * LazyDataSource — 懒加载数据源
 * 配合 LazyForEach 实现 List 的按需渲染
 */

import { MoodRecord } from '../model/MoodRecord';

export class RecordDataSource implements IDataSource {
  private data: MoodRecord[] = [];
  private listeners: DataChangeListener[] = [];

  totalCount(): number { return this.data.length; }

  getData(index: number): MoodRecord {
    return this.data[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const idx = this.listeners.indexOf(listener);
    if (idx >= 0) this.listeners.splice(idx, 1);
  }

  notifyDataReload(): void {
    for (const l of this.listeners) l.onDataReloaded();
  }

  setData(records: MoodRecord[]): void {
    this.data = records;
    this.notifyDataReload();
  }
}
