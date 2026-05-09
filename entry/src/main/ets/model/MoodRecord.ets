/**
 * MoodRecord —— 核心数据模型（单一事实来源）
 *
 * 所有页面统一引用此模型，严禁在页面层定义重复的数据结构。
 */

/**
 * 单条情绪记录
 */
export interface MoodRecord {
  /** UUID 主键 */
  id: string;
  /** 时间戳（毫秒），核心排序依据 */
  timestamp: number;
  /** 格式化日期 (YYYY-MM-DD)，用于日历聚合与热力图 */
  dateStr: string;
  /** 情绪净值：-2 ~ 2 整数 */
  score: number;
  /** 用户文本输入 */
  text: string;
  /** 本地沙盒图片路径占位 */
  images: string[];
  /** 结构化位置信息 */
  location: string;
  /** 标签列表，如 #工作 #社交 */
  tags: string[];
}

/**
 * 热力图单日聚合数据
 */
export interface CalendarDayItem {
  /** 日期字符串 YYYY-MM-DD */
  dateStr: string;
  /** 该日情绪平均值（保留一位小数） */
  avgScore: number;
  /** 该日记录条数 */
  count: number;
  /** 日期在月历中的星期索引 0=Sun */
  dayOfWeek: number;
  /** 是否为当月日期（用于过滤前后月填充格） */
  isCurrentMonth: boolean;
  /** 情绪简码: 0=无, 1=低落, 2=平静, 3=愉悦, 4=混合(大喜大悲) */
  moodCode: number;
}

/**
 * 月度汇总数据
 */
export interface MonthlyStats {
  /** 年份 */
  year: number;
  /** 月份 1-12 */
  month: number;
  /** 总记录天数 */
  totalDays: number;
  /** 愉悦天数 (score >= 1) */
  happyDays: number;
  /** 平静天数 (score = 0) */
  neutralDays: number;
  /** 低落天数 (score <= -1) */
  sadDays: number;
  /** 月度平均分 */
  averageScore: number;
  /** 情绪最高分 */
  maxScore: number;
  /** 情绪最低分 */
  minScore: number;
}

/**
 * 情绪分映射工具函数
 */
export function getMoodLabel(score: number): string {
  if (score >= 1) return '愉悦';
  if (score <= -1) return '低落';
  return '平静';
}

export function getMoodEmoji(score: number): string {
  if (score >= 2) return '😄';
  if (score === 1) return '🙂';
  if (score === 0) return '😐';
  if (score === -1) return '😔';
  return '😢';
}

export function getMoodIconResource(score: number): Resource {
  if (score <= -2) return $r('app.media.ic_face_terrible');
  if (score === -1) return $r('app.media.ic_face_bad');
  if (score === 0) return $r('app.media.ic_face_neutral');
  if (score === 1) return $r('app.media.ic_face_good');
  return $r('app.media.ic_face_awesome');
}

export function getMoodColor(score: number): string {
  if (score >= 1) return '#FF8BA7';
  if (score <= -1) return '#AEC6CF';
  return '#9CA3AF';
}

/**
 * UUID 生成器（毫秒时间戳 + 6 位随机字符）
 */
export function generateUUID(): string {
  return Date.now().toString() + '_' + Math.random().toString(36).slice(2, 10);
}

/**
 * Mock 数据生成（Phase 1 占位使用）
 */
export function createMockRecord(
  overrides: Record<string, number | string | string[]>
): MoodRecord {
  const now = Date.now();
  const record: MoodRecord = {
    id: generateUUID(),
    timestamp: now,
    dateStr: formatDateStr(new Date(now)),
    score: 0,
    text: '',
    images: [],
    location: '',
    tags: [],
  };

  if (overrides) {
    if (overrides.id !== undefined) record.id = overrides.id as string;
    if (overrides.timestamp !== undefined) record.timestamp = overrides.timestamp as number;
    if (overrides.dateStr !== undefined) record.dateStr = overrides.dateStr as string;
    if (overrides.score !== undefined) record.score = overrides.score as number;
    if (overrides.text !== undefined) record.text = overrides.text as string;
    if (overrides.images !== undefined) record.images = overrides.images as string[];
    if (overrides.location !== undefined) record.location = overrides.location as string;
    if (overrides.tags !== undefined) record.tags = overrides.tags as string[];
  }

  return record;
}

/** 快捷标签池 */
export const DEFAULT_TAGS: string[] = ['工作', '社交', '独处', '运动', '休息', '阅读'];

/**
 * 将 Date 格式化为 YYYY-MM-DD
 */
export function formatDateStr(date: Date): string {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  return y + '-' + m + '-' + d;
}
