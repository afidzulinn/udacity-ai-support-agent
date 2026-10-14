#!/usr/bin/env bash
# Runs the six rubric tests against the deployed agent.
# Take one screenshot of the terminal after each test and save it in screenshots/.
# Usage: bash run_tests.sh          -> all six tests
#        bash run_tests.sh memory   -> only Test 4A + 4B
set -u
export AGENTCORE_SUPPRESS_RECOMMENDATION=1

run() {  # $1 = label, $2 = JSON payload
  echo; echo "================ $1 ================"
  uv run agentcore invoke "$2"
  read -rp "Screenshot done? Press Enter for the next test..."
}

memory_tests() {
  run "TEST 4A - Memory, session A" \
    '{"prompt": "Hi, I am Jane. I prefer concise responses.", "customer_id": "CUST-123", "session_id": "s-A"}'
  # Long-term records are extracted asynchronously; give it time before session B.
  echo "Waiting 120s for long-term memory extraction..."; sleep 120
  bash "$(dirname "$0")/check_memory.sh"
  run "TEST 4B - Memory, session B (new session, same customer)" \
    '{"prompt": "Do you remember my name and communication preference?", "customer_id": "CUST-123", "session_id": "s-B"}'
}

if [ "${1:-}" = "memory" ]; then memory_tests; exit; fi

run "TEST 1 - Order Tracking (API Gateway target)" \
  '{"prompt": "Can you track order ORD-001?", "customer_id": "CUST-123", "session_id": "t1"}'
run "TEST 2 - Refund Processing (Lambda target)" \
  '{"prompt": "I want to return my Kindle Paperwhite (ORD-002). Please initiate a refund.", "customer_id": "CUST-123", "session_id": "t2"}'
run "TEST 3 - Knowledge Base (RAG)" \
  '{"prompt": "What are the benefits of the Platinum loyalty tier?", "customer_id": "CUST-123", "session_id": "t3"}'
memory_tests
run "TEST 5 - Loyalty Discount (Code Interpreter)" \
  '{"prompt": "I am a Gold member with 4250 points. Calculate my discount on a $150 standard order.", "customer_id": "CUST-123", "session_id": "t5"}'
run "TEST 6 - Browser Tool" \
  '{"prompt": "Go to https://www.udacity.com and tell me the page title.", "customer_id": "CUST-123", "session_id": "t6"}'
