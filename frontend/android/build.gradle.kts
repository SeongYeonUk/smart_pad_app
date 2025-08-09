// 이 파일의 맨 위에 있는 plugins { ... } 블록은 그대로 유지합니다.
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// 이 함수는 그대로 유지합니다.
fun localProperties(): Properties {
    val localPropertiesFile = rootProject.file("local.properties")
    val properties = Properties()
    if (localPropertiesFile.exists()) {
        properties.load(localPropertiesFile.inputStream())
    }
    return properties
}

// flutter.compileSdkVersion 같은 변수를 읽어옵니다.
val flutterVersionCode: String by localProperties()
val flutterVersionName: String by localProperties()
val compileSdkVersion: String by localProperties()
val minSdkVersion: String by localProperties()
val targetSdkVersion: String by localProperties()


// --- ▼▼▼ 바로 이 블록을 추가하거나 수정하세요 ▼▼▼ ---
android {
    // 앱의 고유한 패키지 이름입니다.
    namespace = "com.example.smart_pad_app"

    // 컴파일에 사용할 안드로이드 SDK 버전입니다.
    compileSdk = compileSdkVersion.toInt()

    // [핵심] NDK 버전을 명시적으로 지정합니다.
    ndkVersion = "27.0.12077973"

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    }

    defaultConfig {
        // 앱의 최종적인 ID입니다.
        applicationId = "com.example.smart_pad_app"
        // 앱이 지원하는 최소 안드로이드 버전입니다.
        minSdk = minSdkVersion.toInt()
        // 앱이 타겟으로 하는 안드로이드 버전입니다.
        targetSdk = targetSdkVersion.toInt()
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
    }

    signingConfigs {
        getByName("debug") {
            // 디버그 서명 설정
        }
    }

    buildTypes {
        getByName("release") {
            // TODO: Add your own signing config for the release build.
            // See https://docs.flutter.dev/deployment/android#signing-the-app
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}
// --- ▲▲▲ 여기까지 추가/수정 ▲▲▲ ---


dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7:1.8.22")
    // 여기에 다른 의존성들이 있을 수 있습니다.
}
