#!/usr/bin/env bash
# Measures time from process start to first successful HTTP response.
#
# Usage:
#   ./time-to-ready.sh /path/to/server-all.jar [port]
set -euo pipefail

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 /path/to/server-all.jar [port]"
    exit 1
fi

JAR="$1"
PORT="${2:-8080}"
URL="http://127.0.0.1:${PORT}/"

START=$(date +%s%N)

java -jar "$JAR" > /dev/null 2>&1 &
SERVER_PID=$!

cleanup() { kill $SERVER_PID 2>/dev/null; wait $SERVER_PID 2>/dev/null || true; }
trap cleanup EXIT

TIMEOUT=30
ELAPSED=0
while ! curl -s -o /dev/null -w '' "$URL" 2>/dev/null; do
    sleep 0.01
    ELAPSED=$((ELAPSED + 1))
    if [ $ELAPSED -ge $((TIMEOUT * 100)) ]; then
        echo "ERROR: Server did not start within ${TIMEOUT}s"
        exit 1
    fi
done

END=$(date +%s%N)
DIFF_MS=$(( (END - START) / 1000000 ))
echo "Time to first response: ${DIFF_MS}ms"