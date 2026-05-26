/**
 * AIAgentChatPage — AI 情绪分析对话页
 *
 * 进入时自动发送当天所有记录作为上下文，
 * DeepSeek 流式输出分析结果，支持多轮追问。
 */

import DataManager from '../data/DataManager';
import { MoodRecord, getMoodEmoji, formatDateStr } from '../model/MoodRecord';
import { Token, Dark, S, F } from '../common/styles';
import { GlassCard } from '../common/components/GlassCard';
import { ChatMessage, TodayRecord, sendMessageStream, buildTodayContext } from '../common/utils/MoodAgent';

interface UIMessage {
  role: string;
  content: string;
  isStreaming: boolean;
}

@Entry
@Component
struct AIAgentChatPage {
  @StorageLink('darkMode') darkMode: boolean = false;
  @StorageLink('currentTheme') currentTheme: string = 'blossomPink';
  @State messages: UIMessage[] = [];
  @State inputText: string = '';
  @State loading: boolean = true;
  @StorageLink('ai_analysis_result') analysisResult: string = '';
  @StorageLink('ai_analysis_done') @Watch('onAnalysisDone') analysisDone: number = 0;
  private scroller: Scroller = new Scroller();

  onAnalysisDone(): void {
    if (this.analysisDone !== 1) return;
    const text = this.analysisResult;
    if (text.startsWith('分析失败')) {
      this.messages[0].content = text;
    } else {
      this.messages[0].content = text;
    }
    this.messages[0].isStreaming = false;
    this.loading = false;
    this.messages = [...this.messages];
    AppStorage.set('ai_analysis_done', 0);
  }

  private analysisSent: boolean = false;

  onPageShow(): void {
    if (this.analysisSent) return;
    this.analysisSent = true;
    this.loadRecords();
  }

  aboutToDisappear(): void {
    this.loading = false;
    AppStorage.set('ai_analysis_done', 0);
    AppStorage.set('ai_analysis_result', '');
  }

  async loadRecords(): Promise<void> {
    await DataManager.ensureInitialized();
    const allRecords = await DataManager.getAllRecords();
    const today = formatDateStr(new Date());
    const todayRecords = allRecords.filter(r => r.dateStr === today);

    if (todayRecords.length === 0) {
      this.messages = [{
        role: 'assistant',
        content: '今天还没有记录，去记录一条心情再来找我吧。',
        isStreaming: false,
      }];
      this.loading = false;
      return;
    }

    const ctx = buildTodayContext(todayRecords.map((r: MoodRecord): TodayRecord => ({
      time: this.fmtTime(r.timestamp),
      score: r.score,
      text: r.text,
      tags: r.tags,
    })));

    const sysMsg: ChatMessage = {
      role: 'system',
      content: '简洁回复，每次不超过三句话。风格温暖但不啰嗦。',
    };
    const userMsg: ChatMessage = { role: 'user', content: ctx };

    this.messages = [{ role: 'assistant', content: '正在分析…', isStreaming: true }];

    setTimeout(() => {
      sendMessageStream([sysMsg, userMsg], {
        onToken: (text: string) => {
          AppStorage.set('ai_analysis_result', text);
        },
        onDone: () => {
          AppStorage.set('ai_analysis_done', 1);
        },
        onError: (msg: string) => {
          AppStorage.set('ai_analysis_result', '分析失败: ' + msg);
          AppStorage.set('ai_analysis_done', 1);
        },
      });
    }, 500);
  }

  sendMessage(): void {
    const text = this.inputText.trim();
    if (!text || this.loading) return;

    this.inputText = '';
    const userMsg: UIMessage = { role: 'user', content: text, isStreaming: false };
    const streamMsg: UIMessage = { role: 'assistant', content: '', isStreaming: true };
    this.messages.unshift(userMsg);
    this.messages.unshift(streamMsg);
    this.loading = true;

    const chatMsgs: ChatMessage[] = [
      { role: 'system', content: '简洁回复，每次不超过三句话。风格温暖但不啰嗦。' },
    ];
    chatMsgs.push({ role: 'user', content: text });

    sendMessageStream(chatMsgs, {
      onToken: (t: string) => {
        this.getUIContext()?.animateTo({ duration: 0 }, () => {
          this.messages[0].content = t;
        });
      },
      onDone: () => {
        this.getUIContext()?.animateTo({ duration: 0 }, () => {
          this.messages[0].isStreaming = false;
          this.loading = false;
          this.messages = [...this.messages];
        });
      },
      onError: (msg: string) => {
        this.getUIContext()?.animateTo({ duration: 0 }, () => {
          this.messages[0].content = '抱歉，出了点问题 ' + msg;
          this.messages[0].isStreaming = false;
          this.loading = false;
          this.messages = [...this.messages];
        });
      },
    });
  }

