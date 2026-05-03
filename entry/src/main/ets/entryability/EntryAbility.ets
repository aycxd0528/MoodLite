import UIAbility from '@ohos.app.ability.UIAbility';
import type Want from '@ohos.app.ability.Want';
import type AbilityConstant from '@ohos.app.ability.AbilityConstant';
import Window from '@ohos.window';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    console.info('[MoodLite] EntryAbility onCreate');
  }

  onDestroy(): void {
    console.info('[MoodLite] EntryAbility onDestroy');
  }

  onWindowStageCreate(windowStage: Window.WindowStage): void {
    windowStage.loadContent('pages/Index', (err: BusinessError) => {
      if (err.code) {
        console.error('[MoodLite] Failed to load content: ' + JSON.stringify(err));
        return;
      }
      console.info('[MoodLite] Index page loaded');
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
}
