import { MoodRecord, formatDateStr, getMoodEmoji, getMoodLabel } from '../model/MoodRecord';
import { calcStreak, countUniqueRecordDays, recordsForMonth } from './StatsViewModel';

export interface WidgetSummary {
  mood: string;
  moodLabel: string;
  todayMood: string;
  todayScore: number;
  streak: number;
  recordDays: number;
  happyPercent: number;
  sadPercent: number;
  neutralPercent: number;
  darkMode: number;
  monthDays: number[];
}

export function buildCompactMonthData(
  records: MoodRecord[],
  year: number,
  month: number,
): number[] {
  const result: number[] = new Array(35).fill(0);
  const positive: number[] = new Array(31).fill(0);
  const negative: number[] = new Array(31).fill(0);
  const neutral: number[] = new Array(31).fill(0);
  const maxAbsolute: number[] = new Array(31).fill(0);

  for (const record of recordsForMonth(records, year, month)) {
    const parts: string[] = record.dateStr.split('-');
    const index: number = parseInt(parts[2]) - 1;
    if (index < 0 || index >= 31) continue;
    if (record.score >= 1) positive[index]++;
    else if (record.score <= -1) negative[index]++;
    else neutral[index]++;
    maxAbsolute[index] = Math.max(maxAbsolute[index], Math.abs(record.score));
  }

  for (let index = 0; index < 31; index++) {
    const count: number = positive[index] + negative[index] + neutral[index];
    if (count === 0) continue;
    const intensity: number = Math.min(4, maxAbsolute[index] * 2 + (count > 1 ? 1 : 0));
    let moodCode: number = 2;
    if (positive[index] > 0 && negative[index] > 0) {
      if (positive[index] > negative[index]) moodCode = 3;
      else if (negative[index] > positive[index]) moodCode = 1;
      else moodCode = 4;
    } else if (positive[index] > 0) {
      moodCode = 3;
    } else if (negative[index] > 0) {
      moodCode = 1;
    }
    result[index] = moodCode * 10 + intensity;
  }
  return result;
}

export function buildWidgetSummary(
  records: MoodRecord[],
  now: Date,
  darkMode: boolean,
): WidgetSummary {
  const year: number = now.getFullYear();
  const month: number = now.getMonth() + 1;
  const monthRecords: MoodRecord[] = recordsForMonth(records, year, month);
  const today: string = formatDateStr(now);
  let todayRecord: MoodRecord | null = null;
  let happy: number = 0;
  let sad: number = 0;
  let neutral: number = 0;

  for (const record of monthRecords) {
    if (record.score >= 1) happy++;
    else if (record.score <= -1) sad++;
    else neutral++;
    if (record.dateStr === today && (todayRecord === null || record.timestamp > todayRecord.timestamp)) {
      todayRecord = record;
    }
  }

  const total: number = happy + sad + neutral;
  const happyPercent: number = total > 0 ? Math.round(happy * 100 / total) : 0;
  const sadPercent: number = total > 0 ? Math.round(sad * 100 / total) : 0;
  const neutralPercent: number = total > 0 ? Math.max(0, 100 - happyPercent - sadPercent) : 0;

  return {
    mood: todayRecord ? getMoodEmoji(todayRecord.score) : '😐',
    moodLabel: todayRecord ? getMoodLabel(todayRecord.score) : 'MoodLite',
    todayMood: todayRecord ? getMoodLabel(todayRecord.score) : '--',
    todayScore: todayRecord ? todayRecord.score : 0,
    streak: calcStreak(records).currentStreak,
    recordDays: countUniqueRecordDays(monthRecords),
    happyPercent: happyPercent,
    sadPercent: sadPercent,
    neutralPercent: neutralPercent,
    darkMode: darkMode ? 1 : 0,
    monthDays: buildCompactMonthData(monthRecords, year, month),
  };
}
