import moodRecordPolicyTest from './MoodRecordPolicy.test';
import statsViewModelTest from './StatsViewModel.test';
import widgetViewModelTest from './WidgetViewModel.test';
import launchIntentTest from './LaunchIntent.test';
import reminderStateTest from './ReminderState.test';

export default function testsuite() {
  moodRecordPolicyTest();
  statsViewModelTest();
  widgetViewModelTest();
  launchIntentTest();
  reminderStateTest();
}
