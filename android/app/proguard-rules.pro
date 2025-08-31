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
