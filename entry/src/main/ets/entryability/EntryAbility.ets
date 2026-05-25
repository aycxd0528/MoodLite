import UIAbility from '@ohos.app.ability.UIAbility';
import type Want from '@ohos.app.ability.Want';
import type AbilityConstant from '@ohos.app.ability.AbilityConstant';
import window from '@ohos.window';
import router from '@ohos.router';
import type { BusinessError } from '@ohos.base';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    console.info('[MoodLite] EntryAbility onCreate');
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.handleWidgetRoute(want);
  }

  onDestroy(): void {
    console.info('[MoodLite] EntryAbility onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    try {
      const mainWindow = windowStage.getMainWindowSync();
      mainWindow.setWindowLayoutFullScreen(true);
      const dk: boolean = (AppStorage.get('darkMode') as boolean) || false;
      mainWindow.setWindowBackgroundColor(dk ? '#1A1A2E' : '#F7F8FA');
      mainWindow.setWindowSystemBarProperties({
        statusBarColor: '#00000000',
        navigationBarColor: '#00000000',
        isStatusBarLightIcon: false,
      });
    } catch (err) {
      console.error('[MoodLite] Window setup failed: ' + JSON.stringify(err));
    }

    let targetPage = 'pages/Index';
    const params = this.launchWant.parameters as Record<string, Object>;
    if (params && params['targetPage']) {
      targetPage = params['targetPage'] as string;
      this.applyWidgetParams(params);
      console.info('[MoodLite] Widget card routed to: ' + targetPage);
    }

    windowStage.loadContent(targetPage, (err: BusinessError) => {
      if (err.code) {
        console.error('[MoodLite] Failed to load content: ' + JSON.stringify(err));
        return;
      }
      console.info('[MoodLite] ' + targetPage + ' loaded');
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

  private applyWidgetParams(params: Record<string, Object>): void {
    if (params['tab'] !== undefined) {
      AppStorage.setOrCreate('moodlite_tab', params['tab'] as number);
    }
  }

  private handleWidgetRoute(want: Want): void {
    try {
      const params = want.parameters as Record<string, Object>;
      if (!params || !params['targetPage']) {
        return;
      }
      this.applyWidgetParams(params);
      const target = params['targetPage'] as string;
      console.info('[MoodLite] onNewWant route to: ' + target);
      router.replaceUrl({ url: target });
    } catch (err) {
      console.error('[MoodLite] handleWidgetRoute failed: ' + JSON.stringify(err));
    }
  }
}
