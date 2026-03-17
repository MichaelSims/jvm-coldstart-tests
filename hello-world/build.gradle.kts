plugins {
    kotlin("jvm") version "2.3.0"
    application
}

repositories {
    mavenCentral()
}

application {
    mainClass.set("MainKt")
}

tasks.named<Jar>("jar") {
    manifest {
        attributes("Main-Class" to "MainKt")
    }
    duplicatesStrategy = DuplicatesStrategy.EXCLUDE
    from(configurations.runtimeClasspath.get().map { if (it.isDirectory) it else zipTree(it) })
}
