/**
 * LoginPage — 登录/注册页
 */

import AuthManager from '../common/AuthManager';
import { Token, Dark, S, F, R } from '../common/styles';
import { resolveColors } from '../common/ThemeManager';

@Entry
@Component
struct LoginPage {
  @StorageLink('darkMode') darkMode: boolean = false;
  @StorageLink('currentTheme') currentTheme: string = 'blossomPink';
  @State username: string = '';
  @State password: string = '';
  @State isRegister: boolean = false;
  @State error: string = '';

  aboutToAppear(): void {
    const ctx = this.getUIContext().getHostContext();
    if (ctx) AuthManager.init(ctx);
  }

  async submit(): Promise<void> {
    this.error = '';
    if (!this.username.trim() || !this.password.trim()) {
      this.error = '请输入用户名和密码';
      return;
    }
    const ok = this.isRegister
      ? await AuthManager.register(this.username.trim(), this.password.trim())
      : await AuthManager.login(this.username.trim(), this.password.trim());
    if (ok) {
      this.getUIContext().getRouter().replaceUrl({ url: 'pages/MainPage' });
    } else {
      this.error = this.isRegister ? '注册失败，用户名已存在' : '用户名或密码错误';
    }
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
            .fontColor(Token.DELETE_RED).margin({ top: 4 })
        }

        Button(this.isRegister ? '注 册' : '登 录')
          .width('100%').height(48).fontSize(F.BODY).fontWeight(FontWeight.Medium)
          .backgroundColor(resolveColors(this.darkMode, this.currentTheme).PINK)
          .borderRadius(R.BUTTON)
          .fontColor(resolveColors(this.darkMode, this.currentTheme).BTN_TEXT)
          .margin({ top: S.SM })
          .onClick(() => { this.submit(); })

        Text(this.isRegister ? '已有账号？去登录' : '没有账号？去注册')
          .fontSize(F.CAPTION)
          .fontColor(resolveColors(this.darkMode, this.currentTheme).PINK)
          .margin({ top: S.SM })
          .onClick(() => {
            this.isRegister = !this.isRegister;
            this.error = '';
          })
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
