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

const STORE_NAME = 'moodlite_db';
const KEY_RECORDS = 'records';
const KEY_FIRST_LAUNCH = 'first_launch';

class DataManager {
  private static instance: DataManager;
  private preferences: dataPreferences.Preferences | null = null;
  private context: Context | null = null;
  private writeQueue: Promise<void> = Promise.resolve();
  private initPromise: Promise<void> | null = null;
  private ready: boolean = false;

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
      this.ready = true;
      console.info('[MoodLite] DataManager init complete — preferences ready');
    } catch (err) {
      this.ready = false;
      const msg = '[MoodLite] Preferences init failed: ' + JSON.stringify(err);
      console.error(msg);
      throw new Error(msg);
    }
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

  /** 读取全部记录（按时间戳倒序） */
  async getAllRecords(): Promise<MoodRecord[]> {
    if (!this.preferences) {
      console.warn('[MoodLite] getAllRecords — DataManager not initialized, returning []');
      return [];
    }
    try {
      const raw = await this.preferences.get(KEY_RECORDS, '[]') as string;
      const parsed: MoodRecord[] = JSON.parse(raw);
      console.info('[MoodLite] getAllRecords — loaded ' + parsed.length + ' records');
      return parsed;
    } catch (err) {
      console.error('[MoodLite] getAllRecords failed, returning []: ' + JSON.stringify(err));
      return [];
    }
  }

  /** 保存/更新记录：同 ID 则删除旧记录后插入头部（串行化防竞态） */
  async saveRecord(record: MoodRecord): Promise<boolean> {
    return this.enqueue(async () => {
      if (!this.preferences) return false;
      const raw = await this.preferences.get(KEY_RECORDS, '[]') as string;
      const records: MoodRecord[] = JSON.parse(raw);
      const filtered = records.filter(r => r.id !== record.id);
      filtered.unshift(record);
      await this.preferences.put(KEY_RECORDS, JSON.stringify(filtered));
      await this.preferences.flush();
      return true;
    });
  }

  /** 删除单条记录（串行化防竞态） */
  async deleteRecord(id: string): Promise<boolean> {
    return this.enqueue(async () => {
      if (!this.preferences) return false;
      const records = await this.getAllRecords();
      const filtered = records.filter(r => r.id !== id);
      await this.preferences.put(KEY_RECORDS, JSON.stringify(filtered));
      await this.preferences.flush();
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
    } catch (err) {
      console.error('[MoodLite] clearAll failed: ' + JSON.stringify(err));
    }
  }
}

export default DataManager.getInstance();
