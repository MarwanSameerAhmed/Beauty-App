# ⚡ أوامر سريعة ومفيدة

## مرجع سريع لأوامر التطوير والنشر

---

## 🧹 التنظيف والتحديث

### تنظيف شامل
```bash
# تنظيف Flutter
flutter clean
flutter pub get

# تنظيف Android
cd android
./gradlew clean
cd ..

# تنظيف iOS
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
```

### تحديث Dependencies
```bash
# فحص packages القديمة
flutter pub outdated

# تحديث minor versions
flutter pub upgrade

# تحديث major versions
flutter pub upgrade --major-versions

# فحص vulnerabilities
flutter pub audit
```

---

## 🔨 البناء (Build)

### Android

#### Debug
```bash
flutter build apk --debug
flutter install
```

#### Release
```bash
# App Bundle (للنشر على Google Play)
flutter build appbundle --release

# APK (للاختبار فقط)
flutter build apk --release

# فحص حجم التطبيق
flutter build appbundle --analyze-size

# تقسيم حسب ABI (APKs أصغر)
flutter build apk --split-per-abi --release
```

### iOS

#### Debug
```bash
flutter build ios --debug
flutter install
```

#### Release
```bash
# بناء IPA
flutter build ios --release

# ثم في Xcode:
open ios/Runner.xcworkspace
# Product → Archive
```

---

## 🧪 الاختبار

### تشغيل على جهاز
```bash
# عرض الأجهزة المتصلة
flutter devices

# تشغيل على جهاز محدد
flutter run -d <device-id>

# تشغيل Release mode
flutter run --release

# تشغيل Profile mode (للأداء)
flutter run --profile
```

### Hot Reload & Restart
```
أثناء التشغيل:
r - Hot reload
R - Hot restart
q - إيقاف
```

---

## 🔍 الفحص والتحليل

### Linting
```bash
# تحليل الكود
flutter analyze

# إصلاح تلقائي
dart fix --apply
```

### Format
```bash
# تنسيق ملف واحد
dart format lib/main.dart

# تنسيق كل المشروع
dart format lib/
```

### Performance
```bash
# تشغيل مع profiling
flutter run --profile

# ثم في DevTools:
flutter pub global activate devtools
flutter pub global run devtools
```

### Size Analysis
```bash
# تحليل حجم APK
flutter build apk --analyze-size

# تحليل حجم AAB
flutter build appbundle --analyze-size

# تحليل تفصيلي
flutter build apk --target-platform android-arm64 --analyze-size --tree-shake-icons
```

---

## 🔥 Firebase

### إعداد Firebase
```bash
# تثبيت Firebase CLI
npm install -g firebase-tools

# تسجيل الدخول
firebase login

# ربط المشروع
firebase use beauty-app-84d57

# تهيئة Flutter مع Firebase
flutterfire configure
```

### نشر Firebase

#### Firestore Rules
```bash
firebase deploy --only firestore:rules
```

#### Cloud Functions
```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

#### Hosting (للـ web)
```bash
flutter build web --release
firebase deploy --only hosting
```

#### الكل معاً
```bash
firebase deploy
```

---

## 📱 Android Specific

### Signing

#### إنشاء Keystore
```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload \
  -storetype JKS
```

#### فحص Keystore
```bash
keytool -list -v -keystore android/app/upload-keystore.jks -alias upload
```

#### SHA-1 للـ Firebase
```bash
# Debug SHA-1
keytool -list -v -alias androiddebugkey \
  -keystore ~/.android/debug.keystore

# Release SHA-1
keytool -list -v -alias upload \
  -keystore android/app/upload-keystore.jks
