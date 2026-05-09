/**
 * Achievement — 成就徽章数据模型
 */

export interface AchievementItem {
  id: string;
  title: string;
  desc: string;
  icon: Resource;
  color: string;
  category: 'habit' | 'awareness' | 'transformation';
  unlocked: boolean;
  unlockedDate: string;
  progress: number;
  target: number;
  progressLabel: string;
}

export const ACHIEVEMENTS: AchievementItem[] = [
  {
    id: 'first_record', title: '初识自我', desc: '首次记录心情',
    icon: $r('app.media.achievement_seed'), color: '#6BB6FF',
    category: 'habit', unlocked: false, unlockedDate: '',
    progress: 0, target: 1, progressLabel: '已记录 0/1 次',
  },
  {
    id: 'streak_7', title: '拾级而上', desc: '连续记录 7 天',
    icon: $r('app.media.achievement_steps'), color: '#7ED321',
    category: 'habit', unlocked: false, unlockedDate: '',
    progress: 0, target: 7, progressLabel: '连续 0/7 天',
  },
  {
    id: 'total_30', title: '岁月痕迹', desc: '累计记录满 30 篇',
    icon: $r('app.media.achievement_hourglass'), color: '#FFB86C',
    category: 'habit', unlocked: false, unlockedDate: '',
    progress: 0, target: 30, progressLabel: '累计 0/30 篇',
  },
  {
    id: 'palette', title: '调色板', desc: '一周内记录 4 种以上心情',
    icon: $r('app.media.achievement_palette'), color: '#FF8BA7',
    category: 'awareness', unlocked: false, unlockedDate: '',
    progress: 0, target: 4, progressLabel: '0/4 种心情',
  },
  {
    id: 'decoder', title: '情绪解码器', desc: '单条记录含 3+ 标签和文字',
    icon: $r('app.media.achievement_magnifier'), color: '#6BB6FF',
    category: 'awareness', unlocked: false, unlockedDate: '',
    progress: 0, target: 1, progressLabel: '未达成',
  },
  {
    id: 'rainbow', title: '雨过天晴', desc: '低落后 48 小时内记录开心',
    icon: $r('app.media.achievement_rainbow'), color: '#FFB86C',
    category: 'transformation', unlocked: false, unlockedDate: '',
    progress: 0, target: 1, progressLabel: '未达成',
  },
  {
    id: 'calm_5', title: '波澜不惊', desc: '连续 5 天心情为平静或以上',
    icon: $r('app.media.achievement_zen'), color: '#7ED321',
    category: 'transformation', unlocked: false, unlockedDate: '',
    progress: 0, target: 5, progressLabel: '连续 0/5 天',
  },
];
