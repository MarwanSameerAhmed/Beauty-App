# إصلاح مشكلة Google Sign-In على iOS

## المشكلة
عند الضغط على زر تسجيل الدخول بـ Google على iPhone، كان التطبيق يخرج فوراً (crash) بينما يعمل بشكل ممتاز على Android.

## السبب
كان ملف `AppDelegate.swift` يفتقد معالجة URL callbacks المطلوبة لـ Google Sign-In. عندما يعيد Google توجيه المستخدم إلى التطبيق بعد تسجيل الدخول، يحتاج iOS إلى معالج URL لاستقبال هذه الاستجابة.

## الإصلاحات المطبقة

### 1. إضافة معالج URL في AppDelegate.swift
تم إضافة الدالة `application(_:open:options:)` لمعالجة URL callbacks من Google Sign-In:

```swift
override func application(
  _ app: UIApplication,
  open url: URL,
  options: [UIApplication.OpenURLOptionsKey : Any] = [:]
) -> Bool {
  // Handle Google Sign-In URL
  if GIDSignIn.sharedInstance.handle(url) {
    return true
  }
  // Let Flutter handle other URLs
  return super.application(app, open: url, options: options)
}
```

### 2. تحسين معالجة الأخطاء في Auth_Service.dart
تم تحسين معالجة `signOut` لتجنب الأخطاء عند عدم وجود جلسة سابقة:

```dart
if (!kIsWeb) {
  try {
    await _googleSignIn.signOut();
  } catch (e) {
    // Ignore sign out errors (e.g., if no previous session exists)
    AppLogger.debug('Sign out before sign in failed (this is OK)', tag: 'AUTH');
  }
}
```

## الملفات المعدلة
1. `ios/Runner/AppDelegate.swift` - إضافة معالج URL
2. `lib/controller/Auth_Service.dart` - تحسين معالجة الأخطاء

## الخطوات التالية

### لإصلاح المشكلة في TestFlight:

1. **إعادة بناء التطبيق:**
   ```bash
   flutter clean
   flutter pub get
   cd ios
   pod install
   cd ..
   flutter build ios --release
   ```

2. **رفع النسخة الجديدة إلى TestFlight:**
   - افتح Xcode
   - Archive التطبيق
   - ارفع النسخة الجديدة إلى App Store Connect
   - وزعها عبر TestFlight

### للاختبار المحلي:
```bash
flutter run -d <device-id>
```

## التحقق من الإعدادات

تم التحقق من:
- ✅ URL Scheme في `Info.plist` يطابق `REVERSED_CLIENT_ID` من `GoogleService-Info.plist`
- ✅ `GoogleService-Info.plist` موجود ومضبوط بشكل صحيح
- ✅ `CFBundleURLTypes` مضبوط في `Info.plist`

## ملاحظات مهمة
- يجب إعادة بناء التطبيق بالكامل بعد هذه التغييرات
- التغييرات في `AppDelegate.swift` تتطلب إعادة بناء native iOS code
- تأكد من أن `GoogleService-Info.plist` محدث في مشروع Xcode

## إذا استمرت المشكلة
1. تحقق من سجلات Xcode Console للأخطاء
2. تأكد من أن Bundle ID في Xcode يطابق `com.glamify.beautyapp`
3. تحقق من أن `GoogleService-Info.plist` مضاف إلى Xcode project بشكل صحيح
4. تأكد من أن جميع CocoaPods dependencies مثبتة: `cd ios && pod install`

