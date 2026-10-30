plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.paconotgames.morph_runner"
    compileSdk = flutter.compileSdkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // ----------------------------
    // READ VALUES FROM gradle.properties
    // ----------------------------
    val keyStoreFile: String = project.property("MYAPP_UPLOAD_STORE_FILE") as String
    val alias: String = project.property("MYAPP_UPLOAD_KEY_ALIAS") as String
    val keyStorePassword: String = project.property("MYAPP_UPLOAD_STORE_PASSWORD") as String
    val password: String = project.property("MYAPP_UPLOAD_KEY_PASSWORD") as String

    // ----------------------------
    // SIGNING CONFIG FOR RELEASE
    // ----------------------------
    signingConfigs {
        create("release") {
            storeFile = file(keyStoreFile)
            storePassword = keyStorePassword
            keyAlias = alias
            keyPassword = password
        }
    }

    defaultConfig {
        applicationId = "com.paconotgames.morph_runner"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
