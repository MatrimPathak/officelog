import java.util.Properties
import java.io.FileInputStream
import java.io.File

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Load keystore properties from keystore.properties file
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("keystore.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Automatic version calculation from pubspec.yaml
fun getVersionFromPubspec(): Pair<String, Int> {
    val pubspecFile = File(rootProject.projectDir.parent, "pubspec.yaml")
    val pubspecContent = pubspecFile.readText()
    
    // Extract version line (e.g., "version: 1.2.3+4")
    val versionRegex = Regex("version:\\s*([0-9]+)\\.([0-9]+)\\.([0-9]+)(?:\\+([0-9]+))?")
    val matchResult = versionRegex.find(pubspecContent)
        ?: throw GradleException("Could not find version in pubspec.yaml")
    
    val major = matchResult.groupValues[1].toInt()
    val minor = matchResult.groupValues[2].toInt()
    val patch = matchResult.groupValues[3].toInt()
    
    // Create semantic version name (without build number)
    val versionName = "$major.$minor.$patch"
    
    // Calculate versionCode using formula: (major * 10000) + (minor * 100) + patch
    // This ensures versionCode always increases with semantic versions
    val versionCode = (major * 10000) + (minor * 100) + patch
    
    println("📱 Auto-calculated version: $versionName (code: $versionCode)")
    
    return Pair(versionName, versionCode)
}

val (calculatedVersionName, calculatedVersionCode) = getVersionFromPubspec()

android {
    namespace = "com.matrimpathak.attendence_flutter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }


    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String? ?: ""
            keyPassword = keystoreProperties["keyPassword"] as String? ?: ""
            storeFile = file("../" + (keystoreProperties["storeFile"] as String? ?: ""))
            storePassword = keystoreProperties["storePassword"] as String? ?: ""
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.matrimpathak.attendence_flutter"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        
        // Use auto-calculated version from pubspec.yaml semantic version
        versionCode = calculatedVersionCode
        versionName = calculatedVersionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
