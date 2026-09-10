import { describe, it, expect } from '@ohos/hypium';
import {
  ReminderSettings,
  disabledReminderSettings,
  enabledReminderSettings,
} from '../main/ets/common/ReminderState';

export default function reminderStateTest(): void {
  describe('ReminderState', () => {
    it('enablesOnlyWithPositivePublishedId', 0, () => {
      expect(enabledReminderSettings(-1, 20, 0).isOn).assertFalse();
      const enabled: ReminderSettings = enabledReminderSettings(42, 9, 30);
      expect(enabled.isOn).assertTrue();
      expect(enabled.id).assertEqual(42);
      expect(enabled.hour).assertEqual(9);
      expect(enabled.minute).assertEqual(30);
    });

    it('disablesWithClearedId', 0, () => {
      const disabled: ReminderSettings = disabledReminderSettings();
      expect(disabled.isOn).assertFalse();
      expect(disabled.id).assertEqual(-1);
    });
  });
}
