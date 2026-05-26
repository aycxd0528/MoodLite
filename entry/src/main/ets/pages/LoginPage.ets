/**
 * LoginPage — 登录/注册页
 */

import AuthManager from '../common/AuthManager';
import { GlassCard } from '../common/components/GlassCard';
import { S, F, R } from '../common/styles';
import { resolveColors } from '../common/ThemeManager';
import window from '@ohos.window';

@Entry
@Component
struct LoginPage {
  @StorageLink('darkMode') darkMode: boolean = false;
  @StorageLink('currentTheme') currentTheme: string = 'blossomPink';
  @State username: string = '';
  @State password: string = '';
  @State isRegister: boolean = false;
  @State error: string = '';
  @State isSubmitting: boolean = false;
  @State tabOpacity: number = 1.0;

  onPageShow(): void {
    const ctx = this.getUIContext().getHostContext();
    if (ctx) {
      window.getLastWindow(ctx).then(win => {
        win.getUIContext().setKeyboardAvoidMode(1); // RESIZE
      });
    }
  }

  async submit(): Promise<void> {
    if (this.isSubmitting) return;
    this.error = '';
    if (!this.username.trim() || !this.password.trim()) {
      this.error = '请输入用户名和密码';
      return;
    }
    this.isSubmitting = true;
    const ok = this.isRegister
      ? await AuthManager.register(this.username.trim(), this.password.trim())
      : await AuthManager.login(this.username.trim(), this.password.trim());
    this.isSubmitting = false;
    if (ok) {
      this.getUIContext().getRouter().replaceUrl({ url: 'pages/MainPage' });
    } else {
      this.error = this.isRegister ? '注册失败，用户名已存在' : '用户名或密码错误';
    }
  }

  toggleMode(): void {
    this.getUIContext()?.animateTo({ duration: 150, curve: Curve.EaseOut }, () => {
      this.tabOpacity = 0.0;
    });
    this.error = '';
    setTimeout(() => {
      this.isRegister = !this.isRegister;
      this.getUIContext()?.animateTo({ duration: 150, curve: Curve.EaseOut }, () => {
        this.tabOpacity = 1.0;
      });
    }, 160);
  }

  build() {
    Column() {
      Column() {
        Text('MoodLite').fontSize(36).fontWeight(FontWeight.Bold)
          .fontColor(resolveColors(this.darkMode, this.currentTheme).PINK)
        Text('轻心记').fontSize(14)
          .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_GRAY)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Center)
      .margin({ top: 80, bottom: 48 })

      GlassCard() {
        Column({ space: S.MD }) {
          TextInput({ placeholder: '用户名', text: this.username })
            .width('100%').height(48).fontSize(F.BODY)
            .backgroundColor(resolveColors(this.darkMode, this.currentTheme).BAR_BG)
            .borderRadius(R.SMALL)
            .onChange((v: string) => { this.username = v; })

          TextInput({ placeholder: '密码', text: this.password })
            .width('100%').height(48).fontSize(F.BODY)
            .type(InputType.Password)
            .backgroundColor(resolveColors(this.darkMode, this.currentTheme).BAR_BG)
            .borderRadius(R.SMALL)
            .onChange((v: string) => { this.password = v; })
            .onSubmit(() => { this.submit(); })

          if (this.error) {
            Text(this.error).fontSize(12)
              .fontColor('#FF6B6B').margin({ top: 4 })
          }

          Button(this.isSubmitting ? '处理中…' : (this.isRegister ? '注 册' : '登 录'))
            .width('100%').height(48).fontSize(F.BODY).fontWeight(FontWeight.Medium)
            .backgroundColor(resolveColors(this.darkMode, this.currentTheme).PINK)
            .borderRadius(R.BUTTON)
            .fontColor(resolveColors(this.darkMode, this.currentTheme).BTN_TEXT)
            .enabled(!this.isSubmitting)
            .margin({ top: S.XS })
            .onClick(() => { this.submit(); })

          Text(this.isRegister ? '已有账号？去登录' : '没有账号？去注册')
            .fontSize(F.CAPTION)
            .fontColor(resolveColors(this.darkMode, this.currentTheme).PINK)
            .margin({ top: S.XS })
            .opacity(this.tabOpacity)
            .onClick(() => { this.toggleMode(); })
        }
        .width('100%').alignItems(HorizontalAlign.Center)
        .padding({ top: S.LG, bottom: S.LG, left: S.LG, right: S.LG })
      }
      .width('80%')
    }
    .width('100%').height('100%')
    .justifyContent(FlexAlign.Center)
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [[resolveColors(this.darkMode, this.currentTheme).PINK_LIGHT, 0.0],
               [resolveColors(this.darkMode, this.currentTheme).BG, 1.0]],
    })
  }
}
