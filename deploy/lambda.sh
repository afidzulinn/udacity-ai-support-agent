#!/usr/bin/env bash
# deploy_lambdas.sh — create IAM execution role + deploy both Lambda functions
set -euo pipefail

REGION="us-east-1"
ROLE_NAME="csai-lambda-execution-role"
LAMBDA_DIR="$HOME/Project_starter/lambda"

echo "=== 1. Create IAM trust policy ==="
cat > trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    { "Effect": "Allow", "Principal": { "Service": "lambda.amazonaws.com" }, "Action": "sts:AssumeRole" }
  ]
}
EOF

echo "=== 2. Create (or reuse) execution role ==="
if aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
  echo "Role $ROLE_NAME already exists — reusing."
else
  aws iam create-role \
    --role-name "$ROLE_NAME" \
    --assume-role-policy-document file://trust-policy.json
  aws iam attach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
  echo "Waiting 15s for IAM role propagation..."
  sleep 15
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"
echo "Role ARN: $ROLE_ARN"

deploy_one() {
  local FUNC_NAME="$1"
  local SRC_FILE="$2"
  local HANDLER="$3"

  echo ""
  echo "=== Deploying $FUNC_NAME ==="
  cd "$LAMBDA_DIR"
  rm -f "${FUNC_NAME}.zip"
  zip -q "${FUNC_NAME}.zip" "$SRC_FILE"

  if aws lambda get-function --function-name "$FUNC_NAME" --region "$REGION" >/dev/null 2>&1; then
    echo "Function exists — updating code."
    aws lambda update-function-code \
      --function-name "$FUNC_NAME" \
      --zip-file "fileb://${FUNC_NAME}.zip" \
      --region "$REGION" >/dev/null
  else
    echo "Creating new function (retrying if role isn't propagated yet)..."
    for i in 1 2 3 4 5; do
      if aws lambda create-function \
        --function-name "$FUNC_NAME" \
        --runtime python3.12 \
        --role "$ROLE_ARN" \
        --handler "$HANDLER" \
        --zip-file "fileb://${FUNC_NAME}.zip" \
        --timeout 10 \
        --region "$REGION" >/dev/null 2>&1; then
        break
      fi
      echo "  attempt $i failed, retrying in 10s..."
      sleep 10
    done
  fi

  local ARN
  ARN=$(aws lambda get-function --function-name "$FUNC_NAME" --region "$REGION" --query 'Configuration.FunctionArn' --output text)
  echo "✅ $FUNC_NAME ARN: $ARN"
}

deploy_one "order-tracker"     "order_tracker.py"     "order_tracker.lambda_handler"
deploy_one "refund-processor"  "refund_processor.py"  "refund_processor.lambda_handler"

echo ""
echo "=== Test order-tracker ==="
aws lambda invoke \
  --function-name order-tracker \
  --cli-binary-format raw-in-base64-out \
  --payload '{"resource": "/orders/{order_id}", "httpMethod": "GET", "pathParameters": {"order_id": "ORD-001"}}' \
  --region "$REGION" \
  /tmp/order_tracker_response.json >/dev/null

cat /tmp/order_tracker_response.json
echo ""
echo ""
echo "Expect statusCode 200 and body containing TRK987654321 and UPS."
echo ""
echo "=== Done. Both ARNs above — save them, you'll need them in Fase 3/4. ==="