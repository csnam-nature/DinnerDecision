pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.3.1" apply false
    id("org.jetbrains.kotlin.android") version "2.4.20" apply false
    // Firebase (6단계). 버전은 firebase_core가 권하는 값 (firebase_core pubspec: google_services_gradle_plugin_version)
    id("com.google.gms.google-services") version "4.4.4" apply false
    // Crashlytics가 빌드 ID를 넣는 플러그인 (firebase_core pubspec: crashlytics_gradle_plugin_version)
    id("com.google.firebase.crashlytics") version "3.0.7" apply false
}

include(":app")
