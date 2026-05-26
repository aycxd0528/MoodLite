/**
 * AIAgentChatPage — AI 情绪分析对话页
 */

import DataManager from '../data/DataManager';
import { MoodRecord, formatDateStr } from '../model/MoodRecord';
import { Token, Dark, S, F } from '../common/styles';
import { ChatMessage, TodayRecord, sendMessageStream, buildTodayContext } from '../common/utils/MoodAgent';

interface UIMessage {
  id: string;
  role: string;
  content: string;
  isStreaming: boolean;
}

let msgId = 0;
function nextId(): string { return String(++msgId); }

@Entry
@Component
struct AIAgentChatPage {
  @StorageLink('darkMode') darkMode: boolean = false;
  @StorageLink('currentTheme') currentTheme: string = 'blossomPink';
  @State messages: UIMessage[] = [];
  @State inputText: string = '';
  @State loading: boolean = true;

  private scroller: Scroller = new Scroller();
  private analysisSent: boolean = false;

  onPageShow(): void {
    if (this.analysisSent) return;
    this.analysisSent = true;
    this.loadRecords();
  }

  aboutToDisappear(): void {
    this.loading = false;
  }

  async loadRecords(): Promise<void> {
    await DataManager.ensureInitialized();
    const allRecords = await DataManager.getAllRecords();
    const today = formatDateStr(new Date());
    const todayRecords = allRecords.filter(r => r.dateStr === today);

    if (todayRecords.length === 0) {
      this.messages = [{
        id: nextId(), role: 'assistant',
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

    const aiId = nextId();
    this.messages = [{
      id: aiId, role: 'assistant',
      content: '正在分析…', isStreaming: true,
    }];

    const sysMsg: ChatMessage = {
      role: 'system',
      content: '简洁回复，每次不超过三句话。风格温暖但不啰嗦。',
    };
    const userMsg: ChatMessage = { role: 'user', content: ctx };

    sendMessageStream([sysMsg, userMsg], {
      onToken: (text: string) => {
        this.replaceMessage(aiId, text, true);
      },
      onDone: () => {
        const msg = this.findMessage(aiId);
        this.replaceMessage(aiId, msg.content, false);
        this.loading = false;
      },
      onError: (msg: string) => {
        this.replaceMessage(aiId, '分析失败: ' + msg, false);
        this.loading = false;
      },
    });
  }

  sendMessage(): void {
    const text = this.inputText.trim();
    if (!text || this.loading) return;

    this.inputText = '';
    const aiId = nextId();
    this.messages = [...this.messages,
      { id: nextId(), role: 'user', content: text, isStreaming: false },
      { id: aiId, role: 'assistant', content: '', isStreaming: true },
    ];
    this.loading = true;

    // 构建完整对话历史，保持多轮上下文
    const chatMsgs: ChatMessage[] = [
      { role: 'system', content: '简洁回复，每次不超过三句话。风格温暖但不啰嗦。' },
    ];
    for (let i = 0; i < this.messages.length - 1; i++) {
      chatMsgs.push({
        role: this.messages[i].role as ('system' | 'user' | 'assistant'),
        content: this.messages[i].content,
      });
    }

    sendMessageStream(chatMsgs, {
      onToken: (t: string) => {
        this.replaceMessage(aiId, t, true);
      },
      onDone: () => {
        const msg = this.findMessage(aiId);
        this.replaceMessage(aiId, msg.content, false);
        this.loading = false;
      },
      onError: (msg: string) => {
        this.replaceMessage(aiId, '抱歉，出了点问题 ' + msg, false);
        this.loading = false;
      },
    });
  }

  replaceMessage(id: string, content: string, streaming: boolean): void {
    this.messages = this.messages.map(m =>
      m.id === id ? ({ id: m.id, role: m.role, content: content, isStreaming: streaming } as UIMessage) : m
    );
  }

  findMessage(id: string): UIMessage {
    return this.messages.find(m => m.id === id) || { id: '', role: '', content: '', isStreaming: false };
  }

  fmtTime(ts: number): string {
    const d = new Date(ts);
    return String(d.getHours()).padStart(2, '0') + ':' + String(d.getMinutes()).padStart(2, '0');
  }

  build() {
    Column() {
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

      List({ scroller: this.scroller }) {
        ForEach(this.messages, (msg: UIMessage) => {
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
        }, (msg: UIMessage) => msg.id)
      }
      .layoutWeight(1).scrollBar(BarState.Off)
      .onScrollIndex(_first => { this.scroller.scrollEdge(Edge.Bottom); })

      Row({ space: S.SM }) {
        TextInput({ placeholder: this.loading ? 'AI 正在思考...' : '输入消息...', text: this.inputText })
          .layoutWeight(1).height(44).fontSize(14)
          .backgroundColor(this.darkMode ? Dark.CARD : Token.BAR_BG)
          .borderRadius(22).padding({ left: 16, right: 16 })
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
