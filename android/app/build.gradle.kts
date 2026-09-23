import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// key.properties는 git에 안 올라감(.gitignore) — 없으면(CI, 다른 팀원 로컬 등) release도
// debug 키로 조용히 빌드되도록 폴백.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    namespace = "kr.nadeulplan.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Play Console 앱 항목이 com.napl.nadeulplan으로 먼저 생성돼 있어서(변경 불가)
        // 맞춤. namespace(kr.nadeulplan.app)는 코드/Firebase 기존 kr.nadeulplan.app
        // 등록과 무관하게 그대로 둬도 됨 — applicationId만 실제 배포 식별자.
        applicationId = "com.napl.nadeulplan"
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
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                // key.properties가 없는 환경(CI/다른 팀원)에서는 debug 키로 폴백해서
                // 빌드 자체는 깨지지 않게 함 — 실제 배포용 appbundle엔 안 씀. 조용히
                // 넘어가면 그 사실을 놓치기 쉬워서 눈에 띄게 경고만 남긴다.
                logger.warn("[nadeulplan] key.properties 없음 — release가 debug 서명으로 빌드됩니다. 이 결과물은 Play 스토어에 업로드할 수 없습니다.")
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

configurations.all {
    resolutionStrategy {
        // play-services-ads-api(AdMob)가 androidx.work:work-runtime을 2.7.0으로 고정해서
        // 물고 오는데, 그 버전(Room 2.2.5, reflection으로 _Impl 클래스를 찾음)이 R8 full
        // mode와 안 맞아 릴리스 빌드가 시작 즉시 크래시했다(RuntimeException: Failed to
        // create an instance of androidx.work.impl.WorkDatabase). 예전엔
        // android.enableR8.fullMode=false로 우회했는데, 최신으로 강제 승격해서 근본 해결함.
        force("androidx.work:work-runtime:2.11.2")
    }
}

flutter {
    source = "../.."
}
