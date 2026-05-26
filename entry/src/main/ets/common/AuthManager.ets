/**
 * AuthManager — 认证与会员管理单例
 */

import dataPreferences from '@ohos.data.preferences';
import { formatDateStr } from '../model/MoodRecord';

const STORE = 'moodlite_auth';
const KEY_PROFILE = 'user_profile';
const KEY_QUOTA = 'ai_quota_';

export interface UserProfile {
  username: string;
  password: string;
  memberType: 'free' | 'pro' | 'ultra';
  createdAt: string;
}

class AuthManager {
  private static instance: AuthManager;
  private prefs: dataPreferences.Preferences | null = null;
  private profile: UserProfile | null = null;

  static getInstance(): AuthManager {
    if (!AuthManager.instance) AuthManager.instance = new AuthManager();
    return AuthManager.instance;
  }

  async init(context: Context): Promise<void> {
    if (this.prefs) return;
    this.prefs = await dataPreferences.getPreferences(context, STORE);
    const raw = await this.prefs.get(KEY_PROFILE, '') as string;
    if (raw) {
      this.profile = JSON.parse(raw) as UserProfile;
      this.syncToAppStorage();
    }
  }

  async register(username: string, password: string): Promise<boolean> {
    if (!this.prefs) return false;
    const profile: UserProfile = {
      username, password,
      memberType: 'free',
      createdAt: formatDateStr(new Date()),
    };
    await this.prefs.put(KEY_PROFILE, JSON.stringify(profile));
    await this.prefs.flush();
    this.profile = profile;
    this.syncToAppStorage();
    return true;
  }

  async login(username: string, password: string): Promise<boolean> {
    if (!this.prefs) return false;
    const raw = await this.prefs.get(KEY_PROFILE, '') as string;
    if (!raw) return false;
    const profile = JSON.parse(raw) as UserProfile;
    if (profile.username === username && profile.password === password) {
      this.profile = profile;
      this.syncToAppStorage();
      return true;
    }
    return false;
  }

  logout(): void {
    this.profile = null;
    AppStorage.set('isLoggedIn', false);
    AppStorage.set('currentUser', '');
    AppStorage.set('memberType', 'free');
  }

  getProfile(): UserProfile | null { return this.profile; }

  async upgradeMember(type: 'pro' | 'ultra'): Promise<void> {
    if (!this.profile || !this.prefs) return;
    this.profile.memberType = type;
    await this.prefs.put(KEY_PROFILE, JSON.stringify(this.profile));
    await this.prefs.flush();
    AppStorage.set('memberType', type);
  }

  async getTodayQuota(): Promise<number> {
    if (!this.prefs) return 0;
    const today = formatDateStr(new Date());
    return await this.prefs.get(KEY_QUOTA + today, 0) as number;
  }

  async consumeQuota(): Promise<boolean> {
    if (!this.profile || !this.prefs) return false;
    if (this.profile.memberType === 'ultra') return true;
    if (this.profile.memberType === 'free') return false;

    // Pro: max 3 per day
    const today = formatDateStr(new Date());
    const key = KEY_QUOTA + today;
    const used = await this.prefs.get(key, 0) as number;
    if (used >= 3) return false;
    await this.prefs.put(key, used + 1);
    await this.prefs.flush();
    return true;
  }

  isLoggedIn(): boolean { return this.profile !== null; }

  private syncToAppStorage(): void {
    if (!this.profile) return;
    AppStorage.set('isLoggedIn', true);
    AppStorage.set('currentUser', this.profile.username);
    AppStorage.set('memberType', this.profile.memberType);
  }
}

export default AuthManager.getInstance();
