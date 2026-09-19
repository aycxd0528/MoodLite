/**
 * ReminderManager — 每日提醒管理（基于系统代理提醒 API）
 *
 * 使用 @ohos.reminderAgentManager 的 ReminderRequestAlarm 实现每日定时提醒。
 * Alarm 类型在设备休眠后仍能唤醒系统触发通知，Timer 会被挂起。
 */

import reminderAgentManager from '@ohos.reminderAgentManager';
import notificationManager from '@ohos.notificationManager';
import common from '@ohos.app.ability.common';

/** 发布每日提醒。仅返回系统结果，不读写界面或持久状态。 */
export async function publishDailyReminder(ctx: Context, hour: number, minute: number): Promise<number> {
  try {
    if (!await notificationManager.isNotificationEnabled()) {
      await notificationManager.requestEnableNotification(ctx as common.UIAbilityContext);
    }
    if (!await notificationManager.isNotificationEnabled()) return -1;
  } catch (err) {
    console.error('[MoodLite] notification permission unavailable: ' + JSON.stringify(err));
    return -1;
  }
  return new Promise<number>((resolve) => {
    const alarm: reminderAgentManager.ReminderRequestAlarm = {
      reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_ALARM,
      hour: hour,
      minute: minute,
      daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
      title: 'MoodLite 提醒',
      content: '点击通知，记录今天的心情吧',
      wantAgent: {
        pkgName: 'com.aycxd.moodlite',
        abilityName: 'EntryAbility',
        parameters: { targetPage: 'pages/MainPage' },
      },
      actionButton: [{
        title: '关闭',
        type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_CLOSE,
      }],
      ringDuration: 5,
      snoozeTimes: 0,
      timeInterval: 0,
    };

    try {
      reminderAgentManager.publishReminder(alarm, (err: Error, reminderId: number) => {
        if (err || reminderId <= 0) {
          console.error('[MoodLite] publishReminder 失败: ' + JSON.stringify(err));
          resolve(-1);
          return;
        }
        console.info('[MoodLite] 提醒已发布，id=' + reminderId);
        resolve(reminderId);
      });
    } catch (err) {
      console.error('[MoodLite] publishReminder 异常: ' + JSON.stringify(err));
      resolve(-1);
    }
  });
}

/** 取消指定提醒。无有效 ID 等同于已取消。 */
export function cancelDailyReminder(reminderId: number): Promise<boolean> {
  if (reminderId <= 0) return Promise.resolve(true);
  return new Promise<boolean>((resolve) => {
    try {
      reminderAgentManager.cancelReminder(reminderId, (err: Error) => {
        if (err) {
          console.error('[MoodLite] cancelReminder 失败: ' + JSON.stringify(err));
          resolve(false);
          return;
        }
        console.info('[MoodLite] 提醒已取消，id=' + reminderId);
        resolve(true);
      });
    } catch (err) {
      console.error('[MoodLite] cancelReminder 异常: ' + JSON.stringify(err));
      resolve(false);
    }
  });
}
