/**
 * AIAgentChatPage — AI 情绪分析对话页
 */

import DataManager from '../data/DataManager';
import { MoodRecord, formatDateStr } from '../model/MoodRecord';
import { S, F } from '../common/styles';
import { resolveColors } from '../common/ThemeManager';
import { ChatMessage, TodayRecord, sendMessageStream, buildTodayContext } from '../common/utils/MoodAgent';

@Observed
export class UIMessage {
  id: string;
  role: string;
  content: string;
  isStreaming: boolean;

  constructor(id: string, role: string, content: string, isStreaming: boolean) {
    this.id = id;
    this.role = role;
    this.content = content;
    this.isStreaming = isStreaming;
  }
}

let msgId = 0;
function nextId(): string { return String(++msgId); }

@Component
struct MessageBubble {
  @ObjectLink msg: UIMessage;
  @Prop darkMode: boolean;
  @Prop currentTheme: string;

  build() {
    const C = resolveColors(this.darkMode, this.currentTheme);
    Row() {
      if (this.msg.role === 'user') Blank()
      Column() {
        Text(this.msg.content + (this.msg.isStreaming ? ' ▍' : ''))
          .fontSize(14).lineHeight(22)
          .fontColor(this.msg.role === 'user'
            ? C.TEXT_WHITE
            : C.TEXT_MAIN)
          .padding({ left: 14, right: 14, top: 10, bottom: 10 })
          .backgroundColor(this.msg.role === 'user'
            ? C.PINK
            : C.CARD)
          .borderRadius(16)
          .constraintSize({ maxWidth: '80%' })
      }
      .alignItems(this.msg.role === 'user' ? HorizontalAlign.End : HorizontalAlign.Start)
      if (this.msg.role !== 'user') Blank()
    }.width('100%').padding({ left: 12, right: 12, top: 4, bottom: 4 })
  }
}

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
      this.messages = [
        new UIMessage(nextId(), 'assistant', '今天还没有记录，去记录一条心情再来找我吧。', false)
      ];
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
    this.messages = [
      new UIMessage(aiId, 'assistant', '正在分析…', true)
    ];

    const sysMsg: ChatMessage = {
      role: 'system',
      content: '简洁回复，每次不超过三句话。风格温暖但不啰嗦。',
    };
    const userMsg: ChatMessage = { role: 'user', content: ctx };

    sendMessageStream([sysMsg, userMsg], {
      onToken: (text: string) => {
        this.typewrite(aiId, text);
      },
      onDone: () => {
        const msg = this.findMessage(aiId);
        if (msg) { msg.isStreaming = false; }
        this.loading = false;
      },
      onError: (msg: string) => {
        const em = this.findMessage(aiId);
        if (em) { em.content = '分析失败: ' + msg; em.isStreaming = false; }
        this.loading = false;
      },
    });
  }

  sendMessage(): void {
    const text = this.inputText.trim();
    if (!text || this.loading) return;

    this.inputText = '';
    const aiId = nextId();
    this.messages.push(new UIMessage(nextId(), 'user', text, false));
    this.messages.push(new UIMessage(aiId, 'assistant', '', true));

    this.loading = true;
    this.scroller.scrollEdge(Edge.Bottom);

    const chatMsgs: ChatMessage[] = [
      { role: 'system', content: '简洁回复，每次不超过三句话。风格温暖但不啰嗦。' }
    ];
    for (let i = 0; i < this.messages.length - 1; i++) {
      const r = this.messages[i].role;
      chatMsgs.push({
        role: (r === 'user' || r === 'assistant' || r === 'system') ? r : 'user',
        content: this.messages[i].content
      });
    }

    sendMessageStream(chatMsgs, {
      onToken: (t: string) => {
        this.typewrite(aiId, t);
      },
      onDone: () => {
        const msg = this.findMessage(aiId);
        if (msg) { msg.isStreaming = false; }
        this.loading = false;
      },
      onError: (msg: string) => {
        const em = this.findMessage(aiId);
        if (em) { em.content = '抱歉，出了点问题 ' + msg; em.isStreaming = false; }
        this.loading = false;
      },
    });
  }

  updateMessage(id: string, content: string, streaming: boolean): void {
    const msg = this.messages.find(m => m.id === id);
    if (msg) {
      msg.content = content;
      msg.isStreaming = streaming;
      this.scroller.scrollEdge(Edge.Bottom);
    }
  }

  // 打字机：逐字追加，2ms/字，首字符清空占位
  typewrite(id: string, fullText: string): void {
    const msg = this.messages.find(m => m.id === id);
    if (!msg) return;
    msg.content = '';
    let i = 0;
    const timer = setInterval(() => {
      if (i < fullText.length) {
        msg.content += fullText.charAt(i);
        i++;
        this.scroller.scrollEdge(Edge.Bottom);
      } else {
        clearInterval(timer);
      }
    }, 25);
  }

  findMessage(id: string): UIMessage | undefined {
    return this.messages.find(m => m.id === id);
  }

  fmtTime(ts: number): string {
    const d = new Date(ts);
    return String(d.getHours()).padStart(2, '0') + ':' + String(d.getMinutes()).padStart(2, '0');
  }

  build() {
    Column() {
      Stack({ alignContent: Alignment.Center }) {
        Text('AI 情绪分析').fontSize(F.BODY).fontWeight(FontWeight.Medium)
          .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_MAIN)

        Row() {
          Image($r('app.media.ic_back')).width(24).height(24).objectFit(ImageFit.Contain)
            .fillColor(resolveColors(this.darkMode, this.currentTheme).TEXT_MAIN)
            .onClick(() => { this.getUIContext().getRouter().back(); })
          Blank()
        }.width('100%')
      }
      .width('100%').padding({ top: S.HEADER_TOP, bottom: S.SM, left: S.LG, right: S.LG })

      List({ scroller: this.scroller }) {
        ForEach(this.messages, (msg: UIMessage) => {
          ListItem() {
            MessageBubble({ msg: msg, darkMode: this.darkMode, currentTheme: this.currentTheme })
          }
        }, (msg: UIMessage) => msg.id)
      }
      .layoutWeight(1).scrollBar(BarState.Off)

      Row({ space: S.SM }) {
        TextInput({ placeholder: this.loading ? 'AI 正在思考...' : '输入消息...', text: this.inputText })
          .layoutWeight(1).height(44).fontSize(14)
          .backgroundColor(resolveColors(this.darkMode, this.currentTheme).BAR_BG)
          .borderRadius(22).padding({ left: 16, right: 16 })
          .placeholderColor(resolveColors(this.darkMode, this.currentTheme).TEXT_GRAY)
          .enabled(!this.loading)
          .onChange((v: string) => { this.inputText = v; })
          .onSubmit(() => { this.sendMessage(); })

        Button('发送')
          .height(44).fontSize(14)
          .backgroundColor(resolveColors(this.darkMode, this.currentTheme).PINK).borderRadius(22)
          .fontColor(resolveColors(this.darkMode, this.currentTheme).BTN_TEXT)
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
      colors: [[resolveColors(this.darkMode, this.currentTheme).PINK_LIGHT, 0.0],
               [resolveColors(this.darkMode, this.currentTheme).BG, 1.0]],
    })
  }
}
