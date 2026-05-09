/**
 * StatsViewModel —— 统计视图模型（数据聚合层）ArkTS Strict
 *
 * 职责：
 * - 月历网格数据生成（含前后月填充）
 * - 月度汇总指标聚合
 * - 情绪分值分布
 * - 周均趋势分解
 * - 连续记录天数（Streak）检测
 * - 月内情绪走势方向判定
 */

import {
  MoodRecord,
  CalendarDayItem,
  MonthlyStats,
  formatDateStr,
} from '../model/MoodRecord';

const DAYS_IN_WEEK = 7;

// ========== 聚合类型 ==========

export interface ScoreBucket {
  score: number;
  count: number;
  label: string;
  emoji: string;
  color: string;
}

export interface WeeklySnapshot {
  weekIndex: number;
  label: string;
  avgScore: number;
  daysCount: number;
  weight: number;
}

export interface StreakInfo {
  currentStreak: number;
  longestStreak: number;
  streakStart: string;
}

export type TrendDirection = 'improving' | 'declining' | 'stable';

/** 周桶中间数据结构 */
interface WeekBucket {
  label: string;
  scores: number[];
  days: string[];
}

// ========== 辅助函数 ==========

function maxOfArray(arr: number[]): number {
  let max = -999;
  for (const v of arr) {
    if (v > max) max = v;
  }
  return max;
}

function minOfArray(arr: number[]): number {
  let min = 999;
  for (const v of arr) {
    if (v < min) min = v;
  }
  return min;
}

function uniqueDates(records: MoodRecord[]): string[] {
  const set = new Set<string>();
  for (const r of records) {
    set.add(r.dateStr);
  }
  const arr: string[] = [];
  set.forEach((v: string) => { arr.push(v); });
  arr.sort();
  return arr;
}

function sortDesc(arr: string[]): string[] {
  const copy: string[] = [];
  for (const v of arr) {
    copy.push(v);
  }
  copy.sort();
  copy.reverse();
  return copy;
}

function parseYearMonth(dateStr: string): number[] {
  const parts = dateStr.split('-');
  return [parseInt(parts[0]), parseInt(parts[1])];
}

// ========== 热力图生成 ==========

export function generateCalendarGrid(
  year: number,
  month: number,
  records: MoodRecord[]
): CalendarDayItem[] {
  const firstDay = new Date(year, month - 1, 1);
  const lastDay = new Date(year, month, 0);
  const daysInMonth = lastDay.getDate();
  const startWeekday = firstDay.getDay();

  const prevMonthLastDay = new Date(year, month - 1, 0).getDate();
  const grid: CalendarDayItem[] = [];

  for (let i = 0; i < startWeekday; i++) {
    const day = prevMonthLastDay - startWeekday + i + 1;
    const date = new Date(year, month - 2, day);
    grid.push({
      dateStr: formatDateStr(date),
      avgScore: 0,
      count: 0,
      dayOfWeek: i,
      isCurrentMonth: false,
      moodCode: 0,
    });
  }

  for (let d = 1; d <= daysInMonth; d++) {
    const date = new Date(year, month - 1, d);
    const dateStr = formatDateStr(date);
    let daySum = 0;
    let dayCount = 0;
    let posCount = 0;
    let negCount = 0;
    for (const r of records) {
      if (r.dateStr === dateStr) {
        daySum += r.score;
        dayCount++;
        if (r.score >= 1) posCount++;
        if (r.score <= -1) negCount++;
      }
    }
    const avg = dayCount > 0 ? daySum / dayCount : 0;

    let code = 0;
    if (dayCount > 0) {
      if (posCount > 0 && negCount > 0) {
        // 正负都有：比数量，谁多就谁主导
        if (posCount > negCount) code = 3;       // 开心多 → 粉色
        else if (negCount > posCount) code = 1;  // 不开心多 → 蓝色
        else code = 4;                            // 一样多 → 紫色
      } else if (posCount > 0) {
        code = 3;
      } else if (negCount > 0) {
        code = 1;
      } else {
        code = 2;
      }
    }

    grid.push({
      dateStr: dateStr,
      avgScore: Math.round(avg * 10) / 10,
      count: dayCount,
      dayOfWeek: date.getDay(),
      isCurrentMonth: true,
      moodCode: code,
    });
  }

  const remaining = DAYS_IN_WEEK * 6 - grid.length;
  for (let i = 1; i <= remaining; i++) {
    const date = new Date(year, month, i);
    grid.push({
      dateStr: formatDateStr(date),
      avgScore: 0,
      count: 0,
      dayOfWeek: date.getDay(),
      isCurrentMonth: false,
      moodCode: 0,
    });
  }

  return grid;
}

