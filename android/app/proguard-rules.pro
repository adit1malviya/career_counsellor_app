# 1. SLF4J Logging (Fixes the StaticLoggerBinder error)
-dontwarn org.slf4j.**
-keep class org.slf4j.** { *; }

# 2. Ktor / Java Management
-dontwarn java.lang.management.**
-keep class java.lang.management.** { *; }

# 3. BouncyCastle (Security/Cryptography)
-dontwarn org.bouncycastle.**
-keep class org.bouncycastle.** { *; }

# 4. OkHttp and Network Platforms
-dontwarn okhttp3.internal.platform.**
-keep class okhttp3.internal.platform.** { *; }

# 5. Standard Flutter / General rules
-dontwarn org.chromium.net.**
-keep class org.chromium.net.** { *; }
-dontwarn org.conscrypt.**
-keep class org.conscrypt.** { *; }
-dontwarn org.openjsse.**
-keep class org.openjsse.** { *; }

# 6. General R8/ProGuard configuration
-ignorewarnings
-keepattributes Signature
-keepattributes *Annotation*