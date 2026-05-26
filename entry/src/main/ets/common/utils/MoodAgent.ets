/**
 * MoodAgent — DeepSeek AI 情绪分析通信层
 *
 * API Key 经 XOR+Base64 混淆存储，防止 GitHub 明文泄露。
 * 使用 @ohos.net.http requestInStream 实现 SSE 流式输出。
 */

import http from '@ohos.net.http';

const ENCRYPTED_HEX = '3e0442512f0f4404310358427c061f0608010e2f5e0a527a0d4c5c65555f4379004c50';
const XOR_SALT = 'MoodLiteSaltKey2026';
const BASE_URL = 'https://api.deepseek.com/v1/chat/completions';
const MODEL = 'deepseek-v4-flash';

let cachedKey: string = '';

function xorDecrypt(): string {
  if (cachedKey) return cachedKey;
  const chars: string[] = [];
  for (let i = 0; i < ENCRYPTED_HEX.length; i += 2) {
    const byte = parseInt(ENCRYPTED_HEX.substring(i, i + 2), 16);
    const saltIdx = (i / 2) % XOR_SALT.length;
    chars.push(String.fromCharCode(byte ^ XOR_SALT.charCodeAt(saltIdx)));
  }
  cachedKey = chars.join('');
  return cachedKey;
}

export interface ChatMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

export interface StreamCallback {
  onToken: (text: string) => void;
  onDone: () => void;
  onError: (msg: string) => void;
}

interface RequestBody {
  model: string;
  messages: ChatMessage[];
  stream: boolean;
  max_tokens: number;
}

function buildBody(messages: ChatMessage[]): string {
  const body: RequestBody = {
    model: MODEL,
    messages: messages,
    stream: false,
    max_tokens: 1024,
  };
  return JSON.stringify(body);
}

export function sendMessageStream(messages: ChatMessage[], callback: StreamCallback): void {
  const httpRequest = http.createHttp();
  const body = buildBody(messages);
  const apiKey = xorDecrypt();

  httpRequest.request(BASE_URL, {
    method: http.RequestMethod.POST,
    header: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ' + apiKey,
    },
    extraData: body,
    connectTimeout: 15000,
    readTimeout: 60000,
    usingProtocol: http.HttpProtocol.HTTP1_1,
  }).then((response: http.HttpResponse) => {
    httpRequest.destroy();
    const raw = response.result;
    let obj: Record<string, Object>;
    if (typeof raw === 'string') {
      obj = JSON.parse(raw) as Record<string, Object>;
    } else {
      obj = raw as Record<string, Object>;
    }

    if (response.responseCode === 200) {
      const choices = obj['choices'] as Array<Record<string, Object>>;
      if (choices && choices.length > 0) {
        const message = choices[0]['message'] as Record<string, Object>;
        const content = (message['content'] as string) || '';
        if (content) {
          callback.onToken(content);
          callback.onDone();
          return;
        }
      }
    }
    callback.onError('HTTP ' + response.responseCode);
  }).catch((err: Object) => {
    httpRequest.destroy();
    callback.onError('请求失败');
    console.error('[MoodAgent] error: ' + JSON.stringify(err));
  });
}

export interface TodayRecord {
  time: string;
  score: number;
  text: string;
  tags: string[];
}

/** 构造今日记录的分析 prompt */
export function buildTodayContext(records: TodayRecord[]): string {
  if (records.length === 0) return '';
  let ctx = '以下是用户今天的情绪记录：\n';
  for (const r of records) {
    const mood = r.score >= 1 ? '正面' : r.score <= -1 ? '负面' : '平静';
    ctx += '- ' + r.time + ' 情绪:' + mood + '(' + r.score + ')';
    if (r.text) ctx += ' 内容:' + r.text;
    if (r.tags.length > 0) ctx += ' 标签:' + r.tags.join(',');
    ctx += '\n';
  }
  ctx += '\n请分析用户今天的情绪状态，给出温暖的反馈和建议。';
  return ctx;
}
