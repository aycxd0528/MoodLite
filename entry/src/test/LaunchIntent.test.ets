import { describe, it, expect } from '@ohos/hypium';
import { LaunchIntent, LaunchParameters, parseLaunchIntent } from '../main/ets/common/LaunchIntent';

export default function launchIntentTest(): void {
  describe('LaunchIntent', () => {
    it('acceptsOnlyWhitelistedTargets', 0, () => {
      const addParams: LaunchParameters = { targetPage: 'pages/AddEntry', tab: 1 };
      const profileParams: LaunchParameters = { targetPage: 'pages/Profile' };
      const remoteParams: LaunchParameters = { targetPage: 'remote-page' };
      const addEntry: LaunchIntent = parseLaunchIntent(addParams);
      const profile: LaunchIntent = parseLaunchIntent(profileParams);
      const remote: LaunchIntent = parseLaunchIntent(remoteParams);
      expect(addEntry.targetPage).assertEqual('pages/AddEntry');
      expect(profile.targetPage).assertEqual('');
      expect(remote.targetPage).assertEqual('');
    });

    it('dropsInvalidTabValues', 0, () => {
      const invalidTab: LaunchParameters = { targetPage: 'pages/MainPage', tab: 99 };
      expect(parseLaunchIntent(invalidTab).tab).assertNull();
      expect(parseLaunchIntent(undefined).targetPage).assertEqual('');
    });
  });
}
