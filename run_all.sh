#!/usr/bin/env bash
# =============================================================================
# run_all.sh — deploy the agent and capture terminal output for all six tests
#
# Usage:
#   bash run_all.sh            # configure + deploy + run all tests
#   bash run_all.sh --tests    # skip deploy, just re-run the tests
# =============================================================================
set -uo pipefail

AGENT_NAME="customer_support_agent"
LOG_DIR="test-logs"
SKIP_DEPLOY=false

[ "${1:-}" == "--tests" ] && SKIP_DEPLOY=true

# Make sure uv is on PATH even in a fresh shell that hasn't sourced ~/.bashrc yet.
export PATH="$HOME/.local/bin:$PATH"

# IMPORTANT: always call the starter-toolkit CLI via 'uv run agentcore', never
# a bare 'agentcore' — this environment also has a different, unrelated
# '@aws/agentcore' npm package on PATH at /usr/local/bin/agentcore that
# shadows it and does not have configure/deploy/invoke/destroy.
AGENTCORE="uv run agentcore"

mkdir -p "$LOG_DIR"

banner() {
  echo ""
  echo "============================================================"
  echo "$1"
  echo "============================================================"
}

# ── Deploy ────────────────────────────────────────────────────────────────────
if [ "$SKIP_DEPLOY" = false ]; then
  banner "STEP 1 — agentcore configure"
  if [ -f ".bedrock_agentcore.yaml" ]; then
    echo "Config already exists, skipping configure."
  else
    $AGENTCORE configure --entrypoint main.py --name "$AGENT_NAME" 2>&1 | tee "$LOG_DIR/00-configure.txt"
  fi

  banner "STEP 2 — agentcore deploy (this takes several minutes)"
  $AGENTCORE deploy 2>&1 | tee "$LOG_DIR/00-deploy.txt"

  echo ""
  echo "Waiting 30s for the runtime endpoint to settle..."
  sleep 30
fi

# ── Test runner ───────────────────────────────────────────────────────────────
run_test() {
  local NUM="$1"
  local NAME="$2"
  local FILE="$3"
  local PAYLOAD="$4"

  banner "TEST $NUM — $NAME"
  echo "Payload: $PAYLOAD"
  echo ""

  {
    echo "==================================================================="
    echo "TEST $NUM — $NAME"
    echo "Timestamp: $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
    echo "Command:"
    echo "  agentcore invoke '$PAYLOAD'"
    echo "==================================================================="
    echo ""
  } > "$LOG_DIR/$FILE"

  $AGENTCORE invoke "$PAYLOAD" 2>&1 | tee -a "$LOG_DIR/$FILE"

  echo ""
  echo "→ saved to $LOG_DIR/$FILE"
}

# ── Test 1 — Order Tracking (Gateway / API Gateway target) ───────────────────
run_test 1 "Order Tracking" "test1-order-tracking.txt" \
  '{"prompt": "Can you track order ORD-001?", "customer_id": "CUST-123", "session_id": "t1"}'

# ── Test 2 — Refund Processing (Gateway / Lambda target) ─────────────────────
run_test 2 "Refund Processing" "test2-refund-processing.txt" \
  '{"prompt": "I want to return my Kindle Paperwhite (ORD-002). Please initiate a refund.", "customer_id": "CUST-123", "session_id": "t2"}'

# ── Test 3 — Knowledge Base (RAG) ────────────────────────────────────────────
run_test 3 "Knowledge Base (RAG)" "test3-knowledge-base.txt" \
  '{"prompt": "What are the benefits of the Platinum loyalty tier?", "customer_id": "CUST-123", "session_id": "t3"}'

# ── Test 4 — Long-Term Memory (two separate sessions) ────────────────────────
run_test 4 "Long-Term Memory — Session A (store)" "test4-memory-session-a.txt" \
  '{"prompt": "Hi, I am Jane. I prefer concise responses.", "customer_id": "CUST-123", "session_id": "s-A"}'

banner "Waiting 60s for asynchronous memory extraction before Session B"
sleep 60

run_test 4 "Long-Term Memory — Session B (recall)" "test4-memory-session-b.txt" \
  '{"prompt": "Do you remember my name and communication preference?", "customer_id": "CUST-123", "session_id": "s-B"}'

# ── Test 5 — Loyalty Discount (Code Interpreter) ─────────────────────────────
run_test 5 "Loyalty Discount Calculation" "test5-loyalty-discount.txt" \
  '{"prompt": "I am a Gold member with 4250 points. Calculate my discount on a $150 standard order.", "customer_id": "CUST-123", "session_id": "t5"}'

# ── Test 6 — Browser Tool ────────────────────────────────────────────────────
run_test 6 "Browser Tool" "test6-browser.txt" \
  '{"prompt": "Go to https://www.udacity.com and tell me the page title.", "customer_id": "CUST-123", "session_id": "t6"}'

# ── Summary ───────────────────────────────────────────────────────────────────
banner "ALL TESTS COMPLETE"
echo "Logs written to $LOG_DIR/:"
ls -la "$LOG_DIR/"
echo ""
echo "Expected results to verify in the logs:"
echo "  Test 1 → TRK987654321, UPS, SHIPPED, estimated delivery date"
echo "  Test 2 → a REF-XXXXXXXX refund ID, APPROVED, '3-5 business days'"
echo "  Test 3 → free same-day shipping, 15% discount, priority support"
echo "  Test 4 → Session B recalls 'Jane' and the preference for concise responses"
echo "  Test 5 → points_redeemed 4000, tier_discount_pct 10, final_total 99, remaining_points 349"
echo "  Test 6 → the live page title from udacity.com"