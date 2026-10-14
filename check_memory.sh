#!/usr/bin/env bash
# Shows exactly what the MemoryHook retrieves for the Test 4B question,
# i.e. which long-term records exist for CUST-123 in each namespace.
MEMORY_ID=$(grep -E '^MEMORY_ID ' "$(dirname "$0")/main.py" | cut -d'"' -f2)
QUERY="Do you remember my name and communication preference?"

for NS in facts preferences; do
  echo; echo "== cs_agent/CUST-123/$NS (top 5 for: $QUERY)"
  aws bedrock-agentcore retrieve-memory-records --memory-id "$MEMORY_ID" \
    --namespace "cs_agent/CUST-123/$NS" \
    --search-criteria "searchQuery=$QUERY,topK=5" \
    --query "memoryRecordSummaries[].content.text" --output text | tr '\t' '\n'
done
