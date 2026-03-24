allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Patch: AGP 8.x exige namespace em todos os módulos.
// isar_flutter_libs 3.x não declara namespace no próprio build.gradle.
subprojects {
    afterEvaluate {
        // Fix namespace ausente + JVM target inconsistente para todos os plugins antigos
        project.extensions.findByType<com.android.build.gradle.LibraryExtension>()?.apply {
            if (namespace == null) {
                namespace = project.group.toString().ifEmpty {
                    "com.${project.name.replace("-", "_").replace(".", "_")}"
                }
            }
            // isar_flutter_libs usa android:attr/lStar que requer compileSdk >= 31
            if (compileSdk == null || compileSdk!! < 35) {
                compileSdk = 35
            }
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions.jvmTarget.set(
                org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
            )
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
