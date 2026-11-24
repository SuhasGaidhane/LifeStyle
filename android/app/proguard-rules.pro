# Razorpay
-keepattributes *Annotation*
-dontwarn com.razorpay.**
-keep class com.razorpay.** { *; }
-optimizations !method/inlining/*
-keepclasseswithmembers class * {
  public void onPayment*(...);
}
# Razorpay uses ProGuard annotations
-keep class proguard.annotation.Keep
-keep class proguard.annotation.KeepClassMembers
-keep @proguard.annotation.Keep class * { *; }
-keepclassmembers class * {
  @proguard.annotation.Keep *;
}
