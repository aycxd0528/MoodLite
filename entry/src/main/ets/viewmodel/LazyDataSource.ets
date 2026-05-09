/**
 * LazyDataSource — 懒加载数据源
 * 配合 LazyForEach 实现 List 的按需渲染
 */

import { MoodRecord } from '../model/MoodRecord';

// ============ RecordDataSource (flat records) ============

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

// ============ GroupDataSource (lazy groups, for ListItemGroup) ============

export class GroupDataSource implements IDataSource {
  private groups: MonthGroup[] = [];
  private listeners: DataChangeListener[] = [];

  totalCount(): number { return this.groups.length; }

  getData(index: number): MonthGroup {
    return this.groups[index];
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

  setData(groups: MonthGroup[]): void {
    this.groups = groups;
    this.notifyDataReload();
  }
}

// ============ TimelineDataSource (fully flattened, for flat LazyForEach) ============

export interface MonthGroup {
  monthTitle: string;
  records: MoodRecord[];
}

export interface TimelineItem {
  type: 'header' | 'record';
  monthLabel?: string;
  record?: MoodRecord;
}

export class TimelineDataSource implements IDataSource {
  private items: TimelineItem[] = [];
  private listeners: DataChangeListener[] = [];

  totalCount(): number { return this.items.length; }

  getData(index: number): TimelineItem {
    return this.items[index];
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

  setData(groups: MonthGroup[]): void {
    this.items = [];
    for (const group of groups) {
      this.items.push({ type: 'header', monthLabel: group.monthTitle });
      for (const record of group.records) {
        this.items.push({ type: 'record', record: record });
      }
    }
    this.notifyDataReload();
  }
}
