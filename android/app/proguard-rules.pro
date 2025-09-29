# Agora RTC SDK
-keep class io.agora.** { *; }
-keepclassmembers class io.agora.** { *; }
-dontwarn io.agora.**

# Flutter plugins
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.engine.plugins.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase (if used)
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# HTTP (for token fetching)
-keep class com.squareup.okhttp.** { *; }
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**

# Prevent R8 from removing plugin methods
-if class * implements io.flutter.embedding.engine.plugins.FlutterPlugin
-keep,allowshrinking,allowobfuscation class <1>

# Preserve shared_preferences and Pigeon classes
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class dev.flutter.pigeon.** { *; }
-dontwarn io.flutter.plugins.sharedpreferences.**
-dontwarn dev.flutter.pigeon.**

# Preserve permission_handler classes
-keep class com.baseflow.permissionhandler.** { *; }
-keep class com.baseflow.** { *; }
-dontwarn com.baseflow.permissionhandler.**
-dontwarn com.baseflow.**

# Preserve Flutter plugin platform channels
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.plugin.**
-dontwarn io.flutter.embedding.**

# Preserve Android SharedPreferences
-keep class android.content.SharedPreferences { *; }
-keep class android.content.SharedPreferences$Editor { *; }
-dontwarn android.content.SharedPreferences**

# Preserve AndroidX and Google classes
-keep class androidx.core.content.** { *; }
-keep class com.google.android.gms.common.** { *; }
-dontwarn androidx.core.content.**
-dontwarn com.google.android.gms.common.**

# Preserve annotations, interfaces, and method signatures
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keep interface * { *; }