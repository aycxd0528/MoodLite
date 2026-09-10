import localUnitTest from './LocalUnit.test';
import moodRecordPolicyTest from './MoodRecordPolicy.test';
import statsViewModelTest from './StatsViewModel.test';
import widgetViewModelTest from './WidgetViewModel.test';

export default function testsuite() {
  localUnitTest();
  moodRecordPolicyTest();
  statsViewModelTest();
  widgetViewModelTest();
}
