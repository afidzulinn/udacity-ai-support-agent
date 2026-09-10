#!/usr/bin/env bash
set -euo pipefail

REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="csai-kb-${ACCOUNT_ID}"
KB_NAME="CustomerSupportKB"
ROLE_NAME="csai-kb-role"
COLLECTION_NAME="csai-kb-collection"
CATALOG_FILE="$HOME/Project_starter/product_catalog.txt"

echo "=== 1. Create S3 bucket + upload catalog ==="
if aws s3api head-bucket --bucket "$BUCKET_NAME" --region "$REGION" 2>/dev/null; then
  echo "Bucket exists, reusing."
else
  aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$REGION" >/dev/null
  echo "Bucket created: $BUCKET_NAME"
fi
aws s3 cp "$CATALOG_FILE" "s3://${BUCKET_NAME}/product_catalog.txt" --region "$REGION"

echo ""
echo "=== 2. Create KB execution role ==="
cat > kb-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "bedrock.amazonaws.com" },
      "Action": "sts:AssumeRole",
      "Condition": { "StringEquals": { "aws:SourceAccount": "${ACCOUNT_ID}" } }
    }
  ]
}
EOF

if aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
  echo "Role exists, reusing."
else
  aws iam create-role --role-name "$ROLE_NAME" \
    --assume-role-policy-document file://kb-trust-policy.json >/dev/null
fi
KB_ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"

cat > kb-permissions-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:ListBucket"],
      "Resource": ["arn:aws:s3:::${BUCKET_NAME}", "arn:aws:s3:::${BUCKET_NAME}/*"]
    },
    {
      "Effect": "Allow",
      "Action": ["bedrock:InvokeModel"],
      "Resource": "arn:aws:bedrock:${REGION}::foundation-model/amazon.titan-embed-text-v2:0"
    },
    {
      "Effect": "Allow",
      "Action": ["aoss:APIAccessAll"],
      "Resource": "arn:aws:aoss:${REGION}:${ACCOUNT_ID}:collection/*"
    }
  ]
}
EOF
aws iam put-role-policy --role-name "$ROLE_NAME" \
  --policy-name "KBAccess" --policy-document file://kb-permissions-policy.json
echo "KB role: $KB_ROLE_ARN"

echo ""
echo "=== 3. Create OpenSearch Serverless encryption/network/access policies ==="
cat > enc-policy.json << EOF
{"Rules":[{"ResourceType":"collection","Resource":["collection/${COLLECTION_NAME}"]}],"AWSOwnedKey":true}
EOF
aws opensearchserverless create-security-policy --name "${COLLECTION_NAME}-enc" \
  --type encryption --policy file://enc-policy.json --region "$REGION" >/dev/null 2>&1 || echo "(encryption policy exists)"

cat > net-policy.json << EOF
[{"Rules":[{"ResourceType":"collection","Resource":["collection/${COLLECTION_NAME}"]},{"ResourceType":"dashboard","Resource":["collection/${COLLECTION_NAME}"]}],"AllowFromPublic":true}]
EOF
aws opensearchserverless create-security-policy --name "${COLLECTION_NAME}-net" \
  --type network --policy file://net-policy.json --region "$REGION" >/dev/null 2>&1 || echo "(network policy exists)"

CALLER_ARN=$(aws sts get-caller-identity --query Arn --output text)
cat > access-policy.json << EOF
[{"Rules":[{"ResourceType":"collection","Resource":["collection/${COLLECTION_NAME}"],"Permission":["aoss:*"]},{"ResourceType":"index","Resource":["index/${COLLECTION_NAME}/*"],"Permission":["aoss:*"]}],"Principal":["${KB_ROLE_ARN}","${CALLER_ARN}"]}]
EOF
aws opensearchserverless create-access-policy --name "${COLLECTION_NAME}-access" \
  --type data --policy file://access-policy.json --region "$REGION" >/dev/null 2>&1 || echo "(access policy exists)"

echo ""
echo "=== 4. Create OpenSearch Serverless collection ==="
EXISTING_COLL=$(aws opensearchserverless list-collections --region "$REGION" \
  --query "collectionSummaries[?name=='${COLLECTION_NAME}'].id" --output text)

if [ -n "$EXISTING_COLL" ] && [ "$EXISTING_COLL" != "None" ]; then
  COLLECTION_ID="$EXISTING_COLL"
  echo "Reusing collection: $COLLECTION_ID"
else
  COLLECTION_ID=$(aws opensearchserverless create-collection \
    --name "$COLLECTION_NAME" --type VECTORSEARCH --region "$REGION" \
    --query 'createCollectionDetail.id' --output text)
  echo "Created collection: $COLLECTION_ID"
fi

echo "Waiting for collection ACTIVE (can take 2-3 min)..."
for i in $(seq 1 30); do
  STATUS=$(aws opensearchserverless batch-get-collection --ids "$COLLECTION_ID" --region "$REGION" \
    --query 'collectionDetails[0].status' --output text)
  echo "  status: $STATUS"
  [ "$STATUS" == "ACTIVE" ] && break
  sleep 10
done

COLLECTION_ARN=$(aws opensearchserverless batch-get-collection --ids "$COLLECTION_ID" --region "$REGION" \
  --query 'collectionDetails[0].arn' --output text)
COLLECTION_ENDPOINT=$(aws opensearchserverless batch-get-collection --ids "$COLLECTION_ID" --region "$REGION" \
  --query 'collectionDetails[0].collectionEndpoint' --output text)
echo "Collection ARN: $COLLECTION_ARN"
echo "Collection endpoint: $COLLECTION_ENDPOINT"

echo ""
echo "=== SUMMARY (save these) ==="
echo "BUCKET_NAME       = $BUCKET_NAME"
echo "KB_ROLE_ARN       = $KB_ROLE_ARN"
echo "COLLECTION_ARN    = $COLLECTION_ARN"
echo "COLLECTION_ENDPOINT = $COLLECTION_ENDPOINT"
echo ""
echo "NEXT: create the vector index and the Knowledge Base itself — tunggu instruksi lanjutan dari Claude sebelum jalan lebih lanjut."
