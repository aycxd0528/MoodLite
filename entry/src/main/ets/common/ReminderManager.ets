/**
 * ReminderManager — 提醒状态管理（暂存本地，系统接入待后续版本）
 */

/** 开启提醒（仅持久化开关与时间） */
export function enableDailyReminder(_ctx: Context, hour: number, minute: number): void {
  AppStorage.set('isReminderOn', true);
  AppStorage.set('reminderHour', hour);
  AppStorage.set('reminderMinute', minute);
}

/** 取消提醒 */
export function cancelReminder(): void {
  AppStorage.set('isReminderOn', false);
}
