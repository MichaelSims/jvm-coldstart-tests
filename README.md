# JVM Cold Start Benchmarks

A minimal test suite for measuring JVM cold start overhead in CLI applications and server startup.

## Projects

- **hello-world** — Bare Kotlin `println("Hello, World!")`. Measures the JVM bootstrap floor with no frameworks.
- **clikt-hello** — Hello world using [Clikt](https://ajalt.github.io/clikt/) 5.1.0. Measures the overhead of a
  modern, lightweight CLI framework on top of the JVM baseline.
- **bare-server** — Minimal HTTP server using only `com.sun.net.httpserver.HttpServer` (built into the JDK, zero
  dependencies). Measures the JVM baseline for serving HTTP, without any framework overhead.

All projects use Gradle 8.10.2. The Kotlin projects use Kotlin 2.3.0.

## Prerequisites

- **Java 21+** — required. The `bare-server` project uses a Java 21 toolchain and will fail to compile on older
  versions. The Kotlin projects will also download a JDK 21 toolchain via Gradle if one isn't available.
- [hyperfine](https://github.com/sharkdp/hyperfine) (`brew install hyperfine`)

## Usage

Run all benchmarks:

```bash
./benchmark.sh
```

Or build and measure individually:

```bash
cd hello-world && ./gradlew jar
hyperfine 'java -jar build/libs/hello-world.jar'

cd ../clikt-hello && ./gradlew jar
hyperfine 'java -jar build/libs/clikt-hello.jar'
```

To measure a server's time to first HTTP response:

```bash
# Included bare-server
cd bare-server && ./gradlew jar
./time-to-ready.sh -jar bare-server/build/libs/bare-server.jar

# Any other server fat jar (e.g., ktor, Spring Boot)
./time-to-ready.sh -jar /path/to/server-all.jar
```

To count classes loaded during startup:

```bash
java -Xlog:class+load=info:file=/dev/stderr:level -jar some-app.jar 2>&1 1>/dev/null | wc -l
```

Class counts are derived from `-Xlog:class+load` output, where each log line represents one class load event. This
includes classes loaded from the CDS (Class Data Sharing) shared archive, which are faster to load than classes from
jars but still must be verified and initialized. For example, in jaspr's 3,184 total classes, 1,147 came from CDS and
~2,037 were loaded from jars on disk.

## Example Results (Mac Studio M3, Java 21 GraalVM CE)

### CLI startup time

| Benchmark                | Mean     | Classes Loaded |
|--------------------------|----------|----------------|
| Bare Kotlin Hello World  | ~74ms    | 842            |
| Clikt Hello World        | ~362ms   | 1,755          |
| jaspr --help (JVM)       | ~646ms   | 3,184          |
| jaspr --help (native)    | ~27ms    | 0 (AOT)        |

### Server time to first response

| Benchmark                          | Mean     |
|------------------------------------|----------|
| Bare JDK HttpServer                | ~165ms   |
| ktor + Netty                       | ~750ms   |
| ktor self-reported "started in"    | ~244ms   |

The ~585ms gap between the bare JDK server and ktor+Netty is pure framework overhead: Netty, ktor routing,
coroutines, YAML config parsing, and Logback initialization.

Note that ktor's self-reported "Application started in 0.244 seconds" fires before the server is actually accepting
connections — real time-to-first-response is roughly 3x higher.