/**
 * DataManager —— 本地持久化单例（Preferences 存储）
 *
 * 职责：
 * - 情绪记录的 CRUD 操作
 * - 首次启动状态管理
 * - 所有写入自动触发 flush 落盘
 */

import dataPreferences from '@ohos.data.preferences';
import { MoodRecord } from '../model/MoodRecord';
import WidgetSyncManager from '../common/utils/WidgetSyncManager';
import { checkNewAchievements } from '../viewmodel/AchievementChecker';
import { AchievementItem } from '../model/Achievement';

const STORE_NAME = 'moodlite_db';
const KEY_RECORDS = 'records';
const KEY_FIRST_LAUNCH = 'first_launch';
const KEY_ACHIEVEMENTS = 'unlocked_achievements';
const KEY_PENDING = 'pending_achievements';

class DataManager {
  private static instance: DataManager;
  private preferences: dataPreferences.Preferences | null = null;
  private context: Context | null = null;
  private writeQueue: Promise<void> = Promise.resolve();
  private initPromise: Promise<void> | null = null;
  private ready: boolean = false;
  private unlockedAchievements: Record<string, string> = {};
  private cache: MoodRecord[] = [];

  static getInstance(): DataManager {
    if (!DataManager.instance) {
      DataManager.instance = new DataManager();
    }
    return DataManager.instance;
  }

  /**
   * 初始化（防重复 — 并发调用共享同一 Promise）
   * 应在 Index.ets 的 aboutToAppear 中调用。
   */
  async init(context: Context): Promise<void> {
    if (this.ready) {
      console.info('[MoodLite] DataManager already initialized');
      return;
    }
    if (this.initPromise) {
      console.info('[MoodLite] Init in progress — awaiting existing promise');
      return this.initPromise;
    }
    console.info('[MoodLite] DataManager init starting...');
    this.context = context;
    this.initPromise = this.doInit();
    try {
      await this.initPromise;
    } finally {
      this.initPromise = null;
    }
  }

  private async doInit(): Promise<void> {
    try {
      this.preferences = await dataPreferences.getPreferences(this.context!, STORE_NAME);
      const raw = await this.preferences.get(KEY_ACHIEVEMENTS, '{}') as string;
      this.unlockedAchievements = JSON.parse(raw) as Record<string, string>;

      // 预热内存缓存
      const recordsRaw = await this.preferences.get(KEY_RECORDS, '[]') as string;
      this.cache = JSON.parse(recordsRaw) as MoodRecord[];

      this.syncAchievementsToUI();
      this.ready = true;
      console.info('[MoodLite] DataManager init complete — ' + this.cache.length + ' records cached');
    } catch (err) {
      this.ready = false;
      const msg = '[MoodLite] Preferences init failed: ' + JSON.stringify(err);
      console.error(msg);
      throw new Error(msg);
    }
  }

  getUnlockedAchievements(): Record<string, string> {
    return this.unlockedAchievements;
  }

  syncAchievementsToUI(): void {
    const list: Record<string, string>[] = [];
    const keys = Object.keys(this.unlockedAchievements);
    for (const k of keys) {
      const item: Record<string, string> = {};
      item['id'] = k;
      item['date'] = this.unlockedAchievements[k];
      list.push(item);
    }
    AppStorage.set('achievements', JSON.stringify(list));
  }

  /** 阻塞直到 DataManager 完全就绪（搭配超时使用） */
  async ensureInitialized(): Promise<boolean> {
    if (this.ready) return true;
    if (this.initPromise) {
      try {
        await this.initPromise;
        return this.ready;
      } catch (_err) {
        return false;
      }
    }
    return this.ready;
  }

  /** 供 Index 页查询当前就绪状态 */
  isReady(): boolean { return this.ready; }

  // ========== 记录 CRUD ==========

  /** 读取全部记录（按时间戳倒序，直接从内存缓存返回） */
  async getAllRecords(): Promise<MoodRecord[]> {
    if (!this.preferences) {
      console.warn('[MoodLite] getAllRecords — DataManager not initialized, returning []');
      return [];
    }
    return [...this.cache];
  }

  /** 按 ID 获取单条记录 */
  async getRecordById(id: string): Promise<MoodRecord | null> {
    const found = this.cache.find(r => r.id === id);
    return found || null;
  }

  /** 获取指定日期范围内的记录（含两端，dateStr YYYY-MM-DD 格式） */
  async getRecordsInRange(startDate: string, endDate: string): Promise<MoodRecord[]> {
    return this.cache.filter(r => r.dateStr >= startDate && r.dateStr <= endDate);
  }

  /** 获取指定月份的记录 */
  async getRecordsByMonth(year: number, month: number): Promise<MoodRecord[]> {
    const prefix: string = year + '-' + String(month).padStart(2, '0');
    return this.cache.filter(r => r.dateStr.startsWith(prefix));
  }

