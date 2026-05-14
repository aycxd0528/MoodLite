/**
 * AchievementChecker — 成就结算引擎
 * 每次 saveRecord 后调用，仅检测新增记录是否触发新成就
 */

import { MoodRecord, formatDateStr } from '../model/MoodRecord';
import { AchievementItem, ACHIEVEMENTS } from '../model/Achievement';

function todayStr(): string { return formatDateStr(new Date()); }

// ========== 共享进度计算（供 HomeTab + checkNewAchievements 共用） ==========

export interface AchievementProgress {
  value: number;
  target: number;
  label: string;
}

function uniqueStrings(arr: string[]): string[] {
  const set = new Set<string>();
  const out: string[] = [];
  for (const s of arr) {
    if (!set.has(s)) { set.add(s); out.push(s); }
  }
  return out;
}

function uniqueNumbers(arr: number[]): number[] {
  const set = new Set<number>();
  const out: number[] = [];
  for (const n of arr) {
    if (!set.has(n)) { set.add(n); out.push(n); }
  }
  return out;
}

function makeProgress(value: number, target: number, label: string): AchievementProgress {
  return { value: value, target: target, label: label };
}

export function computeAchievementProgress(records: MoodRecord[]): Record<string, AchievementProgress> {
  const result: Record<string, AchievementProgress> = {};
  const len = records.length;
  const daySet: string[] = uniqueStrings(records.map(r => r.dateStr)).sort();

  // streak
  let maxStr = len > 0 ? 1 : 0;
  let curS = len > 0 ? 1 : 0;
  for (let i = 1; i < daySet.length; i++) {
    const diff = new Date(daySet[i]).getTime() - new Date(daySet[i - 1]).getTime();
    if (diff <= 26 * 3600 * 1000) { curS++; if (curS > maxStr) maxStr = curS; } else { curS = 1; }
  }

  result['first_record'] = makeProgress(len > 0 ? 1 : 0, 1, len > 0 ? '已记录 1/1 次' : '已记录 0/1 次');
  result['streak_7'] = makeProgress(maxStr, 7, '连续 ' + maxStr + '/7 天');
  result['total_30'] = makeProgress(len, 30, '累计 ' + len + '/30 篇');

  // palette
  const weekAgo = Date.now() - 7 * 24 * 3600 * 1000;
  const scoreSet: number[] = uniqueNumbers(records.filter(r => r.timestamp >= weekAgo).map(r => r.score));
  result['palette'] = makeProgress(scoreSet.length, 4, scoreSet.length + '/4 种心情');

  // decoder
  let hasDecoder = false;
  for (const r of records) {
    if (r.tags && r.tags.length >= 3 && r.text.trim().length > 0) { hasDecoder = true; break; }
  }
  result['decoder'] = makeProgress(hasDecoder ? 1 : 0, 1, hasDecoder ? '已达成' : '未达成');

  // rainbow — 线性扫描：追踪最近一次低落时间戳，遇到开心时判断距离
  let hasRainbow = false;
  const sorted = records.slice().sort((a, b) => a.timestamp - b.timestamp);
  let lastLowTs: number = -1;
  const FORTY_EIGHT_HOURS = 48 * 3600 * 1000;
  for (let i = 0; i < sorted.length; i++) {
    if (sorted[i].score <= -1) {
      lastLowTs = sorted[i].timestamp;
    } else if (sorted[i].score >= 1 && lastLowTs >= 0) {
      if (sorted[i].timestamp - lastLowTs <= FORTY_EIGHT_HOURS) {
        hasRainbow = true;
        break;
      }
    }
  }
  result['rainbow'] = makeProgress(hasRainbow ? 1 : 0, 1, hasRainbow ? '已达成' : '未达成');

  // calm_5
  const negSet = new Set(records.filter(r => r.score < 0).map(r => r.dateStr));
  const allDays: string[] = uniqueStrings(records.map(r => r.dateStr)).sort();
  let calmMax = 0; let calmCur = 0;
  for (const d of allDays) {
    if (!negSet.has(d)) { calmCur++; if (calmCur > calmMax) calmMax = calmCur; } else { calmCur = 0; }
  }
  result['calm_5'] = makeProgress(calmMax, 5, '连续 ' + calmMax + '/5 天');

  return result;
}

// ========== 成就结算（依赖共享进度计算） ==========

export function checkNewAchievements(
  records: MoodRecord[],
  alreadyUnlocked: Record<string, string>
): AchievementItem[] {
  const result: AchievementItem[] = [];
  const progress = computeAchievementProgress(records);
  const today = todayStr();

  // Build ID lookup from ACHIEVEMENTS definition
  const achievementMap = new Map<string, AchievementItem>();
  for (const a of ACHIEVEMENTS) {
    achievementMap.set(a.id, a);
  }

  for (const id of Object.keys(progress)) {
    if (alreadyUnlocked[id]) continue;
    const p = progress[id];
    if (p.value >= p.target) {
      const base = achievementMap.get(id);
      if (base) {
        result.push({
          id: base.id, title: base.title, desc: base.desc,
          icon: base.icon, color: base.color, category: base.category,
          unlocked: true,
          unlockedDate: today,
          progress: p.target,
          target: p.target,
          progressLabel: '已达成',
        });
      }
    }
  }

  return result;
}
