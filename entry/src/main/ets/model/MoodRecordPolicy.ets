import { MoodRecord } from './MoodRecord';

interface RawMoodRecord {
  id?: Object;
  timestamp?: Object;
  dateStr?: Object;
  score?: Object;
  text?: Object;
  images?: Object;
  location?: Object;
  tags?: Object;
}

function isValidDateStr(dateStr: string): boolean {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(dateStr)) return false;
  const parts: string[] = dateStr.split('-');
  const year: number = Number(parts[0]);
  const month: number = Number(parts[1]);
  const day: number = Number(parts[2]);
  const date = new Date(year, month - 1, day);
  return date.getFullYear() === year &&
    date.getMonth() === month - 1 &&
    date.getDate() === day;
}

function normalizedScore(value: Object | undefined): number | null {
  let score: number;
  if (typeof value === 'number') {
    score = value;
  } else if (typeof value === 'string' && value.trim().length > 0) {
    score = Number(value);
  } else {
    return null;
  }
  if (!Number.isFinite(score)) return null;
  return Math.max(-2, Math.min(2, Math.round(score)));
}

function stringArray(value: Object | undefined): string[] {
  if (!Array.isArray(value)) return [];
  const result: string[] = [];
  for (const item of value as Object[]) {
    if (typeof item === 'string') result.push(item);
  }
  return result;
}

export function normalizeMoodRecord(value: Object | null | undefined): MoodRecord | null {
  if (value === null || typeof value !== 'object' || Array.isArray(value)) return null;
  const raw = value as RawMoodRecord;
  if (typeof raw.id !== 'string' || raw.id.trim().length === 0) return null;
  if (typeof raw.timestamp !== 'number' || !Number.isFinite(raw.timestamp) || raw.timestamp <= 0) return null;
  if (typeof raw.dateStr !== 'string' || !isValidDateStr(raw.dateStr)) return null;
  const score: number | null = normalizedScore(raw.score);
  if (score === null) return null;

  return {
    id: raw.id,
    timestamp: raw.timestamp,
    dateStr: raw.dateStr,
    score: score,
    text: typeof raw.text === 'string' ? raw.text : '',
    images: stringArray(raw.images),
    location: typeof raw.location === 'string' ? raw.location : '',
    tags: stringArray(raw.tags),
  };
}

export function parseMoodRecords(raw: string): MoodRecord[] {
  try {
    const parsed: Object = JSON.parse(raw) as Object;
    if (!Array.isArray(parsed)) return [];
    const records: MoodRecord[] = [];
    for (const value of parsed as Object[]) {
      const record: MoodRecord | null = normalizeMoodRecord(value);
      if (record !== null) records.push(record);
    }
    records.sort((a: MoodRecord, b: MoodRecord): number => b.timestamp - a.timestamp);
    return records;
  } catch (_err) {
    return [];
  }
}

export function buildEditedMoodRecord(
  original: MoodRecord,
  score: number,
  text: string,
  tags: string[],
): MoodRecord {
  const nextScore: number = Number.isFinite(score)
    ? Math.max(-2, Math.min(2, Math.round(score)))
    : original.score;
  return {
    id: original.id,
    timestamp: original.timestamp,
    dateStr: original.dateStr,
    score: nextScore,
    text: text,
    images: [...original.images],
    location: original.location,
    tags: [...tags],
  };
}
