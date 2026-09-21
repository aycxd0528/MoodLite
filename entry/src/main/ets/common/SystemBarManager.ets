import window from '@ohos.window';

export function systemBarProperties(darkMode: boolean): window.SystemBarProperties {
  const contentColor: string = darkMode ? '#FFFFFF' : '#1F2937';
  return {
    statusBarColor: '#00000000',
    navigationBarColor: '#00000000',
    statusBarContentColor: contentColor,
    navigationBarContentColor: contentColor,
    enableStatusBarAnimation: true,
  };
}

export function syncSystemBars(context: Context | undefined, darkMode: boolean): void {
  if (!context) return;
  window.getLastWindow(context).then((mainWindow: window.Window) => {
    mainWindow.setWindowSystemBarProperties(systemBarProperties(darkMode)).catch((err: Error) => {
      console.error('[MoodLite] System bar update failed: ' + JSON.stringify(err));
    });
  }).catch((err: Error) => {
    console.error('[MoodLite] Main window unavailable for system bar update: ' + JSON.stringify(err));
  });
}
