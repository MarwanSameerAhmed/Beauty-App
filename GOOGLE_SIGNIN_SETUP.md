# إعداد تسجيل الدخول بـ Google للويب

## المشكلة الحالية
تسجيل الدخول بـ Google لا يعمل في الويب لأنه يحتاج إعداد Web Client ID في Google Cloud Console.

## خطوات الحل

### 1. الذهاب إلى Google Cloud Console
- اذهب إلى: https://console.cloud.google.com/
- اختر المشروع: `beauty-app-84d57`

### 2. إنشاء Web Client ID
1. اذهب إلى **APIs & Services** > **Credentials**
2. اضغط **Create Credentials** > **OAuth 2.0 Client IDs**
3. اختر **Web application**
4. أضف **Authorized JavaScript origins**:
   - `http://localhost:3000` (للتطوير)
   - `https://beauty-app-84d57.web.app` (للإنتاج)
   - `https://beauty-app-84d57.firebaseapp.com` (للإنتاج)

### 3. تحديث الكود
1. انسخ الـ Client ID الجديد
2. افتح ملف: `lib/config/web_config.dart`
3. استبدل `REPLACE_WITH_ACTUAL_WEB_CLIENT_ID` بالـ Client ID الحقيقي

### 4. إعادة البناء والنشر
```bash
flutter clean
flutter pub get
flutter build web --release --no-tree-shake-icons
firebase deploy --only hosting
```

## ملاحظات مهمة
- الـ Client ID الحالي وهمي ولن يعمل
- يجب إنشاء Client ID حقيقي من Google Cloud Console
- تأكد من إضافة جميع النطاقات المطلوبة في Authorized JavaScript origins

## ملفات تم تعديلها
- `lib/controller/Auth_Service.dart` - تحديث إعدادات Google Sign-In
- `lib/config/web_config.dart` - ملف إعدادات الويب الجديد
- `web/index.html` - إضافة Google Sign-In SDK

## الميزات المضافة
- دعم الويب لـ Google Sign-In
- معالجة أفضل للأخطاء
- تخطي FCM token للويب
- رسائل خطأ واضحة باللغة العربية
