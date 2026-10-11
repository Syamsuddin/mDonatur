import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Kunci tanda tangan rilis: android/key.properties (tidak di-commit, docs/20 no. 14) menunjuk ke keystore
// di luar repo. Tanpa berkas itu, misalnya di repo publik, build rilis memakai kunci debug.
val kunciRilis = Properties().apply {
    rootProject.file("key.properties").takeIf { it.exists() }?.inputStream()?.use { load(it) }
}

android {
    namespace = "com.kapuhmadani.mdonator"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Tetap (docs/12_PROJECT_STRUCTURE.md); mengubahnya setelah APK dibagikan butuh gerbang docs/22.
        applicationId = "com.kapuhmadani.mdonator"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (!kunciRilis.isEmpty) {
            create("rilis") {
                storeFile = file(kunciRilis.getProperty("storeFile"))
                storePassword = kunciRilis.getProperty("storePassword")
                keyAlias = kunciRilis.getProperty("keyAlias")
                keyPassword = kunciRilis.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Membagikan APK tetap butuh gerbang pemilik (docs/22_CHANGE_POLICY.md).
            signingConfig = signingConfigs.findByName("rilis") ?: signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
