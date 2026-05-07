export class ControlButtonParameter {
  /**
   * Title content.
   */
  title?: ResourceStr;
  /**
   * Title color.
   */
  titleColor?: ResourceColor;
  /**
   * Title opacity.
   */
  titleOpacity?: number | Resource;
  /**
   * Title shadow.
   */
  titleShadow?: ShadowOptions | ShadowStyle;
  /**
   * Secondary text.
   */
  secondaryText?: ResourceStr;
  /**
   * Secondary text color.
   */
  secondaryTextColor?: ResourceColor;
  /**
   * Secondary text opacity.
   */
  secondaryTextOpacity?: number | Resource;
  /**
   * Secondary text shadow.
   */
  secondaryTextShadow?: ShadowOptions | ShadowStyle;
  /**
   * Logo icon.
   */
  logo?: ResourceStr;
  /**
   * Button icon.
   */
  buttonIcon?: ResourceStr;
  /**
   * Button text.
   */
  buttonText?: ResourceStr;
  /**
   * Button text color.
   */
  buttonTextColor?: ResourceColor;
  /**
   * Button text opacity.
   */
  buttonTextOpacity?: number | Resource;
  /**
   * Button text shadow.
   */
  buttonTextShadow?: ShadowOptions | ShadowStyle;
  /**
   * NButton border.
   */
  buttonBorder?: BorderOptions;
  /**
   * Card bottom background blur style.
   */
  bottomBackgroundBlurStyle: BlurStyle = BlurStyle.COMPONENT_ULTRA_THIN;
  /**
   * Card background color.
   */
  backgroundColor?: ResourceColor;
  /**
   * Background image.
   */
  backgroundImage?: ResourceStr;
  /**
   * ImageSize of background image.
   */
  backgroundImageSize?: ImageSize;
  /**
   * Bottom item list.
   */
  bottomItemList: BottomItem[] = [];
  /**
   * Control the button show.
   */
  buttonVisible?: boolean;
  /**
   * The auxiliary font color.
   */
  auxiliaryTextColor?: ResourceColor;
  /**
   * The start color of card.
   */
  linearStartColor?: ResourceStr;
  /**
   * The end color of card.
   */
  linearEndColor?: ResourceStr;

  constructor(bottomItemList: BottomItem[], bottomBackgroundBlurStyle: BlurStyle,
    backgroundColor?: ResourceColor,
    backgroundImage?: ResourceStr, backgroundImageSize?: ImageSize, title?: ResourceStr, titleColor?: ResourceColor,
    titleOpacity?: number | Resource, titleShadow?: ShadowOptions | ShadowStyle, secondaryText?: ResourceStr,
    secondaryTextColor?: ResourceColor, secondaryTextOpacity?: number | Resource,
    secondaryTextShadow?: ShadowOptions | ShadowStyle, logo?: ResourceStr, buttonIcon?: ResourceStr,
    buttonText?: ResourceStr, buttonTextColor?: ResourceColor, buttonTextOpacity?: number | Resource,
    buttonTextShadow?: ShadowOptions | ShadowStyle, buttonBorder?: BorderOptions, buttonVisible?: boolean,
    auxiliaryTextColor?: ResourceColor, linearStartColor?: ResourceStr, linearEndColor?: ResourceStr) {
    this.bottomItemList = bottomItemList;
    this.backgroundColor = backgroundColor;
    this.bottomBackgroundBlurStyle = bottomBackgroundBlurStyle;
    this.backgroundImage = backgroundImage;
    this.backgroundImageSize = backgroundImageSize;
    this.title = title;
    this.titleColor = titleColor;
    this.titleOpacity = titleOpacity;
    this.titleShadow = titleShadow;
    this.secondaryText = secondaryText;
    this.secondaryTextColor = secondaryTextColor;
    this.secondaryTextOpacity = secondaryTextOpacity;
    this.secondaryTextShadow = secondaryTextShadow;
    this.logo = logo;
    this.buttonIcon = buttonIcon;
    this.buttonText = buttonText;
    this.buttonTextColor = buttonTextColor;
    this.buttonTextOpacity = buttonTextOpacity;
    this.buttonTextShadow = buttonTextShadow;
    this.buttonBorder = buttonBorder;
    this.buttonVisible = buttonVisible;
    this.auxiliaryTextColor = auxiliaryTextColor;
    this.linearStartColor = linearStartColor;
    this.linearEndColor = linearEndColor;
  }
}

export interface BottomItem {
  formLinkParam?: FormLinkOptions;
  title: ResourceStr;
  icon: ResourceStr;
}