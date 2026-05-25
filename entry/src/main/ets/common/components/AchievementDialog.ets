/**
 * AchievementDialog — 成就解锁弹窗（玻璃拟态）
 *
 * 全局统一的成就展示视觉通道。
 * 徽章入场附带弹簧动画，点击"收下"后标记已读并清理队列。
 *
 * 生命周期：
 *  - AchievementChecker 在 saveRecord 后结算，将新成就 ID 写入 pending 队列
 *  - HomeTab.onRecordsChange 检测 pending 队列非空 → 拉起此弹窗
 *  - 用户点击"收下" → markPendingAsSeen → 检查下一个
 */

import curves from '@ohos.curves';
import { AchievementItem, ACHIEVEMENTS } from '../../model/Achievement';
import { Token, Shadow, R, S, F } from '../styles';
import { resolveColors } from '../ThemeManager';

@CustomDialog
export struct AchievementDialog {
  controller: CustomDialogController;
  @StorageLink('darkMode') darkMode: boolean = false;
  @StorageLink('currentTheme') currentTheme: string = 'blossomPink';
  achievement: AchievementItem = ACHIEVEMENTS[0];
  onClaim: () => void = () => {};

  @State badgeScale: number = 0.2;
  @State badgeOpacity: number = 0.0;
  @State contentOpacity: number = 0.0;
  @State contentOffY: number = 24;

  aboutToAppear(): void {
    // 等待一帧让对话框完成布局后再触发动画
    this.scheduleEntryAnimation(50);
  }

  private scheduleEntryAnimation(delay: number): void {
    setTimeout(() => {
      const ctx = this.getUIContext();
      if (ctx) {
        ctx.animateTo({ curve: curves.springMotion(0.4, 0.6) }, () => {
          this.badgeScale = 1.0;
          this.badgeOpacity = 1.0;
        });
        ctx.animateTo({ duration: 350, curve: Curve.EaseOut }, () => {
          this.contentOpacity = 1.0;
          this.contentOffY = 0;
        });
      } else if (delay < 200) {
        // UIContext 尚未就绪，递增重试（最多至 200ms）
        this.scheduleEntryAnimation(delay + 50);
      } else {
        // 最终兜底：直接设置终态，确保弹窗不会停留在空白状态
        this.badgeScale = 1.0;
        this.badgeOpacity = 1.0;
        this.contentOpacity = 1.0;
        this.contentOffY = 0;
      }
    }, delay);
  }

  build() {
    Column() {
      // 可滚动内容区：徽章 + 标题 + 描述
      Scroll() {
        Column() {
          // 顶部星芒装饰
          Image($r('app.media.ic_sparkles'))
            .width(32).height(32).objectFit(ImageFit.Contain)
            .fillColor(this.achievement.color)
            .opacity(0.8)
            .margin({ bottom: 4 })

          // 成就徽章（弹簧动画聚焦点）
          Image(this.achievement.icon)
            .width(120).height(120).objectFit(ImageFit.Contain)
            .scale({ x: this.badgeScale, y: this.badgeScale })
            .opacity(this.badgeOpacity)
            .fillColor(this.achievement.color)
            .margin({ bottom: 8 })

          // 标题
          Text(this.achievement.title)
            .fontSize(22).fontWeight(FontWeight.Bold)
            .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_MAIN)
            .opacity(this.contentOpacity).translate({ y: this.contentOffY })
            .margin({ bottom: S.XS })
            .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })

          // 描述
          Text(this.achievement.desc)
            .fontSize(F.BODY)
            .fontColor(resolveColors(this.darkMode, this.currentTheme).TEXT_GRAY)
            .opacity(this.contentOpacity).translate({ y: this.contentOffY })
            .maxLines(6).textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%').alignItems(HorizontalAlign.Center)
      }
      .scrollBar(BarState.Off).scrollable(ScrollDirection.Vertical)
      .edgeEffect(EdgeEffect.Spring).clip(false)
      .constraintSize({ maxHeight: 260 })

      // 收下按钮 — 固定在底部，始终可见
      Button('收下成就')
        .width('100%').height(44)
        .backgroundColor(resolveColors(this.darkMode, this.currentTheme).PINK).borderRadius(R.BUTTON)
        .fontSize(F.BODY).fontWeight(FontWeight.Medium).fontColor(resolveColors(this.darkMode, this.currentTheme).BTN_TEXT)
        .shadow(Shadow.CARD)
        .opacity(this.contentOpacity).translate({ y: this.contentOffY })
        .margin({ top: 16 })
        .onClick(() => {
          this.controller.close();
          this.onClaim();
        })
    }
    .width(280)
    .constraintSize({ maxHeight: 500 })
    .padding(20)
    .backgroundColor(resolveColors(this.darkMode, this.currentTheme).CARD)
    .borderRadius(R.CARD)
    .border({ width: 0.5, color: this.darkMode ? 'rgba(255,255,255,0.08)' : 'rgba(255,255,255,0.40)' })
    .shadow({ radius: Shadow.CARD.radius, color: resolveColors(this.darkMode, this.currentTheme).SHADOW_COLOR, offsetY: Shadow.CARD.offsetY })
    .alignItems(HorizontalAlign.Center)
  }
}
