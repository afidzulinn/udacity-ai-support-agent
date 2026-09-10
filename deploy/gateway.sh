#!/usr/bin/env bash
set -euo pipefail

REGION="us-east-1"
GATEWAY_NAME="CustomerSupportGateway"
ROLE_NAME="csai-gateway-service-role"
API_NAME="CustomerSupportAPI"
STAGE_NAME="prod"
REFUND_LAMBDA="refund-processor"
LAMBDA_SCHEMA_FILE="$HOME/Project_starter/lambda/lambda_schema"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Account: $ACCOUNT_ID"

echo "=== 0. Check bedrock-agentcore-control CLI support ==="
if ! aws bedrock-agentcore-control help >/dev/null 2>&1; then
  echo "❌ AWS CLI ini tidak mengenali 'bedrock-agentcore-control'."
  echo "   Coba: pip install --upgrade awscli --break-system-packages"
  exit 1
fi
echo "✅ bedrock-agentcore-control tersedia"

API_ID=$(aws apigateway get-rest-apis --region "$REGION" \
  --query "items[?name=='${API_NAME}'].id" --output text)
if [ -z "$API_ID" ] || [ "$API_ID" == "None" ]; then
  echo "❌ REST API '$API_NAME' tidak ditemukan. Jalankan Fase 3 dulu."
  exit 1
fi
echo "REST API: $API_ID"

REFUND_ARN="arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:${REFUND_LAMBDA}"
echo "Refund Lambda ARN: $REFUND_ARN"

echo ""
echo "=== 1. Buat Gateway service role ==="
cat > gw-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "GatewayAssumeRolePolicy",
      "Effect": "Allow",
      "Principal": { "Service": "bedrock-agentcore.amazonaws.com" },
      "Action": "sts:AssumeRole",
      "Condition": { "StringEquals": { "aws:SourceAccount": "${ACCOUNT_ID}" } }
    }
  ]
}
EOF

if aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
  echo "Role $ROLE_NAME sudah ada — reuse."
else
  aws iam create-role \
    --role-name "$ROLE_NAME" \
    --assume-role-policy-document file://gw-trust-policy.json >/dev/null
  echo "Role dibuat: $ROLE_NAME"
fi
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"

cat > gw-permissions-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "InvokeRefundLambda",
      "Effect": "Allow",
      "Action": "lambda:InvokeFunction",
      "Resource": "${REFUND_ARN}"
    },
    {
      "Sid": "InvokeOrderTrackerAPI",
      "Effect": "Allow",
      "Action": "execute-api:Invoke",
      "Resource": "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/${STAGE_NAME}/*/*"
    }
  ]
}
EOF

aws iam put-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-name "GatewayTargetAccess" \
  --policy-document file://gw-permissions-policy.json

echo "Menunggu 15s IAM propagation..."
sleep 15
echo "Gateway service role ARN: $ROLE_ARN"

echo ""
echo "=== 2. Buat Gateway (authorizer NONE) ==="
EXISTING_GW=$(aws bedrock-agentcore-control list-gateways --region "$REGION" \
  --query "items[?name=='${GATEWAY_NAME}'].gatewayId" --output text 2>/dev/null || echo "")

if [ -n "$EXISTING_GW" ] && [ "$EXISTING_GW" != "None" ]; then
  GATEWAY_ID="$EXISTING_GW"
  echo "Reuse gateway: $GATEWAY_ID"
else
  GATEWAY_ID=$(aws bedrock-agentcore-control create-gateway \
    --name "$GATEWAY_NAME" \
    --role-arn "$ROLE_ARN" \
    --protocol-type MCP \
    --authorizer-type NONE \
    --region "$REGION" \
    --query 'gatewayId' --output text)
  echo "Gateway dibuat: $GATEWAY_ID"
fi

echo "Menunggu gateway READY..."
for i in $(seq 1 24); do
  STATUS=$(aws bedrock-agentcore-control get-gateway --gateway-identifier "$GATEWAY_ID" \
    --region "$REGION" --query 'status' --output text)
  echo "  status: $STATUS"
  [ "$STATUS" == "READY" ] && break
  sleep 5
done

GATEWAY_URL=$(aws bedrock-agentcore-control get-gateway --gateway-identifier "$GATEWAY_ID" \
  --region "$REGION" --query 'gatewayUrl' --output text)
echo "✅ Gateway URL: $GATEWAY_URL"

