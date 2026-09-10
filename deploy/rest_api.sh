#!/usr/bin/env bash
# deploy_rest_api.sh — create REST API with 3 GET routes proxying to order-tracker Lambda
set -euo pipefail

REGION="us-east-1"
API_NAME="CustomerSupportAPI"
LAMBDA_FUNC="order-tracker"
STAGE_NAME="prod"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
LAMBDA_ARN="arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:${LAMBDA_FUNC}"

echo "=== 1. Create (or reuse) REST API ==="
API_ID=$(aws apigateway get-rest-apis --region "$REGION" \
  --query "items[?name=='${API_NAME}'].id" --output text)

if [ -z "$API_ID" ] || [ "$API_ID" == "None" ]; then
  API_ID=$(aws apigateway create-rest-api \
    --name "$API_NAME" \
    --region "$REGION" \
    --query 'id' --output text)
  echo "Created API: $API_ID"
else
  echo "Reusing existing API: $API_ID"
fi

ROOT_ID=$(aws apigateway get-resources --rest-api-id "$API_ID" --region "$REGION" \
  --query "items[?path=='/'].id" --output text)
echo "Root resource id: $ROOT_ID"

# --- Helper: get or create a resource under a given parent ---
# IMPORTANT: all info/debug messages go to stderr (>&2) so that
# $(...) capture only picks up the final `echo "$RID"` on stdout.
get_or_create_resource() {
  local PARENT_ID="$1"
  local PATH_PART="$2"
  local FULL_PATH="$3"

  local RID
  RID=$(aws apigateway get-resources --rest-api-id "$API_ID" --region "$REGION" \
    --query "items[?path=='${FULL_PATH}'].id" --output text)

  if [ -z "$RID" ] || [ "$RID" == "None" ]; then
    RID=$(aws apigateway create-resource \
      --rest-api-id "$API_ID" \
      --parent-id "$PARENT_ID" \
      --path-part "$PATH_PART" \
      --region "$REGION" \
      --query 'id' --output text)
    echo "  created resource $FULL_PATH -> $RID" >&2
  else
    echo "  reusing resource $FULL_PATH -> $RID" >&2
  fi
  echo "$RID"
}

echo "=== 2. Create resource tree ==="
ORDERS_ID=$(get_or_create_resource "$ROOT_ID" "orders" "/orders")
ORDER_ID_RES=$(get_or_create_resource "$ORDERS_ID" "{order_id}" "/orders/{order_id}")
CUSTOMERS_ID=$(get_or_create_resource "$ROOT_ID" "customers" "/customers")
CUSTOMER_ID_RES=$(get_or_create_resource "$CUSTOMERS_ID" "{customer_id}" "/customers/{customer_id}")
CUSTOMER_ORDERS_RES=$(get_or_create_resource "$CUSTOMER_ID_RES" "orders" "/customers/{customer_id}/orders")

echo ""
echo "Resolved resource IDs:"
echo "  /orders                       -> $ORDERS_ID"
echo "  /orders/{order_id}            -> $ORDER_ID_RES"
echo "  /customers                    -> $CUSTOMERS_ID"
echo "  /customers/{customer_id}      -> $CUSTOMER_ID_RES"
echo "  /customers/{customer_id}/orders -> $CUSTOMER_ORDERS_RES"

# --- Helper: attach GET method + Lambda proxy integration + permission ---
setup_method() {
  local RESOURCE_ID="$1"
  local OP_NAME="$2"
  local FULL_PATH="$3"

  echo ""
  echo "=== Setting up GET $FULL_PATH  (operation: $OP_NAME, resource: $RESOURCE_ID) ==="

  aws apigateway put-method \
    --rest-api-id "$API_ID" \
    --resource-id "$RESOURCE_ID" \
    --http-method GET \
    --authorization-type NONE \
    --operation-name "$OP_NAME" \
    --region "$REGION" >/dev/null 2>&1 || echo "  (method already exists, continuing)"

  aws apigateway put-integration \
    --rest-api-id "$API_ID" \
    --resource-id "$RESOURCE_ID" \
    --http-method GET \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations" \
    --region "$REGION" >/dev/null

  local STATEMENT_ID="apigw-${OP_NAME}"
  aws lambda add-permission \
    --function-name "$LAMBDA_FUNC" \
    --statement-id "$STATEMENT_ID" \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/*" \
    --region "$REGION" >/dev/null 2>&1 || echo "  (permission already exists, continuing)"

  echo "  ✅ $FULL_PATH wired to $LAMBDA_FUNC (op: $OP_NAME)"
}

setup_method "$ORDER_ID_RES"          "get_order"             "/orders/{order_id}"
setup_method "$CUSTOMER_ORDERS_RES"   "get_customer_orders"   "/customers/{customer_id}/orders"
setup_method "$CUSTOMER_ID_RES"       "get_customer"          "/customers/{customer_id}"

echo ""
echo "=== 3. Deploy to stage '$STAGE_NAME' ==="
aws apigateway create-deployment \
  --rest-api-id "$API_ID" \
  --stage-name "$STAGE_NAME" \
  --region "$REGION" >/dev/null

INVOKE_URL="https://${API_ID}.execute-api.${REGION}.amazonaws.com/${STAGE_NAME}"
echo "✅ Deployed. Base invoke URL: $INVOKE_URL"

echo ""
echo "=== 4. Live test ==="
echo "GET /orders/ORD-001"
curl -s "${INVOKE_URL}/orders/ORD-001" ; echo ""
echo ""
echo "GET /customers/CUST-123"
curl -s "${INVOKE_URL}/customers/CUST-123" ; echo ""
echo ""
echo "GET /customers/CUST-123/orders"
curl -s "${INVOKE_URL}/customers/CUST-123/orders" ; echo ""

echo ""
echo "=========================================="
echo "REST API ID   : $API_ID"
echo "Stage         : $STAGE_NAME"
echo "Invoke URL    : $INVOKE_URL"
echo "Save API_ID — you'll need it for the AgentCore Gateway target in Fase 4."
echo "=========================================="