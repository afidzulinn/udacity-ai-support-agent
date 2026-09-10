#!/usr/bin/env bash
set -euo pipefail

REGION="us-east-1"
MEMORY_NAME="CustomerSupportMemory"

echo "=== 0. Check for existing memory with this name ==="
EXISTING_ID=$(aws bedrock-agentcore-control list-memories --region "$REGION" \
  --query "memories[?name=='${MEMORY_NAME}'].id" --output text 2>/dev/null || echo "")

if [ -n "$EXISTING_ID" ] && [ "$EXISTING_ID" != "None" ]; then
  MEMORY_ID="$EXISTING_ID"
  echo "Reusing existing memory: $MEMORY_ID"
else
  echo "=== 1. Create Memory resource with two strategies ==="
  cat > memory-strategies.json << 'EOF'
[
  {
    "semanticMemoryStrategy": {
      "name": "customer_facts",
      "namespaces": ["cs_agent/{actorId}/facts"]
    }
  },
  {
    "userPreferenceMemoryStrategy": {
      "name": "customer_preferences",
      "namespaces": ["cs_agent/{actorId}/preferences"]
    }
  }
]
EOF

  MEMORY_ID=$(aws bedrock-agentcore-control create-memory \
    --name "$MEMORY_NAME" \
    --description "Memory for the customer support agent" \
    --event-expiry-duration 90 \
    --memory-strategies file://memory-strategies.json \
    --region "$REGION" \
    --query 'memory.id' --output text)
  echo "Created memory: $MEMORY_ID"
fi

echo ""
echo "=== 2. Wait for memory to become ACTIVE ==="
echo "(Strategy provisioning can take a few minutes)"
for i in $(seq 1 36); do
  STATUS=$(aws bedrock-agentcore-control get-memory --memory-id "$MEMORY_ID" \
    --region "$REGION" --query 'memory.status' --output text)
  echo "  status: $STATUS"
  [ "$STATUS" == "ACTIVE" ] && break
  if [ "$STATUS" == "FAILED" ]; then
    echo "❌ Memory creation failed. Details:"
    aws bedrock-agentcore-control get-memory --memory-id "$MEMORY_ID" --region "$REGION"
    exit 1
  fi
  sleep 10
done

echo ""
echo "=== 3. Confirm strategies and namespaces ==="
aws bedrock-agentcore-control list-memory-strategies --memory-id "$MEMORY_ID" \
  --region "$REGION" --output json

echo ""
echo "=========================================="
echo "✅ Memory setup complete."
echo "MEMORY_ID = $MEMORY_ID"
echo ""
echo "Paste ke main.py:"
echo "MEMORY_ID = \"${MEMORY_ID}\""
echo "=========================================="
