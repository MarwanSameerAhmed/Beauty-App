## ============================================================
## Glamify - ProGuard/R8 Rules
## قواعد شاملة لمنع R8 من حذف الأكواد الضرورية
## ============================================================

## ========================
## Flutter Engine (أساسي)
## ========================
-dontwarn io.flutter.embedding.android.**
-keep class io.flutter.embedding.android.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

## ========================
## Firebase Core
## ========================
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

## ========================
## Firebase Auth & Google Sign-In
## ========================
-keep class com.google.firebase.auth.** { *; }
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.auth.api.credentials.** { *; }
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep class com.google.android.gms.common.** { *; }
-dontwarn com.google.android.gms.auth.**
-dontwarn com.google.android.gms.common.**

## ========================
## Firebase Cloud Firestore
## ========================
-keep class com.google.firebase.firestore.** { *; }
-dontwarn com.google.firebase.firestore.**
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**

## ========================
## Firebase Storage
## ========================
-keep class com.google.firebase.storage.** { *; }
-dontwarn com.google.firebase.storage.**

## ========================
## Firebase Messaging (FCM)
## ========================
-keep class com.google.firebase.messaging.** { *; }
-dontwarn com.google.firebase.messaging.**

## ========================
## Firebase Crashlytics
## ========================
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
-keep class com.google.firebase.crashlytics.** { *; }
-dontwarn com.google.firebase.crashlytics.**

## ========================
## Firebase App Check
## ========================
-keep class com.google.firebase.appcheck.** { *; }
-dontwarn com.google.firebase.appcheck.**
-keep class com.google.android.play.core.integrity.** { *; }
-dontwarn com.google.android.play.core.integrity.**

## ========================
## Firebase Remote Config
## ========================
-keep class com.google.firebase.remoteconfig.** { *; }
-dontwarn com.google.firebase.remoteconfig.**
-keep class io.flutter.plugins.firebase.firebaseremoteconfig.** { *; }

## ========================
## Google Play Core (Play Integrity, Deferred Components)
## ========================
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; }

## ========================
## Google Sign-In
## ========================
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep class com.google.android.gms.auth.api.identity.** { *; }

## ========================
## Sign In With Apple
## ========================
-keep class com.aboutyou.dart_packages.sign_in_with_apple.** { *; }
-dontwarn com.aboutyou.dart_packages.sign_in_with_apple.**

## ========================
## Smart Auth (used by pinput)
## ========================
-keep class fman.ge.smart_auth.** { *; }
-dontwarn fman.ge.smart_auth.**
-dontwarn com.google.android.gms.auth.api.credentials.**

## ========================
## Connectivity Plus
## ========================
-keep class dev.fluttercommunity.plus.connectivity.** { *; }
-dontwarn dev.fluttercommunity.plus.connectivity.**

## ========================
## Flutter Local Notifications
## ========================
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**

## ========================
## Image Picker
## ========================
-keep class io.flutter.plugins.imagepicker.** { *; }
-dontwarn io.flutter.plugins.imagepicker.**

## ========================
## Flutter Image Compress
## ========================
-keep class com.pnikosis.materialishprogress.** { *; }
-keep class net.bither.** { *; }
-dontwarn net.bither.**

## ========================
## URL Launcher
## ========================
-keep class io.flutter.plugins.urllauncher.** { *; }
-dontwarn io.flutter.plugins.urllauncher.**

## ========================
## Share Plus
## ========================
-keep class dev.fluttercommunity.plus.share.** { *; }
-dontwarn dev.fluttercommunity.plus.share.**

## ========================
## Path Provider
## ========================
-keep class io.flutter.plugins.pathprovider.** { *; }
-dontwarn io.flutter.plugins.pathprovider.**

## ========================
## File Picker
## ========================
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-dontwarn com.mr.flutter.plugin.filepicker.**

## ========================
## Printing / PDF
## ========================
-keep class net.nfet.flutter.printing.** { *; }
-dontwarn net.nfet.flutter.printing.**

## ========================
## Shared Preferences
## ========================
-keep class io.flutter.plugins.sharedpreferences.** { *; }

## ========================
## Kotlin & AndroidX
## ========================
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
-dontwarn kotlin.**
-dontwarn kotlinx.**
-keep class androidx.** { *; }
-dontwarn androidx.**

## ========================
## OkHttp & Okio (used by Firebase internally)
## ========================
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

## ========================
## General Rules
## ========================
# Keep annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Keep serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelable
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# Keep R classes
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Don't warn about missing optional dependencies
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-dontwarn org.codehaus.**
