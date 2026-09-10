export interface LaunchIntent {
  targetPage: string;
  tab: number | null;
}

export interface LaunchParameters {
  targetPage?: Object;
  tab?: Object;
}

export const PENDING_TARGET_KEY: string = 'moodlite_pending_target';
export const PENDING_TAB_KEY: string = 'moodlite_pending_tab';

const MAIN_PAGE: string = 'pages/MainPage';
const ADD_ENTRY_PAGE: string = 'pages/AddEntry';

function allowedTab(value: Object | undefined): number | null {
  if (typeof value !== 'number') return null;
  return value === 0 || value === 1 || value === 3 || value === 4 ? value : null;
}

export function parseLaunchIntent(params: LaunchParameters | undefined): LaunchIntent {
  if (!params) return { targetPage: '', tab: null };
  const rawTarget: Object | undefined = params.targetPage;
  const targetPage: string = rawTarget === MAIN_PAGE || rawTarget === ADD_ENTRY_PAGE
    ? rawTarget as string
    : '';
  return {
    targetPage: targetPage,
    tab: allowedTab(params.tab),
  };
}
