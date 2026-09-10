import { describe, it, expect } from '@ohos/hypium';
import { buildWidgetSummary, WidgetSummary } from '../main/ets/viewmodel/WidgetViewModel';
import { MoodRecord } from '../main/ets/model/MoodRecord';

export default function widgetViewModelTest(): void {
  describe('WidgetViewModel', () => {
    it('countsTwoRecordsOnOneDayAsOneRecordDay', 0, () => {
      const records: MoodRecord[] = [
        { id: 'a', timestamp: 2, dateStr: '2026-09-02', score: 2, text: '', tags: [], images: [], location: '' },
        { id: 'b', timestamp: 1, dateStr: '2026-09-02', score: -1, text: '', tags: [], images: [], location: '' },
      ];
      const summary: WidgetSummary = buildWidgetSummary(records, new Date(2026, 8, 2), false);
      expect(summary.recordDays).assertEqual(1);
      expect(summary.happyPercent).assertEqual(50);
      expect(summary.sadPercent).assertEqual(50);
    });
  });
}
