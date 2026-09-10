#!/usr/bin/env bash
set -euo pipefail

REGION="us-east-1"
API_NAME="CustomerSupportAPI"
STAGE_NAME="prod"
GATEWAY_NAME="CustomerSupportGateway"

API_ID=$(aws apigateway get-rest-apis --region "$REGION" \
  --query "items[?name=='${API_NAME}'].id" --output text)
echo "REST API: $API_ID"

get_resource_id() {
  aws apigateway get-resources --rest-api-id "$API_ID" --region "$REGION" \
    --query "items[?path=='$1'].id" --output text
}

ORDER_ID_RES=$(get_resource_id "/orders/{order_id}")
CUSTOMER_ID_RES=$(get_resource_id "/customers/{customer_id}")
CUSTOMER_ORDERS_RES=$(get_resource_id "/customers/{customer_id}/orders")

echo "Resource IDs: $ORDER_ID_RES / $CUSTOMER_ID_RES / $CUSTOMER_ORDERS_RES"

add_response() {
  local RESOURCE_ID="$1"
  local LABEL="$2"
  echo "Adding 200 method-response to $LABEL ($RESOURCE_ID)..."
  aws apigateway put-method-response \
    --rest-api-id "$API_ID" \
    --resource-id "$RESOURCE_ID" \
    --http-method GET \
    --status-code 200 \
    --response-models '{"application/json":"Empty"}' \
    --region "$REGION" >/dev/null 2>&1 || echo "  (already exists, continuing)"
}

add_response "$ORDER_ID_RES"        "/orders/{order_id}"
add_response "$CUSTOMER_ID_RES"     "/customers/{customer_id}"
add_response "$CUSTOMER_ORDERS_RES" "/customers/{customer_id}/orders"

echo ""
echo "=== Redeploy stage '$STAGE_NAME' ==="
aws apigateway create-deployment \
  --rest-api-id "$API_ID" \
  --stage-name "$STAGE_NAME" \
  --region "$REGION" >/dev/null
echo "✅ Redeployed"

echo ""
echo "=== Sanity check: fetch OpenAPI export and confirm 'responses' present ==="
aws apigateway get-export \
  --rest-api-id "$API_ID" \
  --stage-name "$STAGE_NAME" \
  --export-type oas30 \
  --region "$REGION" \
  /tmp/export-check.json >/dev/null
python3 -c "
import json
d = json.load(open('/tmp/export-check.json'))
for path, methods in d.get('paths', {}).items():
    for m, op in methods.items():
        has_resp = 'responses' in op
        print(f'{m.upper():5} {path:35} responses present: {has_resp}')
"

echo ""
echo "=== Delete the FAILED order-tracker target and recreate ==="
GATEWAY_ID=$(aws bedrock-agentcore-control list-gateways --region "$REGION" \
  --query "items[?name=='${GATEWAY_NAME}'].gatewayId" --output text)
echo "Gateway: $GATEWAY_ID"

TARGET_ID=$(aws bedrock-agentcore-control list-gateway-targets --gateway-identifier "$GATEWAY_ID" \
  --region "$REGION" --query "items[?name=='order-tracker'].targetId" --output text)
echo "Existing target-id: $TARGET_ID"

if [ -n "$TARGET_ID" ] && [ "$TARGET_ID" != "None" ]; then
  aws bedrock-agentcore-control delete-gateway-target \
    --gateway-identifier "$GATEWAY_ID" \
    --target-id "$TARGET_ID" \
    --region "$REGION" >/dev/null
  echo "Deleted old failed target. Waiting 10s..."
  sleep 10
fi

aws bedrock-agentcore-control create-gateway-target \
  --gateway-identifier "$GATEWAY_ID" \
  --name "order-tracker" \
  --target-configuration file://target-order-tracker.json \
  --credential-provider-configurations file://cred-gateway-iam.json \
  --region "$REGION" >/dev/null
echo "✅ Recreated target order-tracker"

echo ""
echo "=== Wait for READY ==="
NEW_TARGET_ID=$(aws bedrock-agentcore-control list-gateway-targets --gateway-identifier "$GATEWAY_ID" \
  --region "$REGION" --query "items[?name=='order-tracker'].targetId" --output text)

for i in $(seq 1 24); do
  STATUS=$(aws bedrock-agentcore-control get-gateway-target --gateway-identifier "$GATEWAY_ID" \
    --target-id "$NEW_TARGET_ID" --region "$REGION" --query 'status' --output text)
  echo "  order-tracker status: $STATUS"
  [ "$STATUS" == "READY" ] && break
  if [ "$STATUS" == "FAILED" ]; then
    echo "❌ Masih gagal. Alasan:"
    aws bedrock-agentcore-control get-gateway-target --gateway-identifier "$GATEWAY_ID" \
      --target-id "$NEW_TARGET_ID" --region "$REGION" --query 'statusReasons'
    exit 1
  fi
  sleep 5
done

echo ""
echo "✅ Selesai. order-tracker sekarang READY."