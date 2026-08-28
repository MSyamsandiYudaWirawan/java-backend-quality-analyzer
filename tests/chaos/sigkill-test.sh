#!/bin/bash
# ============================================================================
# Chaos Test: SIGKILL Mid-Flow
# ============================================================================
# Usage:
#   ./tests/chaos/sigkill-test.sh
#
# Prerequisites:
#   - Service JAR built: cd service && ./mvnw clean package -DskipTests
#   - Docker Compose running: docker compose up -d
#
# This is a TEMPLATE. Adapt the flow steps, health checks, and assertions
# to match the actual business process in the problem PDF.
# ============================================================================

set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
JAR="$PROJECT_ROOT/service/target/service-0.0.1-SNAPSHOT.jar"
HEALTH_URL="http://localhost:8080/actuator/health"
JAVA_PID=""

echo "=== Chaos Test: SIGKILL Mid-Flow ==="

# --- Verify JAR exists -------------------------------------------------------
if [ ! -f "$JAR" ]; then
  echo "ERROR: JAR not found: $JAR"
  echo "Build first: cd service && ./mvnw clean package -DskipTests"
  exit 1
fi

# --- Start service in background ---------------------------------------------
echo "[1/5] Starting service..."
java -jar "$JAR" &
JAVA_PID=$!
sleep 5

# --- Wait for healthy --------------------------------------------------------
echo "[2/5] Waiting for health..."
for i in {1..30}; do
  if curl -sf "$HEALTH_URL" >/dev/null 2>&1; then
    echo "  healthy"
    break
  fi
  sleep 1
done

if ! curl -sf "$HEALTH_URL" >/dev/null 2>&1; then
  echo "ERROR: Service never became healthy"
  kill "$JAVA_PID" 2>/dev/null || true
  exit 1
fi

# --- Start business flow -----------------------------------------------------
echo "[3/5] Starting business flow..."
# TEMPLATE: Replace with actual endpoint that starts a multi-step process.
# Example: POST /api/v1/orders to create an order that triggers a saga.
#
# FLOW_ID=$(curl -sf -X POST http://localhost:8080/api/v1/orders \
#   -H "Content-Type: application/json" \
#   -d '{"entityId":"...","qty":1}' | jq -r '.id')
#
# Wait until a specific step completes (poll for state):
# for i in {1..20}; do
#   STATE=$(curl -sf http://localhost:8080/api/v1/orders/$FLOW_ID | jq -r '.status')
#   [ "$STATE" = "PAYMENT_HELD" ] && break
#   sleep 0.5
# done
#
# echo "  Flow $FLOW_ID reached PAYMENT_HELD"

echo "  (TEMPLATE — adapt flow steps to the problem domain)"

# --- SIGKILL -----------------------------------------------------------------
echo "[4/5] Sending SIGKILL to PID $JAVA_PID..."
kill -9 "$JAVA_PID"
echo "  killed"

# --- Restart and assert ------------------------------------------------------
echo "[5/5] Restarting service and asserting recovery..."
java -jar "$JAR" &
JAVA_PID=$!
sleep 5

for i in {1..30}; do
  if curl -sf "$HEALTH_URL" >/dev/null 2>&1; then
    echo "  healthy after restart"
    break
  fi
  sleep 1
done

# TEMPLATE: Assert no stuck state, no duplicates, correct final state.
# Example:
# FINAL_STATE=$(curl -sf http://localhost:8080/api/v1/orders/$FLOW_ID | jq -r '.status')
# if [ "$FINAL_STATE" = "COMPLETED" ] || [ "$FINAL_STATE" = "ROLLED_BACK" ]; then
#   echo "PASS: Flow recovered to $FINAL_STATE"
# else
#   echo "FAIL: Flow stuck in $FINAL_STATE"
#   kill "$JAVA_PID" 2>/dev/null || true
#   exit 1
# fi

echo "  (TEMPLATE — add assertions for the actual problem)"

# --- Cleanup -----------------------------------------------------------------
kill "$JAVA_PID" 2>/dev/null || true
echo "=== Chaos Test Complete ==="
