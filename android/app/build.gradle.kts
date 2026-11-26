plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "ir.kianex.kianex_pts50n1_app"
    compileSdk = flutter.compileSdkVersion
    // ndkVersion intentionally not set — the app and every plugin are pure
    // Java/Kotlin, so no NDK is required to build or run.

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "ir.kianex.kianex_pts50n1_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // The APK is signed with the debug keys so that `flutter build apk`
            // and the GitHub Actions artifact are installable right away.
            // For store distribution, create a proper keystore and switch to
            // a release signing config.
            signingConfig = signingConfigs.getByName("debug")
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
