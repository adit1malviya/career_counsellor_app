// Top-level build file where you can add configuration options common to all sub-projects/modules.

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Ensure this version matches your Flutter SDK requirements
        classpath("com.android.tools.build:gradle:8.1.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.8.22")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

/**
 * Custom build directory logic to handle Windows path length limitations.
 * This moves the build folder to the root level of your project.
 */
val newBuildDir: Directory = rootProject.layout.buildDirectory
    .dir("../../build")
    .get()

rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    // Set custom build directory for each subproject (e.g., :app, :path_provider, etc.)
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    // Critical for Flutter: ensures the :app module is evaluated before its dependencies
    project.evaluationDependsOn(":app")
}

// Register the clean task to remove the custom build directory effectively
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}