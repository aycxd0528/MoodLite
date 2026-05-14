/**
 * LazyDataSource — 共享类型定义
 */

import { MoodRecord } from '../model/MoodRecord';

export interface MonthGroup {
  monthTitle: string;
  records: MoodRecord[];
}
