/**
 * ReminderManager — 每日提醒管理（基于系统代理提醒 API）
 *
 * 使用 @ohos.reminderAgentManager 的 ReminderRequestAlarm 实现每日定时提醒。
 * Alarm 类型在设备休眠后仍能唤醒系统触发通知，Timer 会被挂起。
 */

import reminderAgentManager from '@ohos.reminderAgentManager';

/** 开启每日提醒 */
export function enableDailyReminder(ctx: Context, hour: number, minute: number): Promise<boolean> {
  return new Promise<boolean>((resolve) => {
    const oldId: number = AppStorage.get('mood_reminder_id') as number;
    if (oldId > 0) {
      reminderAgentManager.cancelReminder(oldId, (_err: Error) => {
      });
      AppStorage.set('mood_reminder_id', -1);
    }

    const alarm: reminderAgentManager.ReminderRequestAlarm = {
      reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_ALARM,
      hour: hour,
      minute: minute,
      daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
      title: 'MoodLite 提醒',
      content: '记录今天的心情吧',
      actionButton: [{
        title: '去记录',
        type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_CLOSE,
      }],
      ringDuration: 5,
      snoozeTimes: 1,
      timeInterval: 5,
    };

    reminderAgentManager.publishReminder(alarm, (err: Error, reminderId: number) => {
      if (err) {
        console.error('[MoodLite] publishReminder 失败: ' + JSON.stringify(err));
        AppStorage.set('isReminderOn', false);
        resolve(false);
        return;
      }
      console.info('[MoodLite] 提醒已发布，id=' + reminderId);
      AppStorage.set('mood_reminder_id', reminderId);
      AppStorage.set('isReminderOn', true);
      AppStorage.set('reminderHour', hour);
      AppStorage.set('reminderMinute', minute);
      resolve(true);
    });
  });
}

/** 取消已发布的每日提醒 */
export function cancelReminder(): void {
  const reminderId: number = AppStorage.get('mood_reminder_id') as number;
  if (reminderId > 0) {
    reminderAgentManager.cancelReminder(reminderId, (err: Error) => {
      if (err) {
        console.error('[MoodLite] cancelReminder 失败: ' + JSON.stringify(err));
        return;
      }
      console.info('[MoodLite] 提醒已取消，id=' + reminderId);
    });
    AppStorage.set('mood_reminder_id', -1);
  }
  AppStorage.set('isReminderOn', false);
}
