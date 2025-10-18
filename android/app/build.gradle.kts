import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 1. Property Loading Block (Kotlin DSL syntax is required for .kts files)
val keystoreProperties = Properties()
// Locate key.properties in the project's root 'android/' folder
val keystorePropertiesFile = rootProject.file("key.properties") 

// Flag to track if we successfully loaded the release key properties
val isSigningAvailable: Boolean = if (keystorePropertiesFile.exists()) {
    // Correct Kotlin DSL method for reading properties file securely
    keystorePropertiesFile.inputStream().use { 
        keystoreProperties.load(it) 
    }
    true // Signing properties were loaded successfully
} else {
    println("WARNING: key.properties file not found. Release build will use debug signing.")
    false // Signing properties were not loaded
}

android {
    namespace = "com.example.jeepmiyabe"
    // Use .toInt() when reading these properties in Kotlin DSL
    compileSdk = flutter.compileSdkVersion.toInt()
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // 2. SIGNING CONFIGS MUST BE DIRECTLY UNDER 'android'
    signingConfigs {
        // Define the 'release' signing config, but only populate it if keys were loaded
        create("release") {
            if (isSigningAvailable) {
                // Use explicit assignment (=) and getProperty("key")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            } 
            // NOTE: No 'else' block or 'signingConfig' here!
        }
    }

    defaultConfig {
        applicationId = "com.example.jeepmiyabe"
        // Use .toInt() when reading these properties in Kotlin DSL
        minSdk = flutter.minSdkVersion.toInt() 
        targetSdk = flutter.targetSdkVersion.toInt()
        versionCode = flutter.versionCode.toInt()
        versionName = flutter.versionName

        // Kotlin DSL syntax for manifestPlaceholders - reads GOOGLE_MAPS_API_KEY from local.properties
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = project.findProperty("GOOGLE_MAPS_API_KEY") as String? ?: ""
    }


    // 3. BUILD TYPES BLOCK
    buildTypes {
        release {
            // *** CORRECT LOCATION FOR CONDITIONAL SIGNING LOGIC ***
            if (isSigningAvailable) {
                // Use the custom release key if properties were successfully loaded
                signingConfig = signingConfigs.getByName("release")
            } else {
                // Fallback to debug signing if key.properties was missing
                signingConfig = signingConfigs.getByName("debug")
            }

            // Use 'is' prefix and explicit assignment for boolean properties
            isMinifyEnabled = true
            isShrinkResources = true 
            // Use parentheses for function calls
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"), 
                "proguard-rules.pro"
            )
        }
        
        debug {
            // Keep the 'debug' configuration default
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
