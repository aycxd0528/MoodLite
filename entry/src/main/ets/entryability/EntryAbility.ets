import UIAbility from '@ohos.app.ability.UIAbility';
import type Want from '@ohos.app.ability.Want';
import type AbilityConstant from '@ohos.app.ability.AbilityConstant';
import window from '@ohos.window';
import type { BusinessError } from '@ohos.base';
import DataManager from '../data/DataManager';
import {
  LaunchIntent,
  LaunchParameters,
  PENDING_TAB_KEY,
  PENDING_TARGET_KEY,
  parseLaunchIntent,
} from '../common/LaunchIntent';
import { systemBarProperties } from '../common/SystemBarManager';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    console.info('[MoodLite] EntryAbility onCreate');
    this.storeLaunchIntent(want, true);
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.handleLaunchIntent(want);
  }

  onDestroy(): void {
    console.info('[MoodLite] EntryAbility onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    try {
      const mainWindow = windowStage.getMainWindowSync();
      mainWindow.setWindowLayoutFullScreen(true).catch((err: Error) => {
        console.error('[MoodLite] Full-screen setup failed: ' + JSON.stringify(err));
      });
      mainWindow.setWindowSystemBarProperties(systemBarProperties(false)).catch((err: Error) => {
        console.error('[MoodLite] System bar setup failed: ' + JSON.stringify(err));
      });
    } catch (err) {
      console.error('[MoodLite] Window setup failed: ' + JSON.stringify(err));
    }

    // 所有冷启动先经过 Index，确保本地数据初始化完成后再处理卡片路由。
    windowStage.loadContent('pages/Index', (err: BusinessError) => {
      if (err.code) {
        console.error('[MoodLite] Failed to load content: ' + JSON.stringify(err));
        return;
      }
      console.info('[MoodLite] pages/Index loaded');
    });
  }

  onWindowStageDestroy(): void {
    console.info('[MoodLite] EntryAbility onWindowStageDestroy');
  }

  onForeground(): void {
    console.info('[MoodLite] EntryAbility onForeground');
  }

  onBackground(): void {
    console.info('[MoodLite] EntryAbility onBackground');
  }

  private clearPendingIntent(): void {
    AppStorage.delete(PENDING_TARGET_KEY);
    AppStorage.delete(PENDING_TAB_KEY);
  }

  private storeIntent(intent: LaunchIntent): void {
    AppStorage.setOrCreate(PENDING_TARGET_KEY, intent.targetPage);
    if (intent.tab === null) {
      AppStorage.delete(PENDING_TAB_KEY);
    } else {
      AppStorage.setOrCreate(PENDING_TAB_KEY, intent.tab);
    }
  }

  private storeLaunchIntent(want: Want, clearInvalid: boolean): void {
    const intent: LaunchIntent = parseLaunchIntent(want.parameters as LaunchParameters | undefined);
    if (intent.targetPage.length === 0) {
      if (clearInvalid) this.clearPendingIntent();
      return;
    }
    this.storeIntent(intent);
  }

  private navigate(intent: LaunchIntent): void {
    window.getLastWindow(this.context).then((mainWindow: window.Window) => {
      try {
        const uiRouter = mainWindow.getUIContext().getRouter();
        if (intent.targetPage === 'pages/MainPage') {
          if (intent.tab !== null) {
            AppStorage.setOrCreate('moodlite_tab', intent.tab);
          }
          uiRouter.replaceUrl({ url: 'pages/MainPage' }).catch((err: Error) => {
            console.error('[MoodLite] MainPage route failed: ' + JSON.stringify(err));
          });
          return;
        }
        uiRouter.replaceUrl({
          url: 'pages/AddEntry',
          params: { fromTab: intent.tab === null ? 0 : intent.tab },
        }).catch((err: Error) => {
          console.error('[MoodLite] AddEntry route failed: ' + JSON.stringify(err));
        });
      } catch (err) {
        console.error('[MoodLite] Route setup failed: ' + JSON.stringify(err));
      }
    }).catch((err: Error) => {
      console.error('[MoodLite] Main window unavailable for route: ' + JSON.stringify(err));
    });
  }

  private handleLaunchIntent(want: Want): void {
    try {
      const intent: LaunchIntent = parseLaunchIntent(want.parameters as LaunchParameters | undefined);
      if (intent.targetPage.length === 0) {
        console.warn('[MoodLite] Ignoring invalid launch target');
        return;
      }
      if (!DataManager.isReady()) {
        this.storeIntent(intent);
        console.info('[MoodLite] Launch intent queued until local data is ready');
        return;
      }
      this.clearPendingIntent();
      console.info('[MoodLite] onNewWant route to: ' + intent.targetPage);
      this.navigate(intent);
    } catch (err) {
      console.error('[MoodLite] handleLaunchIntent failed: ' + JSON.stringify(err));
    }
  }
}
