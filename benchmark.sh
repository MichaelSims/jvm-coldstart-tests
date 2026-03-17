#!/usr/bin/env bash
# JVM Cold Start Benchmark Suite
# Requires: hyperfine (brew install hyperfine), Java 21+
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNS=10

echo "=== JVM Cold Start Benchmark ==="
echo ""
java -version 2>&1 | head -1
echo ""

# Build projects if needed
echo "--- Building projects ---"
(cd "$SCRIPT_DIR/hello-world" && ./gradlew jar -q)
(cd "$SCRIPT_DIR/clikt-hello" && ./gradlew jar -q)
(cd "$SCRIPT_DIR/bare-server" && ./gradlew jar -q)
echo "Done."
echo ""

HELLO_JAR="$SCRIPT_DIR/hello-world/build/libs/hello-world.jar"
CLIKT_JAR="$SCRIPT_DIR/clikt-hello/build/libs/clikt-hello.jar"
SERVER_JAR="$SCRIPT_DIR/bare-server/build/libs/bare-server.jar"
TTR="$SCRIPT_DIR/time-to-ready.sh"

# CLI startup benchmarks
echo "--- CLI startup time benchmarks (hyperfine) ---"
echo ""
hyperfine --warmup 3 --runs "$RUNS" \
  -n "Bare Kotlin Hello World" "java -jar $HELLO_JAR" \
  -n "Clikt Hello World" "java -jar $CLIKT_JAR"

echo ""

# Class loading counts
echo "--- Class loading counts ---"
for label_jar in "Hello World:$HELLO_JAR" "Clikt Hello:$CLIKT_JAR"; do
  label="${label_jar%%:*}"
  jar="${label_jar#*:}"
  count=$(java -Xlog:class+load=info:file=/dev/stderr:level -jar "$jar" 2>&1 1>/dev/null | wc -l)
  echo "  $label: $count classes loaded"
done

echo ""

# Server time-to-first-response benchmarks
echo "--- Server time-to-first-response ($RUNS runs) ---"
echo ""
echo "Bare JDK HttpServer:"
for i in $(seq 1 "$RUNS"); do
  kill $(lsof -ti:8080) 2>/dev/null || true
  sleep 0.3
  "$TTR" "$SERVER_JAR"
done

echo ""
echo "To compare against another server, run:"
echo "  $SCRIPT_DIR/benchmark-server.sh /path/to/server-all.jar"
echo ""
echo "--- To add your own CLI tool ---"
echo "  hyperfine --warmup 3 --runs 15 'your-tool --help'"