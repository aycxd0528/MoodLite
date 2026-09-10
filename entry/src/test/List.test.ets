import localUnitTest from './LocalUnit.test';
import moodRecordPolicyTest from './MoodRecordPolicy.test';

export default function testsuite() {
  localUnitTest();
  moodRecordPolicyTest();
}
