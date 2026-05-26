/**
 * AuthManager — 认证与会员管理单例
 */

import dataPreferences from '@ohos.data.preferences';
import { formatDateStr } from '../model/MoodRecord';

const STORE = 'moodlite_auth';
const KEY_USERS = 'users_map';
const KEY_ACTIVE = 'active_user';
const KEY_QUOTA = 'ai_quota_';
const KEY_MEMBER = 'member_';

export interface UserProfile {
  username: string;
  password: string;
  memberType: 'free' | 'pro' | 'ultra';
  createdAt: string;
}

function hashPwd(pwd: string): string {
  const salt = 'MoodLiteSALT';
  const chars: string[] = [];
  for (let i = 0; i < pwd.length; i++) {
    chars.push(String.fromCharCode(pwd.charCodeAt(i) ^ salt.charCodeAt(i % salt.length)));
  }
  return chars.join('');
}

class AuthManager {
  private static instance: AuthManager;
  private prefs: dataPreferences.Preferences | null = null;
  private profile: UserProfile | null = null;
  private users: Record<string, UserProfile> = {};

  static getInstance(): AuthManager {
    if (!AuthManager.instance) AuthManager.instance = new AuthManager();
    return AuthManager.instance;
  }

  async init(context: Context): Promise<void> {
    if (this.prefs) return;
    this.prefs = await dataPreferences.getPreferences(context, STORE);

    const usersRaw = await this.prefs.get(KEY_USERS, '{}') as string;
    this.users = JSON.parse(usersRaw) as Record<string, UserProfile>;

    const activeUser = await this.prefs.get(KEY_ACTIVE, '') as string;
    if (activeUser && this.users[activeUser]) {
      this.profile = this.users[activeUser];
      this.loadMemberType();
      this.syncToAppStorage();
    }
  }

  async register(username: string, password: string): Promise<boolean> {
    if (!this.prefs) return false;
    if (this.users[username]) return false;

    const profile: UserProfile = {
      username,
      password: hashPwd(password),
      memberType: 'free',
      createdAt: formatDateStr(new Date()),
    };
    this.users[username] = profile;
    await this.saveUsers();
    this.profile = profile;
    await this.prefs.put(KEY_ACTIVE, username);
    await this.prefs.flush();
    this.syncToAppStorage();
    return true;
  }

  async login(username: string, password: string): Promise<boolean> {
    if (!this.prefs) return false;
    const user = this.users[username];
    if (!user) return false;
    if (user.password !== hashPwd(password)) return false;

    this.profile = user;
    this.loadMemberType();
    await this.prefs.put(KEY_ACTIVE, username);
    await this.prefs.flush();
    this.syncToAppStorage();
    return true;
  }

  logout(): void {
    this.profile = null;
    AppStorage.set('isLoggedIn', false);
    AppStorage.set('currentUser', '');
    AppStorage.set('memberType', 'free');
  }

  getProfile(): UserProfile | null { return this.profile; }

  async upgradeMember(type: string): Promise<void> {
    if (!this.profile || !this.prefs) return;
    if (type !== 'free' && type !== 'pro' && type !== 'ultra') return;
    this.profile.memberType = type;
    this.saveMemberType();
    this.users[this.profile.username] = this.profile;
    await this.saveUsers();
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
    const today = formatDateStr(new Date());
    const key = KEY_QUOTA + today;
    const used = await this.prefs.get(key, 0) as number;
    if (used >= 3) return false;
    await this.prefs.put(key, used + 1);
    await this.prefs.flush();
    return true;
  }

  isLoggedIn(): boolean { return this.profile !== null; }

  private async saveUsers(): Promise<void> {
    if (!this.prefs) return;
    await this.prefs.put(KEY_USERS, JSON.stringify(this.users));
  }

  private async saveMemberType(): Promise<void> {
    if (!this.profile || !this.prefs) return;
    await this.prefs.put(KEY_MEMBER + this.profile.username, this.profile.memberType);
  }

  private async loadMemberType(): Promise<void> {
    if (!this.profile || !this.prefs) return;
    const saved = await this.prefs.get(KEY_MEMBER + this.profile.username, 'free') as string;
    if (saved === 'pro' || saved === 'ultra' || saved === 'free') {
      this.profile.memberType = saved;
    }
  }

  private syncToAppStorage(): void {
    if (!this.profile) return;
    AppStorage.set('isLoggedIn', true);
    AppStorage.set('currentUser', this.profile.username);
    AppStorage.set('memberType', this.profile.memberType);
  }
}

export default AuthManager.getInstance();
