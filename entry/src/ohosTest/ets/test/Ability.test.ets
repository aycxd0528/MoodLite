import { describe, it, expect } from '@ohos/hypium';
import {
  LaunchIntent,
  LaunchParameters,
  parseLaunchIntent,
} from '../../../main/ets/common/LaunchIntent';

export default function abilityTest(): void {
  describe('LaunchRouteSafety', () => {
    it('rejectsNonWhitelistedDeviceRoute', 0, () => {
      const params: LaunchParameters = { targetPage: 'pages/Profile' };
      const intent: LaunchIntent = parseLaunchIntent(params);
      expect(intent.targetPage).assertEqual('');
    });
  });
}