  fmtTime(ts: number): string {
    const d = new Date(ts);
    return String(d.getHours()).padStart(2, '0') + ':' + String(d.getMinutes()).padStart(2, '0');
  }

  build() {
    Column() {
      // 标题栏
      Stack({ alignContent: Alignment.Center }) {
        Text('AI 情绪分析').fontSize(F.BODY).fontWeight(FontWeight.Medium)
          .fontColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN)

        Row() {
          Image($r('app.media.ic_back')).width(24).height(24).objectFit(ImageFit.Contain)
            .fillColor(this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN)
            .onClick(() => { this.getUIContext().getRouter().back(); })
          Blank()
        }.width('100%')
      }
      .width('100%').padding({ top: S.HEADER_TOP, bottom: S.SM, left: S.LG, right: S.LG })

      // 消息列表
      List({ scroller: this.scroller }) {
        ForEach(this.messages, (msg: UIMessage, index: number) => {
          ListItem() {
            Row() {
              if (msg.role === 'user') Blank()
              Column() {
                Text(msg.content + (msg.isStreaming ? ' ▍' : ''))
                  .fontSize(14).lineHeight(22)
                  .fontColor(msg.role === 'user'
                    ? Token.TEXT_WHITE
                    : (this.darkMode ? Dark.TEXT_MAIN : Token.TEXT_MAIN))
                  .padding({ left: 14, right: 14, top: 10, bottom: 10 })
                  .backgroundColor(msg.role === 'user'
                    ? Token.PINK
                    : (this.darkMode ? Dark.CARD : Token.BUBBLE_BG))
                  .borderRadius(16)
                  .constraintSize({ maxWidth: '80%' })
              }
              .alignItems(msg.role === 'user' ? HorizontalAlign.End : HorizontalAlign.Start)
              if (msg.role !== 'user') Blank()
            }.width('100%').padding({ left: 12, right: 12, top: 4, bottom: 4 })
          }
        }, (_msg: UIMessage, index: number) => index.toString())
      }
      .layoutWeight(1).scrollBar(BarState.Off)
      .onScrollIndex(_first => { this.scroller.scrollEdge(Edge.Bottom); })

      // 输入区
      Row({ space: S.SM }) {
        TextInput({ placeholder: this.loading ? 'AI 正在思考...' : '输入消息...', text: this.inputText })
          .layoutWeight(1).height(44)
          .fontSize(14)
          .backgroundColor(this.darkMode ? Dark.CARD : Token.BAR_BG)
          .borderRadius(22)
          .padding({ left: 16, right: 16 })
          .placeholderColor(this.darkMode ? Dark.TEXT_GRAY : Token.TEXT_GRAY)
          .enabled(!this.loading)
          .onChange((v: string) => { this.inputText = v; })
          .onSubmit(() => { this.sendMessage(); })

        Button('发送')
          .height(44).fontSize(14)
          .backgroundColor(Token.PINK).borderRadius(22)
          .fontColor(Token.TEXT_WHITE)
          .padding({ left: 16, right: 16 })
          .enabled(!this.loading && this.inputText.trim().length > 0)
          .onClick(() => { this.sendMessage(); })
      }
      .width('100%')
      .padding({ left: S.LG, right: S.LG, bottom: S.MD, top: S.XS })
    }
    .width('100%').height('100%')
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: this.darkMode
        ? [[Dark.PINK_LIGHT, 0.0], [Dark.BG, 1.0]]
        : [[Token.PINK_LIGHT, 0.0], [Token.TEXT_WHITE, 1.0]],
    })
  }
}
