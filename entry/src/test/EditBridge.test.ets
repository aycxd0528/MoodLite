import { describe, it, expect } from '@ohos/hypium';
import { MoodRecord } from '../main/ets/model/MoodRecord';
import {
  clearEditPayload,
  clearRefreshHandler,
  consumeRefresh,
  getEditPayload,
  setEditPayload,
  setRefreshHandler,
  signalRefresh,
} from '../main/ets/common/EditBridge';

export default function editBridgeTest(): void {
  describe('EditBridge refresh coordination', () => {
    it('clearsOnlyTheFailedRoutePayloadAndIsolatesEdits', 0, () => {
      const source: MoodRecord = {
        id: 'first', timestamp: 100, dateStr: '2026-09-18', score: 0,
        text: 'original', images: ['local'], location: '', tags: ['休息'],
      };
      const failed = setEditPayload({ record: source });
      clearEditPayload(failed);
      expect(getEditPayload()).assertNull();

      setEditPayload({ record: source });
      clearEditPayload(failed);
      const next = getEditPayload();
      expect(next !== null).assertTrue();
      if (next !== null) {
        next.record.tags.push('工作');
        next.record.images.push('other');
      }
      expect(source.tags.length).assertEqual(1);
      expect(source.images.length).assertEqual(1);
      expect(getEditPayload()).assertNull();
    });

    it('doesNotRequestSecondPageShowRefreshAfterImmediateHandler', 0, async () => {
      let refreshCount: number = 0;
      setRefreshHandler(() => { refreshCount += 1; });

      await signalRefresh();
      const shouldReloadOnPageShow: boolean = consumeRefresh();

      expect(refreshCount).assertEqual(1);
      expect(shouldReloadOnPageShow).assertFalse();
    });

    it('keepsPageShowFallbackWhenAsyncImmediateHandlerFails', 0, async () => {
      let didThrow: boolean = false;
      setRefreshHandler(async () => {
        await Promise.resolve();
        throw new Error('refresh failed');
      });

      try {
        await signalRefresh();
      } catch (_err) {
        didThrow = true;
      }
      const shouldReloadOnPageShow: boolean = consumeRefresh();

      expect(didThrow).assertFalse();
      expect(shouldReloadOnPageShow).assertTrue();
    });

    it('doesNotLetAnOldPageUnregisterTheCurrentHandler', 0, async () => {
      let firstCount: number = 0;
      let secondCount: number = 0;
      const firstHandler = (): void => { firstCount += 1; };
      const secondHandler = (): void => { secondCount += 1; };
      setRefreshHandler(firstHandler);
      setRefreshHandler(secondHandler);

      clearRefreshHandler(firstHandler);
      await signalRefresh();
      consumeRefresh();

      expect(firstCount).assertEqual(0);
      expect(secondCount).assertEqual(1);

      clearRefreshHandler(secondHandler);
      await signalRefresh();
      expect(consumeRefresh()).assertTrue();
      expect(secondCount).assertEqual(1);
    });
  });
}
