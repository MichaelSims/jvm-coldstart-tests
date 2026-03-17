plugins {
    java
    application
}

java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(21))
    }
}

application {
    mainClass.set("BareServer")
}

tasks.named<Jar>("jar") {
    manifest {
        attributes("Main-Class" to "BareServer")
    }
}