/**
 * DataPrivacyPage — 本地数据与隐私说明
 */

import { GlassCard } from '../common/components/GlassCard';
import { F, R, S } from '../common/styles';
import { resolveColors } from '../common/ThemeManager';

interface PrivacyItem {
  title: string;
  detail: string;
}

const PRIVACY_ITEMS: PrivacyItem[] = [
  { title: '只保存在本机', detail: '情绪记录、标签、主题与提醒配置仅保存在你的设备中。' },
  { title: '无需账号', detail: '使用 MoodLite 不需要注册、登录或提供个人身份信息。' },
  { title: '不上传情绪内容', detail: '应用不包含网络访问能力，也不会把日记内容发送到服务器。' },
  { title: '不调用第三方 AI', detail: '记录与统计均在本地完成，不接入第三方分析或生成服务。' },
];

@Entry
@Component
struct DataPrivacyPage {
  @StorageLink('darkMode') darkMode: boolean = false;
  @StorageLink('currentTheme') currentTheme: string = 'blossomPink';

  build() {
    Stack({ alignContent: Alignment.Top }) {
      Column()
        .width('100%')
        .height('35%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [
            [resolveColors(this.darkMode, this.currentTheme).PINK_LIGHT, 0.0],
            [resolveColors(this.darkMode, this.currentTheme).BG, 1.0],
          ],
        })

      Column() {
        Stack({ alignContent: Alignment.Center }) {
          Text('数据与隐私')
            .fontSize(F.BODY)
            .fontWeight(FontWeight.Medium)
            .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_MAIN)

          Row() {
            Image($r('app.media.ic_back'))
              .width(24).height(24).objectFit(ImageFit.Contain)
              .fillColor(resolveColors(this.darkMode, this.currentTheme).TEXT_MAIN)
              .onClick(() => { this.getUIContext().getRouter().back(); })
            Blank()
          }
          .width('100%')
        }
        .width('100%')
        .padding({ top: S.HEADER_TOP, bottom: S.MD, left: S.LG, right: S.LG })

        Scroll() {
          Column({ space: S.MD }) {
            GlassCard() {
              Column({ space: S.SM }) {
                Image($r('app.media.ic_shield'))
                  .width(48).height(48).objectFit(ImageFit.Contain)
                  .fillColor(resolveColors(this.darkMode, this.currentTheme).PINK)
                Text('你的心情，只属于你')
                  .fontSize(F.SUBTITLE).fontWeight(FontWeight.Bold)
                  .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_MAIN)
                Text('MoodLite 是一款完全离线的轻量情绪日记。')
                  .fontSize(F.CAPTION)
                  .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_GRAY)
                  .textAlign(TextAlign.Center)
              }
              .width('100%').alignItems(HorizontalAlign.Center)
            }

            GlassCard() {
              Column() {
                ForEach(PRIVACY_ITEMS, (item: PrivacyItem) => {
                  Row({ space: S.SM }) {
                    Text('✓')
                      .fontSize(F.BODY).fontWeight(FontWeight.Bold)
                      .fontColor(resolveColors(this.darkMode, this.currentTheme).PINK)
                    Column({ space: 4 }) {
                      Text(item.title)
                        .fontSize(F.BODY).fontWeight(FontWeight.Medium)
                        .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_MAIN)
                      Text(item.detail)
                        .fontSize(F.CAPTION).lineHeight(20)
                        .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_GRAY)
                    }
                    .layoutWeight(1).alignItems(HorizontalAlign.Start)
                  }
                  .width('100%').alignItems(VerticalAlign.Top)
                  .padding({ top: S.SM, bottom: S.SM })
                }, (item: PrivacyItem) => item.title)
              }
              .width('100%')
            }

            Column({ space: S.XS }) {
              Text('请注意')
                .fontSize(F.BODY).fontWeight(FontWeight.Bold)
                .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_MAIN)
              Text('卸载应用或清空应用数据后，本地记录将被删除，且无法从云端恢复。')
                .fontSize(F.CAPTION).lineHeight(20)
                .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_GRAY)
            }
            .width('100%').alignItems(HorizontalAlign.Start)
            .padding(S.MD)
            .backgroundColor(resolveColors(this.darkMode, this.currentTheme).PINK_LIGHT)
            .borderRadius(R.SMALL)

            Row().height(S.BOTTOM_BREATH)
          }
          .padding({ left: S.LG, right: S.LG })
        }
        .layoutWeight(1).scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring)
      }
      .width('100%').height('100%')
    }
    .width('100%').height('100%')
    .backgroundColor(resolveColors(this.darkMode, this.currentTheme).BG)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
