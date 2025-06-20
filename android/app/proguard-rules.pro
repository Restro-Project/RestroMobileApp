# Flutter specific ProGuard rules.
# This file is automatically generated by the Flutter tool.
# Do not modify.

# Keep all unreferenced classes, fields, and methods that are annotated with @Keep.
-keep,allowshrinking class * {
    @androidx.annotation.Keep <fields>;
    @androidx.annotation.Keep <methods>;
    @androidx.annotation.Keep <init>(...);
}
-keep,allowshrinking class * {
    @com.google.firebase.database.annotations.Keep <fields>;
    @com.google.firebase.database.annotations.Keep <methods>;
    @com.google.firebase.database.annotations.Keep <init>(...);
}
-keep,allowshrinking class * {
    @com.google.android.gms.common.annotation.KeepForSdk <fields>;
    @com.google.android.gms.common.annotation.KeepForSdk <methods>;
    @com.google.gms.common.annotation.KeepForSdk <init>(...);
}

# Add these for TensorFlow Lite and ML Kit
-dontwarn org.tensorflow.lite.**
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-keep class org.tensorflow.lite.support.** { *; }
-keep class org.tensorflow.lite.schema.** { *; }
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; } # Penting untuk Google Play Services/ML Kit

# If you use `tflite_flutter` with GPU delegate, these might be necessary
-keep class org.tensorflow.lite.DataType { *; }
-keep class org.tensorflow.lite.Tensor { *; }
-keep class org.tensorflow.lite.Interpreter { *; }
-keep class org.tensorflow.lite.NativeInterpreterWrapper { *; }
-keep class org.tensorflow.lite.nnapi.** { *; }
-keep class org.tensorflow.lite.examples.classification.tflite.** { *; }

# For the GpuDelegate itself (INI SANGAT PENTING UNTUK ERROR ANDA)
-keep class org.tensorflow.lite.gpu.GpuDelegate { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory$Options { *; }

# Untuk memastikan semua Enum yang digunakan oleh TFLite/ML Kit tidak dihilangkan
-keep enum org.tensorflow.lite.** { *; }
-keep enum com.google.mlkit.** { *; }

# Aturan umum lainnya yang sering membantu
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes Exceptions
-keepattributes SourceFile,LineNumberTable

# Jika Anda melihat error lain yang menyebutkan `reflect` atau `native`, tambahkan:
-keep class sun.misc.Unsafe { *; }
-keep class java.lang.reflect.** { *; }
-keep class com.google.protobuf.** { *; } # Jika ada dependensi protobuf