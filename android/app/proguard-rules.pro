# Flutter's default rules.
-dontwarn io.flutter.embedding.android.**
-keep class io.flutter.embedding.android.** { *; }

# Rules for smart_auth plugin / R8 missing classes error
-dontwarn com.google.android.gms.auth.api.credentials.**
-keep class com.google.android.gms.auth.api.credentials.** { *; }

# Rules for Google Play Core library (deferred components)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; }

# Firebase Crashlytics
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
-keep class com.google.firebase.crashlytics.** { *; }
-dontwarn com.google.firebase.crashlytics.**

# Firebase Auth & Google Sign-In
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.firebase.auth.** { *; }
-dontwarn com.google.android.gms.auth.**

# Firebase Cloud Firestore
-keep class com.google.firebase.firestore.** { *; }

# Firebase Messaging
-keep class com.google.firebase.messaging.** { *; }

# General Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Keep Flutter-related classes
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**