// ========== 月度统计 ==========

export function calcMonthlyStats(
  year: number,
  month: number,
  records: MoodRecord[]
): MonthlyStats {
  const monthRecords: MoodRecord[] = [];
  const daySet = new Set<string>();
  for (const r of records) {
    const ym = parseYearMonth(r.dateStr);
    if (ym[0] === year && ym[1] === month) {
      monthRecords.push(r);
      daySet.add(r.dateStr);
    }
  }

  // 按「条」计数，不是按「天」
  let happyCount = 0;
  let neutralCount = 0;
  let sadCount = 0;
  let totalScore = 0;
  let maxScore = -3;
  let minScore = 3;

  for (const r of monthRecords) {
    totalScore += r.score;
    maxScore = Math.max(maxScore, r.score);
    minScore = Math.min(minScore, r.score);
    if (r.score >= 1) happyCount++;
    else if (r.score <= -1) sadCount++;
    else neutralCount++;
  }

  const totalDays = daySet.size;
  const totalRecords = monthRecords.length;

  return {
    year: year,
    month: month,
    totalDays: totalDays,
    happyDays: happyCount,
    neutralDays: neutralCount,
    sadDays: sadCount,
    averageScore: totalRecords > 0 ? Math.round((totalScore / totalRecords) * 10) / 10 : 0,
    maxScore: maxScore === -3 ? 0 : maxScore,
    minScore: minScore === 3 ? 0 : minScore,
  };
}

// ========== 热力图颜色 ==========

// ========== 热力图颜色 (支持 5 色阶 & 深浅模式) ==========
export function heatmapColor(moodCode: number, absScore: number, isCurrentMonth: boolean, isDarkMode: boolean = false): string {
  if (!isCurrentMonth) return 'transparent';
  if (moodCode === 0) return isDarkMode ? '#3D3D5A' : '#F5F6F8'; // 无记录

  // absScore 真实范围 0~2，5 个档位各占 0.4
  const lvl5 = absScore >= 1.8;              // ±2
  const lvl4 = absScore >= 1.4 && absScore < 1.8;  // ±1.5
  const lvl3 = absScore >= 1.0 && absScore < 1.4;  // ±1
  const lvl2 = absScore >= 0.5 && absScore < 1.0;  // ±0.5
  // < 0.5 → lvl1（含混合情绪 avg=0）

  if (moodCode === 1) { // 低落 → 蓝
    if (isDarkMode) {
      if (lvl5) return '#7BB8F0';
      if (lvl4) return '#5EA3E0';
      if (lvl3) return '#458ED0';
      if (lvl2) return '#3078B8';
      return '#1E5E9A';
    } else {
      if (lvl5) return '#3B7EC2';
      if (lvl4) return '#5095D8';
      if (lvl3) return '#6DADE5';
      if (lvl2) return '#90C4F0';
      return '#B5D8F7';
    }
  }

  if (moodCode === 2) { // 平静 → 金
    if (isDarkMode) {
      if (lvl5) return '#FFD700';
      if (lvl4) return '#E0C200';
      if (lvl3) return '#C0A800';
      if (lvl2) return '#A09000';
      return '#807000';
    } else {
      if (lvl5) return '#FFD700';
      if (lvl4) return '#FFE44D';
      if (lvl3) return '#FFED80';
      if (lvl2) return '#FFF5B3';
      return '#FFFAE0';
    }
  }

  if (moodCode === 3) { // 愉悦 → 粉
    if (isDarkMode) {
      if (lvl5) return '#F080A0';
      if (lvl4) return '#D06888';
      if (lvl3) return '#B85070';
      if (lvl2) return '#A04060';
      return '#803048';
    } else {
      if (lvl5) return '#D0557A';
      if (lvl4) return '#E87398';
      if (lvl3) return '#F590AE';
      if (lvl2) return '#FAAEC7';
      return '#FFCCDD';
    }
  }

  if (moodCode === 4) { // 混合 → 紫
    if (isDarkMode) {
      if (lvl5) return '#C080F0';
      if (lvl4) return '#A860D8';
      if (lvl3) return '#9050C0';
      if (lvl2) return '#7840A8';
      return '#603090';
    } else {
      if (lvl5) return '#6A1B9A';
      if (lvl4) return '#8E24AA';
      if (lvl3) return '#AB47BC';
      if (lvl2) return '#C265D2';
      return '#D49DE4';
    }
  }

  return isDarkMode ? '#3D3D5A' : '#F5F6F8';
}

