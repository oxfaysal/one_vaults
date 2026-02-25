allprojects {
    repositories {
        google()
        mavenCentral()
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


subprojects {
    project.configurations.all {
        resolutionStrategy.eachDependency {
            // এই ব্লকটি খালি রাখতে পারেন অথবা প্রয়োজনে ডিপেন্ডেন্সি ফোর্স করতে পারেন
        }
    }

    // Namespace ফোর্স করার নতুন এবং সেফ পদ্ধতি
    plugins.withType<com.android.build.gradle.BasePlugin> {
        val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
        if (android.namespace == null) {
            android.namespace = "dev.isar.isar_flutter_libs"
        }
    }
}