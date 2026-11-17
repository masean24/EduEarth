# Aturan R8/ProGuard minimal untuk menjaga integrasi Flutter & Android plugins.
# Jangan memakai `-keep class io.flutter.embedding.** { *; }` karena menjaga
# PlayStoreDeferredComponentManager yang bergantung pada Play Core SDK.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class com.eduearth.app.** { *; }

-dontwarn com.google.android.play.core.**
-dontwarn javax.annotation.**
-dontwarn org.codehaus.mojo.animal_sniffer.**
