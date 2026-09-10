export interface ReminderSettings {
  isOn: boolean;
  id: number;
  hour: number;
  minute: number;
}

export function disabledReminderSettings(): ReminderSettings {
  return {
    isOn: false,
    id: -1,
    hour: 20,
    minute: 0,
  };
}

export function enabledReminderSettings(id: number, hour: number, minute: number): ReminderSettings {
  if (id <= 0) return disabledReminderSettings();
  return {
    isOn: true,
    id: id,
    hour: hour,
    minute: minute,
  };
}
