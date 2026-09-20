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
    
    afterEvaluate {
        project.extensions.findByName("android")?.let { ext ->
            try {
                // Use reflection to avoid class cast issues if AGP classes are not on the script classpath
                val setCompileSdkVersionMethod = ext.javaClass.getMethod("setCompileSdkVersion", Int::class.java)
                setCompileSdkVersionMethod.invoke(ext, 36)
            } catch(e: Exception) {
                // Ignore if method not found
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
