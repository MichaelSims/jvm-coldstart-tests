#!/usr/bin/env bash
# Measures time from process start to first successful HTTP response.
#
# Dependencies: java, curl
#
# Usage:
#   ./time-to-ready.sh -jar /path/to/app.jar [port]
#   ./time-to-ready.sh -cp /path/to/classes ClassName [port]
set -euo pipefail

JAVA="${JAVA_CMD:-java}"

if [[ "${1:-}" == "-jar" ]]; then
    shift
    TARGET="$1"; shift
    JAVA_ARGS=(-jar "$TARGET")
elif [[ "${1:-}" == "-cp" ]]; then
    shift
    CLASSPATH="$1"; shift
    CLASSNAME="$1"; shift
    JAVA_ARGS=(-cp "$CLASSPATH" "$CLASSNAME")
else
    echo "Usage:"
    echo "  $0 -jar /path/to/app.jar [port]"
    echo "  $0 -cp /path/to/classes ClassName [port]"
    exit 1
fi

PORT="${1:-8080}"
URL="http://127.0.0.1:${PORT}/"

START=$(date +%s%N)

"$JAVA" "${JAVA_ARGS[@]}" &
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