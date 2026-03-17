#!/usr/bin/env bash
# Benchmark a server fat jar for time-to-first-response, compared against the bare JDK HttpServer.
#
# Usage:
#   ./benchmark-server.sh /path/to/ktor-sample-all.jar
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNS=10

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 /path/to/server-all.jar"
    exit 1
fi

JAR="$1"
NAME="$(basename "$JAR" .jar)"
SERVER_JAR="$SCRIPT_DIR/bare-server/build/libs/bare-server.jar"
TTR="$SCRIPT_DIR/time-to-ready.sh"

# Build bare-server for comparison if needed
if [[ ! -f "$SERVER_JAR" ]]; then
    echo "Building bare-server for comparison..."
    (cd "$SCRIPT_DIR/bare-server" && ./gradlew jar -q)
fi

echo "=== Server Time-to-First-Response ($RUNS runs each) ==="
echo ""

echo "Bare JDK HttpServer:"
for i in $(seq 1 "$RUNS"); do
  kill $(lsof -ti:8080) 2>/dev/null || true
  sleep 0.3
  "$TTR" "$SERVER_JAR"
done

echo ""
echo "$NAME:"
for i in $(seq 1 "$RUNS"); do
  kill $(lsof -ti:8080) 2>/dev/null || true
  sleep 0.3
  "$TTR" "$JAR"
done