/**
 * AiAgentClient — Dify 工作流通信层
 *
 * 职责：
 * - 调用 Dify Workflow API 分析情绪文本
 * - 返回结构化建议对象，注入 dateStr 用于首页过期校验
 */

import http from '@ohos.net.http';
import { formatDateStr } from '../../model/MoodRecord';

const BASE_URL = 'https://api.dify.ai/v1/workflow/run';
const API_KEY = 'app-S6zhHuzyIKdblmTqC4g7esFi';
const USER_ID = 'aycxd';

export interface AiSuggestion {
  /** AI 返回的建议文本 */
  suggestion: string;
  /** 原始情绪文本 */
  input: string;
  /** 生成日期 YYYY-MM-DD，用于过期校验 */
  dateStr: string;
}

interface DifyRequestBody {
  inputs: Record<string, string>;
  response_mode: string;
  user: string;
}

interface DifyResponse {
  outputs?: Record<string, string>;
}

/**
 * 异步调用 Dify 工作流，分析情绪文本并返回建议
 * @param moodText 用户输入的情绪文本
 * @returns AiSuggestion 或 null（失败时）
 */
export async function analyzeMood(moodText: string): Promise<AiSuggestion | null> {
  if (!moodText || moodText.trim().length === 0) {
    return null;
  }

  try {
    const httpRequest = http.createHttp();
    const inputsMap: Record<string, string> = { 'mood_text': moodText };
    const requestBody: DifyRequestBody = {
      inputs: inputsMap,
      response_mode: 'blocking',
      user: USER_ID,
    };

    const headerMap: Record<string, string> = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ' + API_KEY,
    };
    const options: http.HttpRequestOptions = {
      method: http.RequestMethod.POST,
      header: headerMap,
      extraData: JSON.stringify(requestBody),
      connectTimeout: 10000,
      readTimeout: 30000,
    };

    const response = await httpRequest.request(BASE_URL, options);
    httpRequest.destroy();

    if (response.responseCode === 200) {
      const result: DifyResponse = JSON.parse(response.result as string) as DifyResponse;
      const outputs = result.outputs;
      const suggestionText = outputs?.['text'] || outputs?.['result'] || '';

      if (suggestionText.length > 0) {
        return {
          suggestion: suggestionText,
          input: moodText,
          dateStr: formatDateStr(new Date()),
        };
      }
    }

    console.error('[MoodLite] AiAgentClient — API response code: ' + response.responseCode);
    return null;
  } catch (err) {
    console.error('[MoodLite] AiAgentClient — request failed: ' + JSON.stringify(err));
    return null;
  }
}