```

### Gradle

#### تنظيف
```bash
cd android
./gradlew clean
```

#### بناء
```bash
./gradlew assembleRelease
./gradlew bundleRelease
```

#### فحص dependencies
```bash
./gradlew app:dependencies
```

---

## 🍎 iOS Specific

### CocoaPods

#### تثبيت/تحديث
```bash
cd ios
pod install
pod update
```

#### تنظيف
```bash
rm -rf Pods Podfile.lock
pod install --repo-update
```

### Xcode

#### فتح Workspace
```bash
open ios/Runner.xcworkspace
```

#### تنظيف من Terminal
```bash
cd ios
xcodebuild clean
```

---

## 🐛 معالجة الأخطاء الشائعة

### Android: "Execution failed for task ':app:processReleaseResources'"
```bash
flutter clean
cd android
./gradlew clean
cd ..
flutter pub get
flutter build appbundle --release
```

### iOS: "Pod install" fails
```bash
cd ios
rm -rf Pods Podfile.lock .symlinks
pod install --repo-update
cd ..
flutter clean
flutter pub get
```

### "SDK is not available"
```bash
flutter doctor -v
flutter upgrade
```

### Git conflicts في pubspec.lock
```bash
# حذف الملف وإعادة إنشائه
rm pubspec.lock
flutter pub get
```

---

## 📦 إدارة Packages

### إضافة package
```bash
flutter pub add package_name
# أو
flutter pub add package_name:^version
```

### إزالة package
```bash
flutter pub remove package_name
```

### فحص package محدد
```bash
flutter pub outdated package_name
```

---

## 🔐 App Check Debug Tokens

### Android
```bash
# الحصول على debug token
adb shell setprop debug.firebase.appcheck.debug true

# ثم شغل التطبيق، سيطبع token في console
flutter run

# بعدها أضف الـ token في Firebase Console
```

### iOS
```bash
# في main.dart أضف:
# FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);

# ثم شغل التطبيق، سيطبع token في console
flutter run
```

---

## 📊 تحليل الأداء

### Flutter Performance
```bash
# تشغيل مع performance overlay
flutter run --profile --trace-skia

# بدون checked mode
flutter run --profile --no-checked-mode-assertions
```

### Memory Profiling
```bash
# تشغيل مع memory profiling
flutter run --profile --enable-impeller

# في DevTools → Memory
```

---

## 🚀 CI/CD Commands

### GitHub Actions (مثال)
```yaml
# .github/workflows/build.yml
- name: Build Android
  run: |
    flutter clean
    flutter pub get
    flutter build appbundle --release

- name: Build iOS
  run: |
    flutter clean
    flutter pub get
    flutter build ios --release --no-codesign
```

### Fastlane (Android)
```bash
# في android/
bundle exec fastlane beta
```

### Fastlane (iOS)
```bash
# في ios/
bundle exec fastlane beta
```

---

## 📝 اختبارات مفيدة

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter drive --target=test_driver/app.dart
```

### Widget Tests
```bash
flutter test test/widget_test.dart
```

### Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## 🌐 Web Specific

### تشغيل على Web
```bash
flutter run -d chrome
flutter run -d web-server --web-port=8080
```

### بناء Web
```bash
# Production build
flutter build web --release

# مع tree shaking
flutter build web --release --tree-shake-icons

# Canvaskit renderer (أفضل أداء)
flutter build web --release --web-renderer canvaskit

# HTML renderer (حجم أصغر)
flutter build web --release --web-renderer html
```

---

## 🔄 Git Commands (مفيدة)

### قبل commit
```bash
# تأكد من formatting
dart format lib/

# تأكد من عدم وجود أخطاء
flutter analyze

# stage الملفات
git add .

# commit
git commit -m "fix: إصلاح مشكلة كذا"
```

### إنشاء release tag
```bash
# tag جديد
git tag -a v1.0.0 -m "Release version 1.0.0"

# push tag
git push origin v1.0.0
```

---

## 🎨 الأيقونات والـ Splash

### تحديث الأيقونات
```bash
flutter pub run flutter_launcher_icons:main
```

### تحديث Splash Screen
```bash
flutter pub run flutter_native_splash:create
```