  /** 保存/更新记录：同 ID 则删除旧记录后插入头部（串行化防竞态） */
  async saveRecord(record: MoodRecord): Promise<boolean> {
    return this.enqueue(async () => {
      if (!this.preferences) return false;
      const raw = await this.preferences.get(KEY_RECORDS, '[]') as string;
      const records: MoodRecord[] = JSON.parse(raw);
      const filtered = records.filter(r => r.id !== record.id);
      filtered.unshift(record);

      // 成就结算（纯内存操作，先于落盘完成，保证记录+成就+待展示队列一起 flush）
      const newAchievements = checkNewAchievements(filtered, this.unlockedAchievements);
      if (newAchievements.length > 0) {
        for (const a of newAchievements) {
          this.unlockedAchievements[a.id] = a.unlockedDate;
        }
        await this.preferences.put(KEY_ACHIEVEMENTS, JSON.stringify(this.unlockedAchievements));

        const pendingRaw = await this.preferences.get(KEY_PENDING, '[]') as string;
        const pendingIds: string[] = JSON.parse(pendingRaw);
        for (const a of newAchievements) {
          if (!pendingIds.includes(a.id)) {
            pendingIds.push(a.id);
          }
        }
        await this.preferences.put(KEY_PENDING, JSON.stringify(pendingIds));
      }

      // 唯一一次落盘：记录 + 成就 + 待展示队列原子写入
      await this.preferences.put(KEY_RECORDS, JSON.stringify(filtered));
      await this.preferences.flush();

      // 落盘成功，更新内存缓存
      this.cache = filtered;

      // 数据已安全落盘，异步通知（非阻塞）
      if (this.context) {
        WidgetSyncManager.updateWidgets(this.context, filtered).catch((e: Error) => {
          console.error('[MoodLite] WidgetSync failed (non-blocking): ' + JSON.stringify(e));
        });
      }
      if (newAchievements.length > 0) {
        this.notifyAchievements(filtered);
      }
      return true;
    });
  }

  /** 删除单条记录（串行化防竞态） */
  async deleteRecord(id: string): Promise<boolean> {
    return this.enqueue(async () => {
      if (!this.preferences) return false;
      const raw = await this.preferences.get(KEY_RECORDS, '[]') as string;
      const records: MoodRecord[] = JSON.parse(raw);
      const filtered = records.filter(r => r.id !== id);
      await this.preferences.put(KEY_RECORDS, JSON.stringify(filtered));
      await this.preferences.flush();

      // 落盘成功，更新内存缓存
      this.cache = filtered;

      if (this.context) {
        WidgetSyncManager.updateWidgets(this.context, filtered).catch((e: Error) => {
          console.error('[MoodLite] WidgetSync failed (non-blocking): ' + JSON.stringify(e));
        });
      }
      return true;
    });
  }

  /** 将写操作串行入队，避免并发读写覆盖 */
  private enqueue(fn: () => Promise<boolean>): Promise<boolean> {
    return new Promise<boolean>((resolve) => {
      this.writeQueue = this.writeQueue.then(async () => {
        try {
          resolve(await fn());
        } catch (err) {
          console.error('[MoodLite] write op failed: ' + JSON.stringify(err));
          resolve(false);
        }
      });
    });
  }

  // ========== 待展示成就队列 ==========

  /** 获取尚未向用户展示的成就 ID 列表 */
  async getPendingAchievementIds(): Promise<string[]> {
    if (!this.preferences) return [];
    try {
      const raw = await this.preferences.get(KEY_PENDING, '[]') as string;
      return JSON.parse(raw) as string[];
    } catch (err) {
      return [];
    }
  }

  /** 是否有待展示成就 */
  async hasPendingAchievements(): Promise<boolean> {
    const ids: string[] = await this.getPendingAchievementIds();
    return ids.length > 0;
  }

  /** 标记成就已向用户展示（从队列移除） */
  async markPendingAsSeen(id: string): Promise<void> {
    if (!this.preferences) return;
    try {
      const raw = await this.preferences.get(KEY_PENDING, '[]') as string;
      const ids: string[] = JSON.parse(raw);
      const filtered = ids.filter(i => i !== id);
      await this.preferences.put(KEY_PENDING, JSON.stringify(filtered));
      await this.preferences.flush();
    } catch (err) {
      console.error('[MoodLite] markPendingAsSeen failed: ' + JSON.stringify(err));
    }
  }

  // ========== 成就通知 ==========

  /** 成就结算后通知 UI */
  private notifyAchievements(records: MoodRecord[]): void {
    const list: Record<string, string>[] = [];
    const keys = Object.keys(this.unlockedAchievements);
    for (const k of keys) {
      const item: Record<string, string> = {};
      item['id'] = k;
      item['date'] = this.unlockedAchievements[k];
      list.push(item);
    }
    AppStorage.set('achievements', JSON.stringify(list));
  }

  // ========== 启动状态 ==========

  /** 是否为首次启动 */
  async isFirstLaunch(): Promise<boolean> {
    if (!this.preferences) return true;
    try {
      return await this.preferences.get(KEY_FIRST_LAUNCH, true) as boolean;
    } catch (err) {
      return true;
    }
  }

  /** 标记已启动（Welcome 页“开始体验”点击后调用） */
  async markLaunched(): Promise<void> {
    if (!this.preferences) return;
    try {
      await this.preferences.put(KEY_FIRST_LAUNCH, false);
      await this.preferences.flush();
    } catch (err) {
      console.error('[MoodLite] markLaunched failed: ' + JSON.stringify(err));
    }
  }

  /** 清空全部数据（调试用） */
  async clearAll(): Promise<void> {
    if (!this.preferences) return;
    try {
      await this.preferences.clear();
      await this.preferences.flush();
      this.cache = [];
      this.unlockedAchievements = {};
      this.syncAchievementsToUI();
    } catch (err) {
      console.error('[MoodLite] clearAll failed: ' + JSON.stringify(err));
    }
  }
}

export default DataManager.getInstance();