echo ""
echo "=== 3. Target: order-tracker (API Gateway REST API stage) ==="
cat > target-order-tracker.json << EOF
{
  "mcp": {
    "apiGateway": {
      "restApiId": "${API_ID}",
      "stage": "${STAGE_NAME}",
      "apiGatewayToolConfiguration": {
        "toolFilters": [
          { "filterPath": "/orders/{order_id}", "methods": ["GET"] },
          { "filterPath": "/customers/{customer_id}/orders", "methods": ["GET"] },
          { "filterPath": "/customers/{customer_id}", "methods": ["GET"] }
        ]
      }
    }
  }
}
EOF

cat > cred-gateway-iam.json << 'EOF'
[ { "credentialProviderType": "GATEWAY_IAM_ROLE" } ]
EOF

EXISTING_T1=$(aws bedrock-agentcore-control list-gateway-targets --gateway-identifier "$GATEWAY_ID" \
  --region "$REGION" --query "items[?name=='order-tracker'].targetId" --output text 2>/dev/null || echo "")

if [ -n "$EXISTING_T1" ] && [ "$EXISTING_T1" != "None" ]; then
  echo "Target order-tracker sudah ada — skip."
else
  aws bedrock-agentcore-control create-gateway-target \
    --gateway-identifier "$GATEWAY_ID" \
    --name "order-tracker" \
    --target-configuration file://target-order-tracker.json \
    --credential-provider-configurations file://cred-gateway-iam.json \
    --region "$REGION" >/dev/null
  echo "✅ Target order-tracker dibuat"
fi

echo ""
echo "=== 4. Target: refund-processor (Lambda) ==="
python3 << PYEOF
import json
with open("${LAMBDA_SCHEMA_FILE}") as f:
    tool_schema = json.load(f)
config = {
    "mcp": {
        "lambda": {
            "lambdaArn": "${REFUND_ARN}",
            "toolSchema": { "inlinePayload": tool_schema }
        }
    }
}
with open("target-refund-processor.json", "w") as f:
    json.dump(config, f, indent=2)
print("Wrote target-refund-processor.json with", len(tool_schema), "tools")
PYEOF

EXISTING_T2=$(aws bedrock-agentcore-control list-gateway-targets --gateway-identifier "$GATEWAY_ID" \
  --region "$REGION" --query "items[?name=='refund-processor'].targetId" --output text 2>/dev/null || echo "")

if [ -n "$EXISTING_T2" ] && [ "$EXISTING_T2" != "None" ]; then
  echo "Target refund-processor sudah ada — skip."
else
  aws bedrock-agentcore-control create-gateway-target \
    --gateway-identifier "$GATEWAY_ID" \
    --name "refund-processor" \
    --target-configuration file://target-refund-processor.json \
    --credential-provider-configurations file://cred-gateway-iam.json \
    --region "$REGION" >/dev/null
  echo "✅ Target refund-processor dibuat"
fi

echo ""
echo "=== 5. Tunggu kedua target READY ==="
for TARGET_NAME in "order-tracker" "refund-processor"; do
  TARGET_ID=$(aws bedrock-agentcore-control list-gateway-targets --gateway-identifier "$GATEWAY_ID" \
    --region "$REGION" --query "items[?name=='${TARGET_NAME}'].targetId" --output text)
  for i in $(seq 1 24); do
    STATUS=$(aws bedrock-agentcore-control get-gateway-target --gateway-identifier "$GATEWAY_ID" \
      --target-id "$TARGET_ID" --region "$REGION" --query 'status' --output text)
    echo "  $TARGET_NAME status: $STATUS"
    [ "$STATUS" == "READY" ] && break
    if [ "$STATUS" == "FAILED" ]; then
      echo "❌ $TARGET_NAME gagal:"
      aws bedrock-agentcore-control get-gateway-target --gateway-identifier "$GATEWAY_ID" \
        --target-id "$TARGET_ID" --region "$REGION" --query 'statusReasons'
      exit 1
    fi
    sleep 5
  done
done

echo ""
echo "=========================================="
echo "✅ Gateway setup selesai."
echo "GATEWAY_ID  : $GATEWAY_ID"
echo "GATEWAY_URL : $GATEWAY_URL"
echo ""
echo "Paste ke main.py:"
echo "GATEWAY_URL = \"${GATEWAY_URL}\""
echo "=========================================="