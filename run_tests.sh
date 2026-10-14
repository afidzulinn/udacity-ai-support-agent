#!/usr/bin/env bash
# Runs the six rubric tests against the deployed agent.
# Take one screenshot of the terminal after each test and save it in screenshots/.
set -u
export AGENTCORE_SUPPRESS_RECOMMENDATION=1

run() {  # $1 = label, $2 = JSON payload
  echo; echo "================ $1 ================"
  uv run agentcore invoke "$2"
  read -rp "Screenshot done? Press Enter for the next test..."
}

run "TEST 1 - Order Tracking (API Gateway target)" \
  '{"prompt": "Can you track order ORD-001?", "customer_id": "CUST-123", "session_id": "t1"}'
run "TEST 2 - Refund Processing (Lambda target)" \
  '{"prompt": "I want to return my Kindle Paperwhite (ORD-002). Please initiate a refund.", "customer_id": "CUST-123", "session_id": "t2"}'
run "TEST 3 - Knowledge Base (RAG)" \
  '{"prompt": "What are the benefits of the Platinum loyalty tier?", "customer_id": "CUST-123", "session_id": "t3"}'
run "TEST 4A - Memory, session A" \
  '{"prompt": "Hi, I am Jane. I prefer concise responses.", "customer_id": "CUST-123", "session_id": "s-A"}'
echo "Waiting 60s for long-term memory extraction..."; sleep 60
run "TEST 4B - Memory, session B (new session, same customer)" \
  '{"prompt": "Do you remember my name and communication preference?", "customer_id": "CUST-123", "session_id": "s-B"}'
run "TEST 5 - Loyalty Discount (Code Interpreter)" \
  '{"prompt": "I am a Gold member with 4250 points. Calculate my discount on a $150 standard order.", "customer_id": "CUST-123", "session_id": "t5"}'
run "TEST 6 - Browser Tool" \
  '{"prompt": "Go to https://www.udacity.com and tell me the page title.", "customer_id": "CUST-123", "session_id": "t6"}'
