import 'package:flutter/material.dart';

/// نظام متكامل للتصميم المتجاوب
/// يدعم جميع أحجام الشاشات من الموبايلات الصغيرة إلى iPad Pro
class ResponsiveHelper {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double blockSizeHorizontal;
  static late double blockSizeVertical;
  static late double safeAreaHorizontal;
  static late double safeAreaVertical;
  static late double safeBlockHorizontal;
  static late double safeBlockVertical;
  static late DeviceType deviceType;
  static late Orientation orientation;

  /// تهيئة الـ helper - يجب استدعاؤها في بداية كل build
  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    orientation = _mediaQueryData.orientation;

    // تقسيم الشاشة إلى 100 بلوك
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;

    // حساب المساحة الآمنة
    safeAreaHorizontal = _mediaQueryData.padding.left + _mediaQueryData.padding.right;
    safeAreaVertical = _mediaQueryData.padding.top + _mediaQueryData.padding.bottom;

    safeBlockHorizontal = (screenWidth - safeAreaHorizontal) / 100;
    safeBlockVertical = (screenHeight - safeAreaVertical) / 100;

    // تحديد نوع الجهاز
    deviceType = _getDeviceType();
  }

  /// تحديد نوع الجهاز بناءً على عرض الشاشة
  static DeviceType _getDeviceType() {
    if (screenWidth < 360) {
      return DeviceType.mobileSmall;
    } else if (screenWidth < 414) {
      return DeviceType.mobile;
    } else if (screenWidth < 600) {
      return DeviceType.mobileLarge;
    } else if (screenWidth < 834) {
      return DeviceType.tablet;
    } else if (screenWidth < 1024) {
      return DeviceType.tabletLarge;
    } else {
      return DeviceType.desktop;
    }
  }

  /// هل الجهاز موبايل؟
  static bool get isMobile =>
      deviceType == DeviceType.mobileSmall ||
      deviceType == DeviceType.mobile ||
      deviceType == DeviceType.mobileLarge;

  /// هل الجهاز تابلت؟
  static bool get isTablet =>
      deviceType == DeviceType.tablet || deviceType == DeviceType.tabletLarge;

  /// هل الجهاز ديسكتوب؟
  static bool get isDesktop => deviceType == DeviceType.desktop;

  /// هل الشاشة في وضع landscape؟
  static bool get isLandscape => orientation == Orientation.landscape;

  // ===== دوال حساب الأبعاد =====

  /// حساب العرض كنسبة من عرض الشاشة
  static double wp(double percentage) => screenWidth * (percentage / 100);

  /// حساب الارتفاع كنسبة من ارتفاع الشاشة
  static double hp(double percentage) => screenHeight * (percentage / 100);

  /// حساب حجم الخط المتجاوب
  static double sp(double fontSize) {
    double scaleFactor = _getScaleFactor();
    return fontSize * scaleFactor;
  }

  /// عامل التحجيم للخطوط
  static double _getScaleFactor() {
    switch (deviceType) {
      case DeviceType.mobileSmall:
        return 0.85;
      case DeviceType.mobile:
        return 1.0;
      case DeviceType.mobileLarge:
        return 1.05;
      case DeviceType.tablet:
        return 1.15;
      case DeviceType.tabletLarge:
        return 1.25;
      case DeviceType.desktop:
        return 1.35;
    }
  }

  // ===== قيم محددة للتطبيق =====

  /// ارتفاع الـ Header
  static double get headerHeight {
    switch (deviceType) {
      case DeviceType.mobileSmall:
        return 100;
      case DeviceType.mobile:
        return 110;
      case DeviceType.mobileLarge:
        return 115;
      case DeviceType.tablet:
        return 130;
      case DeviceType.tabletLarge:
        return 140;
      case DeviceType.desktop:
        return 150;
    }
  }

  /// عرض زر الأيقونات في الـ Header
  static double get headerIconsWidth {
    switch (deviceType) {
      case DeviceType.mobileSmall:
        return 90;
      case DeviceType.mobile:
        return 100;
      case DeviceType.mobileLarge:
        return 110;
      case DeviceType.tablet:
        return 130;
      case DeviceType.tabletLarge:
        return 150;
      case DeviceType.desktop:
        return 170;
    }
  }

  /// ارتفاع زر الأيقونات
  static double get headerIconsHeight {
    switch (deviceType) {
      case DeviceType.mobileSmall:
        return 44;
      case DeviceType.mobile:
        return 50;
      case DeviceType.mobileLarge:
        return 52;
      case DeviceType.tablet:
        return 58;
      case DeviceType.tabletLarge:
        return 64;
      case DeviceType.desktop:
        return 70;
    }
  }

  /// حجم الـ Avatar
  static double get avatarRadius {
    switch (deviceType) {
      case DeviceType.mobileSmall:
        return 26;
      case DeviceType.mobile:
        return 30;
      case DeviceType.mobileLarge:
        return 32;
      case DeviceType.tablet:
        return 40;
      case DeviceType.tabletLarge:
        return 45;
      case DeviceType.desktop:
        return 50;
    }
  }

  /// ارتفاع الـ Carousel
  static double get carouselHeight {
    if (isLandscape) {
      return hp(40);
    }
    switch (deviceType) {
      case DeviceType.mobileSmall:
        return 180;
      case DeviceType.mobile:
        return 220;
      case DeviceType.mobileLarge:
        return 240;
      case DeviceType.tablet:
        return 300;
      case DeviceType.tabletLarge:
        return 350;
      case DeviceType.desktop:
        return 400;
    }
  }

  /// ارتفاع الإعلانات المستطيلة
  static double get rectangleAdHeight {
    switch (deviceType) {
      case DeviceType.mobileSmall:
        return 150;
      case DeviceType.mobile:
        return 180;
      case DeviceType.mobileLarge:
        return 200;
      case DeviceType.tablet:
        return 250;
      case DeviceType.tabletLarge:
        return 300;
      case DeviceType.desktop:
        return 350;
    }
  }

  /// عدد أعمدة الإعلانات المربعة
  static int get squareAdsColumns {
    switch (deviceType) {
      case DeviceType.mobileSmall:
      case DeviceType.mobile:
      case DeviceType.mobileLarge:
        return 2;
      case DeviceType.tablet:
        return 3;
      case DeviceType.tabletLarge:
      case DeviceType.desktop:
        return 4;
    }
  }

  /// حساب عرض الإعلان المربع بناءً على عدد الأعمدة
  static double get squareAdWidth {
    int columns = squareAdsColumns;
    double totalPadding = 32 + ((columns - 1) * 10); // padding + spacing
    return (screenWidth - totalPadding) / columns;
  }

  /// ارتفاع قسم المنتجات
  static double get productSectionHeight {
    switch (deviceType) {
      case DeviceType.mobileSmall:
        return 220;
      case DeviceType.mobile:
        return 250;
      case DeviceType.mobileLarge:
        return 270;
      case DeviceType.tablet:
        return 320;
      case DeviceType.tabletLarge:
        return 360;
      case DeviceType.desktop:
        return 400;
    }
  }

  /// عرض كارت المنتج
  static double get productCardWidth {
    switch (deviceType) {
      case DeviceType.mobileSmall:
        return 150;
      case DeviceType.mobile:
        return 180;
      case DeviceType.mobileLarge:
        return 200;
      case DeviceType.tablet:
        return 220;
      case DeviceType.tabletLarge:
        return 250;
      case DeviceType.desktop:
        return 280;
    }
  }

  /// الـ Padding الأفقي العام
  static double get horizontalPadding {
    switch (deviceType) {
      case DeviceType.mobileSmall:
        return 12;
      case DeviceType.mobile:
        return 16;
      case DeviceType.mobileLarge:
        return 18;
      case DeviceType.tablet:
        return 24;
      case DeviceType.tabletLarge:
        return 32;
      case DeviceType.desktop:
        return 40;
    }
  }

  /// حجم خط العناوين الرئيسية
  static double get titleFontSize {
    switch (deviceType) {
      case DeviceType.mobileSmall:
        return 18;
      case DeviceType.mobile:
        return 22;
      case DeviceType.mobileLarge:
        return 24;
      case DeviceType.tablet:
        return 28;
      case DeviceType.tabletLarge:
        return 32;
      case DeviceType.desktop:
        return 36;
    }
  }

  /// حجم خط النصوص العادية
  static double get bodyFontSize {
    switch (deviceType) {
      case DeviceType.mobileSmall:
        return 13;
      case DeviceType.mobile:
        return 16;
      case DeviceType.mobileLarge:
        return 17;
      case DeviceType.tablet:
        return 18;
      case DeviceType.tabletLarge:
        return 20;
      case DeviceType.desktop:
        return 22;
    }
  }

  /// حجم خط النصوص الصغيرة
  static double get smallFontSize {
    switch (deviceType) {
      case DeviceType.mobileSmall:
        return 11;
      case DeviceType.mobile:
        return 12;
      case DeviceType.mobileLarge:
        return 13;
      case DeviceType.tablet:
        return 14;
      case DeviceType.tabletLarge:
        return 15;
      case DeviceType.desktop:
        return 16;
    }
  }

  /// حجم أيقونات الأزرار
  static double get iconSize {
    switch (deviceType) {
      case DeviceType.mobileSmall:
        return 20;
      case DeviceType.mobile:
        return 22;
      case DeviceType.mobileLarge:
        return 24;
      case DeviceType.tablet:
        return 28;
      case DeviceType.tabletLarge:
        return 32;
      case DeviceType.desktop:
        return 36;
    }
  }

  /// نصف قطر الزوايا (Border Radius)
  static double get borderRadius {
    switch (deviceType) {
      case DeviceType.mobileSmall:
        return 12;
      case DeviceType.mobile:
        return 15;
      case DeviceType.mobileLarge:
        return 16;
      case DeviceType.tablet:
        return 18;
      case DeviceType.tabletLarge:
        return 20;
      case DeviceType.desktop:
        return 24;
    }
  }

  /// مساحة الـ spacing العمودي
  static double get verticalSpacing {
    switch (deviceType) {
      case DeviceType.mobileSmall:
        return 8;
      case DeviceType.mobile:
        return 10;
      case DeviceType.mobileLarge:
        return 12;
      case DeviceType.tablet:
        return 16;
      case DeviceType.tabletLarge:
        return 20;
      case DeviceType.desktop:
        return 24;
    }
  }

  /// الـ viewport fraction للـ carousel
  static double get carouselViewportFraction {
    switch (deviceType) {
      case DeviceType.mobileSmall:
        return 0.92;
      case DeviceType.mobile:
        return 0.94;
      case DeviceType.mobileLarge:
        return 0.9;
      case DeviceType.tablet:
        return 0.75;
      case DeviceType.tabletLarge:
        return 0.65;
      case DeviceType.desktop:
        return 0.55;
    }
  }
}

/// أنواع الأجهزة المدعومة
enum DeviceType {
  mobileSmall,  // أقل من 360dp (مثل iPhone SE)
  mobile,       // 360-414dp (مثل iPhone 14)
  mobileLarge,  // 414-600dp (مثل iPhone 14 Pro Max)
  tablet,       // 600-834dp (مثل iPad Mini)
  tabletLarge,  // 834-1024dp (مثل iPad Air/Pro 11")
  desktop,      // أكبر من 1024dp (مثل iPad Pro 12.9")
}

/// Extension للوصول السهل من BuildContext
extension ResponsiveExtension on BuildContext {
  /// تهيئة وإرجاع الـ helper
  ResponsiveHelper get responsive {
    ResponsiveHelper.init(this);
    return ResponsiveHelper();
  }

  /// اختصارات للوصول السريع
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  bool get isMobile => ResponsiveHelper.isMobile;
  bool get isTablet => ResponsiveHelper.isTablet;
  bool get isDesktop => ResponsiveHelper.isDesktop;
  bool get isLandscape => ResponsiveHelper.isLandscape;
}
