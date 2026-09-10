import { describe, it, expect } from '@ohos/hypium';
import { buildEditedMoodRecord, parseMoodRecords } from '../main/ets/model/MoodRecordPolicy';
import { MoodRecord } from '../main/ets/model/MoodRecord';

export default function moodRecordPolicyTest(): void {
  describe('MoodRecordPolicy', () => {
    it('normalizesLegacyRecordsAndSortsNewestFirst', 0, () => {
      const raw: string = '[{"id":"old","timestamp":100,"dateStr":"2026-09-01","score":8,"text":"a"},' +
        '{"id":"","timestamp":200,"dateStr":"2026-09-02","score":0,"text":"bad"},' +
        '{"id":"new","timestamp":300,"dateStr":"2026-09-03","score":1.6,"text":"b","tags":["工作"]}]';
      const records: MoodRecord[] = parseMoodRecords(raw);
      expect(records.length).assertEqual(2);
      expect(records[0].id).assertEqual('new');
      expect(records[0].score).assertEqual(2);
      expect(records[0].images.length).assertEqual(0);
      expect(records[0].location).assertEqual('');
      expect(records[1].score).assertEqual(2);
    });

    it('returnsEmptyListForMalformedJson', 0, () => {
      expect(parseMoodRecords('{broken').length).assertEqual(0);
    });

    it('rejectsImpossibleCalendarDates', 0, () => {
      const raw: string = '[{"id":"bad-date","timestamp":100,"dateStr":"2026-02-30",' +
        '"score":0,"text":""}]';
      expect(parseMoodRecords(raw).length).assertEqual(0);
    });

    it('preservesIdentityAndCompatibilityFieldsWhenEditing', 0, () => {
      const original: MoodRecord = {
        id: 'r1', timestamp: 123, dateStr: '2026-08-03', score: -1,
        text: 'old', tags: ['旧'], images: ['sandbox://legacy'], location: 'legacy',
      };
      const edited: MoodRecord = buildEditedMoodRecord(original, 2, 'new', ['新']);
      expect(edited.id).assertEqual('r1');
      expect(edited.timestamp).assertEqual(123);
      expect(edited.dateStr).assertEqual('2026-08-03');
      expect(edited.images[0]).assertEqual('sandbox://legacy');
      expect(edited.location).assertEqual('legacy');
      expect(edited.score).assertEqual(2);
      expect(edited.text).assertEqual('new');
    });
  });
}