---

## 📱 ADB Commands (Android)

### أوامر مفيدة
```bash
# عرض الأجهزة المتصلة
adb devices

# تثبيت APK
adb install -r app-release.apk

# حذف التطبيق
adb uninstall com.example.test_pro

# عرض logs
adb logcat | grep -i flutter

# أخذ screenshot
adb shell screencap -p /sdcard/screen.png
adb pull /sdcard/screen.png

# تسجيل فيديو
adb shell screenrecord /sdcard/demo.mp4
# اضغط Ctrl+C لإيقاف التسجيل
adb pull /sdcard/demo.mp4

# فتح app-specific storage
adb shell
run-as com.example.test_pro
cd /data/data/com.example.test_pro/databases
```

---

## 🎬 تسجيل Screenshots للمتاجر

### Android (من Emulator)
```bash
# في Android Studio:
# Tools → Device Manager → إخترالجهاز
# ثم اضغط Camera icon

# أو من command line:
adb shell screencap -p /sdcard/screen.png
adb pull /sdcard/screen.png ~/Desktop/screenshots/
```

### iOS (من Simulator)
```bash
# Cmd + S في Simulator

# أو:
xcrun simctl io booted screenshot ~/Desktop/screenshots/screenshot.png
```

---

## 🔧 الإصلاحات السريعة

### "DexArchiveMergerException"
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### "Pod install" errors
```bash
cd ios
rm -rf Pods Podfile.lock
pod cache clean --all
pod install --repo-update
```

### "License not accepted"
```bash
flutter doctor --android-licenses
```

### Firebase initialization error
```bash
flutterfire configure
# ثم اختر المشروع والـ platforms
```

---

## 📈 Monitoring في الإنتاج

### Firebase Console
- **Crashlytics:** مراقبة الأخطاء
- **Performance:** مراقبة الأداء
- **Analytics:** إحصائيات المستخدمين

### Play Console
```
اذهب إلى:
- Dashboard → للإحصائيات العامة
- Vitals → للأداء والـ Crashes
- Reviews → للتقييمات
```

### App Store Connect
```
اذهب إلى:
- App Analytics → للإحصائيات
- TestFlight → لإدارة Beta
- Crash Organizer → للأخطاء
```

---

## 💡 نصائح سريعة

### تسريع البناء (Build)
```bash
# استخدام أكثر من core
flutter build apk --release -j8

# تعطيل tree shaking (في التطوير فقط)
flutter build apk --debug --no-tree-shake-icons
```

### فحص سريع قبل commit
```bash
#!/bin/bash
# save as pre-commit-check.sh

echo "🔍 Analyzing..."
flutter analyze || exit 1

echo "🧪 Running tests..."
flutter test || exit 1

echo "✨ Formatting..."
dart format lib/

echo "✅ All checks passed!"
```

### script لبناء كل المنصات
```bash
#!/bin/bash
# save as build-all.sh

echo "🧹 Cleaning..."
flutter clean
flutter pub get

echo "📱 Building Android..."
flutter build appbundle --release

echo "🍎 Building iOS..."
flutter build ios --release

echo "🌐 Building Web..."
flutter build web --release

echo "✅ All builds complete!"
```

---

## 📞 مصادر مفيدة

### Documentation
- [Flutter Docs](https://docs.flutter.dev/)
- [Firebase Docs](https://firebase.google.com/docs)
- [Android Developers](https://developer.android.com/)
- [Apple Developer](https://developer.apple.com/)

### Communities
- [Flutter Discord](https://discord.gg/flutter)
- [Stack Overflow - Flutter](https://stackoverflow.com/questions/tagged/flutter)
- [Reddit - r/FlutterDev](https://reddit.com/r/FlutterDev)

---

**💡 نصيحة:** احفظ هذا الملف في مكان سهل الوصول، ستحتاجه كثيراً! 🚀

