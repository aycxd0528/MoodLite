/**
 * AchievementChecker — 成就结算引擎
 * 每次 saveRecord 后调用，仅检测新增记录是否触发新成就
 */

import { MoodRecord, formatDateStr } from '../model/MoodRecord';
import { AchievementItem } from '../model/Achievement';

function daysSinceEpoch(dateStr: string): number {
  const parts = dateStr.split('-');
  const y = parseInt(parts[0]); const m = parseInt(parts[1]); const d = parseInt(parts[2]);
  const a = Math.floor((14 - m) / 12);
  const yy = y + 4800 - a; const mm = m + 12 * a - 3;
  return d + Math.floor((153 * mm + 2) / 5) + 365 * yy + Math.floor(yy / 4) - Math.floor(yy / 100) + Math.floor(yy / 400) - 32045;
}

function todayStr(): string { return formatDateStr(new Date()); }

export function checkNewAchievements(
  records: MoodRecord[],
  alreadyUnlocked: Record<string, string>
): AchievementItem[] {
  const result: AchievementItem[] = [];
  const now = Date.now();

  if (!alreadyUnlocked['first_record'] && records.length >= 1) {
    const item: AchievementItem = {
      id: 'first_record', title: '初识自我', desc: '首次记录心情',
      icon: $r('app.media.achievement_seed'), color: '#6BB6FF',
      category: 'habit', unlocked: true, unlockedDate: todayStr(),
      progress: 1, target: 1, progressLabel: '已达成' };
    result.push(item);
  }

  if (!alreadyUnlocked['streak_7']) {
    const days = new Set<string>();
    for (const r of records) days.add(r.dateStr);
    const sorted = Array.from(days).sort();
    let streak = 1; let maxStreak = 1;
    for (let i = 1; i < sorted.length; i++) {
      if (daysSinceEpoch(sorted[i]) - daysSinceEpoch(sorted[i - 1]) === 1) { streak++; if (streak > maxStreak) maxStreak = streak; }
      else { streak = 1; }
    }
    if (maxStreak >= 7) {
      const item: AchievementItem = {
        id: 'streak_7', title: '拾级而上', desc: '连续记录 7 天',
        icon: $r('app.media.achievement_steps'), color: '#7ED321',
        category: 'habit', unlocked: true, unlockedDate: todayStr(),
        progress: 7, target: 7, progressLabel: '已达成' };
      result.push(item);
    }
  }

  if (!alreadyUnlocked['total_30'] && records.length >= 30) {
    const item: AchievementItem = {
      id: 'total_30', title: '岁月痕迹', desc: '累计记录满 30 篇',
      icon: $r('app.media.achievement_hourglass'), color: '#FFB86C',
      category: 'habit', unlocked: true, unlockedDate: todayStr(),
      progress: 30, target: 30, progressLabel: '已达成' };
    result.push(item);
  }

  if (!alreadyUnlocked['palette']) {
    const weekAgo = now - 7 * 24 * 3600 * 1000;
    const scores = new Set<number>();
    for (const r of records) { if (r.timestamp >= weekAgo) scores.add(r.score); }
    if (scores.size >= 4) {
      const item: AchievementItem = {
        id: 'palette', title: '调色板', desc: '一周内记录 4 种以上心情',
        icon: $r('app.media.achievement_palette'), color: '#FF8BA7',
        category: 'awareness', unlocked: true, unlockedDate: todayStr(),
        progress: 4, target: 4, progressLabel: '已达成' };
      result.push(item);
    }
  }

  if (!alreadyUnlocked['decoder']) {
    for (const r of records) {
      if (r.tags && r.tags.length >= 3 && r.text.trim().length > 0) {
        const item: AchievementItem = {
          id: 'decoder', title: '情绪解码器', desc: '单条记录含 3+ 标签和文字',
          icon: $r('app.media.achievement_magnifier'), color: '#6BB6FF',
          category: 'awareness', unlocked: true, unlockedDate: todayStr(),
          progress: 1, target: 1, progressLabel: '已达成' };
        result.push(item);
        break;
      }
    }
  }

  if (!alreadyUnlocked['rainbow']) {
    for (let i = 0; i < records.length - 1; i++) {
      if (records[i].score <= -1) {
        const lowTs = records[i].timestamp;
        for (let j = i + 1; j < records.length; j++) {
          if (records[j].score >= 1 && records[j].timestamp - lowTs <= 48 * 3600 * 1000) {
            const item: AchievementItem = {
              id: 'rainbow', title: '雨过天晴', desc: '低落后 48 小时内记录开心',
              icon: $r('app.media.achievement_rainbow'), color: '#FFB86C',
              category: 'transformation', unlocked: true, unlockedDate: todayStr(),
              progress: 1, target: 1, progressLabel: '已达成' };
            result.push(item);
            i = records.length;
            break;
          }
        }
      }
    }
  }

  if (!alreadyUnlocked['calm_5']) {
    const dayMap = new Map<string, boolean>();
    for (const r of records) {
      if (r.score < 0) dayMap.set(r.dateStr, false);
      else if (!dayMap.has(r.dateStr)) dayMap.set(r.dateStr, true);
    }
    const sortedDays = Array.from(dayMap.keys()).sort();
    let calmStr = 0; let calmMax = 0;
    for (const day of sortedDays) {
      if (dayMap.get(day)) { calmStr++; if (calmStr > calmMax) calmMax = calmStr; }
      else { calmStr = 0; }
    }
    if (calmMax >= 5) {
      const item: AchievementItem = {
        id: 'calm_5', title: '波澜不惊', desc: '连续 5 天心情为平静或以上',
        icon: $r('app.media.achievement_zen'), color: '#7ED321',
        category: 'transformation', unlocked: true, unlockedDate: todayStr(),
        progress: 5, target: 5, progressLabel: '已达成' };
      result.push(item);
    }
  }

  return result;
}