export const WEEKDAY_HEADERS: string[] = ['日', '一', '二', '三', '四', '五', '六'];

// ========== 分值分布 ==========

export function calcScoreDistribution(
  year: number,
  month: number,
  records: MoodRecord[]
): ScoreBucket[] {
  const monthRecords: MoodRecord[] = [];
  for (const r of records) {
    const ym = parseYearMonth(r.dateStr);
    if (ym[0] === year && ym[1] === month) {
      monthRecords.push(r);
    }
  }

  const countMap = new Map<number, number>();
  for (let s = -2; s <= 2; s++) {
    countMap.set(s, 0);
  }
  for (const r of monthRecords) {
    const prev = countMap.get(r.score) || 0;
    countMap.set(r.score, prev + 1);
  }

  const labels: string[] = ['很糟糕', '不太好', '平静', '不错', '很棒'];
  const emojis: string[] = ['😢', '😔', '😐', '🙂', '😄'];
  const colors: string[] = ['#8BA9B8', '#AEC6CF', '#9CA3AF', '#FFB3C5', '#FF8BA7'];

  const buckets: ScoreBucket[] = [];
  for (let s = -2; s <= 2; s++) {
    buckets.push({
      score: s,
      count: countMap.get(s) || 0,
      label: labels[s + 2],
      emoji: emojis[s + 2],
      color: colors[s + 2],
    });
  }
  return buckets;
}

// ========== 周趋势 ==========

export function calcWeeklyBreakdown(
  year: number,
  month: number,
  records: MoodRecord[]
): WeeklySnapshot[] {
  const monthRecords: MoodRecord[] = [];
  for (const r of records) {
    const ym = parseYearMonth(r.dateStr);
    if (ym[0] === year && ym[1] === month) {
      monthRecords.push(r);
    }
  }

  const dayMap = new Map<string, number[]>();
  for (const r of monthRecords) {
    let list = dayMap.get(r.dateStr);
    if (!list) {
      list = [];
    }
    list.push(r.score);
    dayMap.set(r.dateStr, list);
  }

  const weeks: WeekBucket[] = [
    { label: '第1周', scores: [], days: [] },
    { label: '第2周', scores: [], days: [] },
    { label: '第3周', scores: [], days: [] },
    { label: '第4周', scores: [], days: [] },
    { label: '第5周', scores: [], days: [] },
  ];

  const dateKeys: string[] = [];
  dayMap.forEach((_val: number[], key: string) => { dateKeys.push(key); });

  for (const dateStr of dateKeys) {
    const scores = dayMap.get(dateStr);
    if (!scores) continue;
    const dayNum = parseInt(dateStr.split('-')[2], 10);
    const avg = scores.reduce((a, b) => a + b, 0) / scores.length;
    const weekIdx = Math.min(Math.floor((dayNum - 1) / 7), 4);
    weeks[weekIdx].scores.push(avg);
    weeks[weekIdx].days.push(dateStr);
  }

  const totalDays = dayMap.size;

  const snapshots: WeeklySnapshot[] = [];
  for (let i = 0; i < weeks.length; i++) {
    const w = weeks[i];
    if (w.scores.length === 0 && i >= 4) continue;
    let wAvg = 0;
    if (w.scores.length > 0) {
      const s = w.scores.reduce((a, b) => a + b, 0) / w.scores.length;
      wAvg = Math.round(s * 10) / 10;
    }
    snapshots.push({
      weekIndex: i,
      label: i <= 3 ? '第' + (i + 1).toString() + '周' : '第5周',
      avgScore: wAvg,
      daysCount: w.days.length,
      weight: totalDays > 0 ? w.days.length / totalDays : 0,
    });
  }

  return snapshots;
}

// ========== 连续天数 ==========

