import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(FileInputStream(localPropertiesFile))
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode")
val flutterVersionName = localProperties.getProperty("flutter.versionName")

android {
    namespace = "ru.dema.futrat" // Убедись, что это совпадает с package в AndroidManifest.xml
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    }

    defaultConfig {
        applicationId = "ru.dema.futrat" // Твой ID приложения
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutterVersionCode?.toIntOrNull() ?: 1
        versionName = flutterVersionName ?: "1.0"
    }

    signingConfigs {
        create("release") {
            keyAlias = "upload"
            keyPassword = "q1w2e3r4t5y6" // <-- ВСТАВЬ СВОЙ ПАРОЛЬ ОТ КЛЮЧА
            storeFile = file("upload-keystore.jks")
            storePassword = "q1w2e3r4t5y6" // <-- ВСТАВЬ СВОЙ ПАРОЛЬ ОТ КЛЮЧА
        }
    }

    buildTypes {
        getByName("release") {
            // В Kotlin DSL доступ к signingConfigs делается так:
            signingConfig = signingConfigs.getByName("release")
            
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}