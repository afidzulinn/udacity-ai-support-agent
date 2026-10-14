#!/usr/bin/env bash
# Configures AWS CLI from the lab's aws.txt, then lists the project resources
# so we can see whether the IDs in main.py are still valid.
set -u

CRED=$(find ~ /home -maxdepth 3 -name aws.txt 2>/dev/null | head -1)
if [ -z "$CRED" ]; then
  echo "aws.txt not found"; exit 1
fi
echo "Using credentials from $CRED"

# aws.txt layout: line 2 = access key, line 5 = secret key, line 8 = session token
aws configure set aws_access_key_id     "$(sed -n 2p "$CRED" | tr -d '\r ')"
aws configure set aws_secret_access_key "$(sed -n 5p "$CRED" | tr -d '\r ')"
aws configure set aws_session_token     "$(sed -n 8p "$CRED" | tr -d '\r ')"
aws configure set region us-east-1

echo; echo "== Identity";       aws sts get-caller-identity --query Account --output text
echo; echo "== Gateways";       aws bedrock-agentcore-control list-gateways --query "items[].[name,gatewayId,status]" --output table
echo; echo "== Memories";       aws bedrock-agentcore-control list-memories --query "memories[].[id,status]" --output table
echo; echo "== Knowledge bases"; aws bedrock-agent list-knowledge-bases --query "knowledgeBaseSummaries[].[name,knowledgeBaseId,status]" --output table
echo; echo "== Lambda";         aws lambda list-functions --query "Functions[].FunctionName" --output table
echo; echo "== Expected by main.py"; grep -E '^(GATEWAY_URL|KB_ID|MEMORY_ID) ' "$(dirname "$0")/main.py"
