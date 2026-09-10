import { describe, it, expect } from '@ohos/hypium';
import { recordsForMonth, calcMonthlyStats, calcTagDistribution } from '../main/ets/viewmodel/StatsViewModel';
import { MoodRecord } from '../main/ets/model/MoodRecord';

function record(id: string, dateStr: string, score: number, tags: string[]): MoodRecord {
  return { id: id, dateStr: dateStr, score: score, tags: tags, timestamp: 1, text: '', images: [], location: '' };
}

export default function statsViewModelTest(): void {
  describe('StatsViewModel month scope', () => {
    it('keepsTagsInsideSelectedMonthAndCountsUniqueDays', 0, () => {
      const all: MoodRecord[] = [
        record('a', '2026-09-01', 2, ['九月']),
        record('b', '2026-09-01', -1, ['同日']),
        record('c', '2026-08-31', 1, ['八月']),
      ];
      const september: MoodRecord[] = recordsForMonth(all, 2026, 9);
      const stats = calcMonthlyStats(2026, 9, september);
      const tags = calcTagDistribution(september);
      expect(september.length).assertEqual(2);
      expect(stats.totalDays).assertEqual(1);
      expect(tags.some(item => item.tag === '八月')).assertFalse();
    });
  });
}