export function calcStreak(records: MoodRecord[]): StreakInfo {
  if (records.length === 0) {
    return { currentStreak: 0, longestStreak: 0, streakStart: '' };
  }

  const uniqueDays = uniqueDates(records);

  let longest = 0;
  let cur = 0;
  let lastDate: Date | null = null;

  for (const day of uniqueDays) {
    const d = new Date(day);
    if (lastDate === null) {
      cur = 1;
    } else {
      const diff = (d.getTime() - lastDate.getTime()) / 86400000;
      if (Math.abs(diff - 1) < 0.01) {
        cur++;
      } else {
        cur = 1;
      }
    }
    longest = Math.max(longest, cur);
    lastDate = d;
  }

  let currentStreak = 0;
  let streakStart = '';
  const now = new Date();
  const today = formatDateStr(now);
  const yesterday = formatDateStr(new Date(now.getTime() - 86400000));

  let check = today;
  if (!uniqueDays.includes(today)) {
    check = yesterday;
  }

  const sortedDesc = sortDesc(uniqueDays);
  if (sortedDesc.length > 0 && sortedDesc[0] < check) {
    check = sortedDesc[0];
  }

  let cursor = new Date(check);
  for (let i = 0; i < sortedDesc.length; i++) {
    const day = formatDateStr(cursor);
    if (uniqueDays.includes(day)) {
      if (currentStreak === 0) {
        streakStart = day;
      }
      currentStreak++;
      cursor = new Date(cursor.getTime() - 86400000);
    } else {
      break;
    }
  }

  return {
    currentStreak: currentStreak,
    longestStreak: longest,
    streakStart: streakStart,
  };
}

// ========== 走势方向 ==========

export function calcTrendDirection(
  year: number,
  month: number,
  records: MoodRecord[]
): TrendDirection {
  const monthRecords: MoodRecord[] = [];
  for (const r of records) {
    const ym = parseYearMonth(r.dateStr);
    if (ym[0] === year && ym[1] === month) {
      monthRecords.push(r);
    }
  }

  if (monthRecords.length < 4) return 'stable';

  const dayMap = new Map<string, number[]>();
  for (const r of monthRecords) {
    let list = dayMap.get(r.dateStr);
    if (!list) {
      list = [];
    }
    list.push(r.score);
    dayMap.set(r.dateStr, list);
  }

  const midDay = 15;
  let firstSum = 0;
  let firstCount = 0;
  let secondSum = 0;
  let secondCount = 0;

  const dKeys: string[] = [];
  dayMap.forEach((_v: number[], k: string) => { dKeys.push(k); });

  for (const dateStr of dKeys) {
    const scores = dayMap.get(dateStr);
    if (!scores) continue;
    const dayNum = parseInt(dateStr.split('-')[2], 10);
    const avg = scores.reduce((a, b) => a + b, 0) / scores.length;
    if (dayNum <= midDay) {
      firstSum += avg;
      firstCount++;
    } else {
      secondSum += avg;
      secondCount++;
    }
  }

  if (firstCount === 0 || secondCount === 0) return 'stable';

  const firstAvg = firstSum / firstCount;
  const secondAvg = secondSum / secondCount;
  const diff = secondAvg - firstAvg;

  if (diff > 0.3) return 'improving';
  if (diff < -0.3) return 'declining';
  return 'stable';
}

// ========== 标签分布 ==========

export interface TagDistribution {
  tag: string;
  count: number;
  avgScore: number;
}

interface TagAcc {
  count: number;
  totalScore: number;
}

export function calcTagDistribution(records: MoodRecord[]): TagDistribution[] {
  const tagMap = new Map<string, TagAcc>();
  for (const r of records) {
    if (!r.tags || r.tags.length === 0) continue;
    for (const tag of r.tags) {
      const entry = tagMap.get(tag);
      if (entry) {
        entry.count++;
        entry.totalScore += r.score;
      } else {
        tagMap.set(tag, { count: 1, totalScore: r.score } as TagAcc);
      }
    }
  }
  const result: TagDistribution[] = [];
  tagMap.forEach((v, k) => {
    result.push({ tag: k, count: v.count, avgScore: Math.round((v.totalScore / v.count) * 10) / 10 } as TagDistribution);
  });
  result.sort((a, b) => b.count - a.count);
  return result;
}
