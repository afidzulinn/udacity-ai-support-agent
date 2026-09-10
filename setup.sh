#!/usr/bin/env bash
# setup_aws.sh — configure AWS CLI from a "label \n value" style creds file
# Usage: ./setup_aws.sh [path/to/aws.txt]   (default: /voc/work/aws.txt)

set -euo pipefail

CRED_FILE="${1:-/voc/work/aws.txt}"
REGION="us-east-1"
PARSED_TMP="$(mktemp)"

cleanup() { rm -f "$PARSED_TMP"; }
trap cleanup EXIT

if [ ! -f "$CRED_FILE" ]; then
  echo "❌ File not found: $CRED_FILE"
  echo "   Usage: ./setup_aws.sh /path/to/aws.txt"
  exit 1
fi

echo "📄 Parsing credentials from: $CRED_FILE"

python3 - "$CRED_FILE" "$PARSED_TMP" << 'PYEOF'
import sys

src, dst = sys.argv[1], sys.argv[2]
with open(src) as f:
    lines = [l.strip() for l in f]

def find_value(labels):
    for i, line in enumerate(lines):
        low = line.lower()
        if any(low == lbl or low.startswith(lbl) for lbl in labels):
            for j in range(i + 1, len(lines)):
                if lines[j]:
                    return lines[j]
    return None

access_key    = find_value(["aws key id", "access key id", "aws_access_key_id", "access key"])
secret_key    = find_value(["secret key", "secret access key", "aws_secret_access_key"])
session_token = find_value(["session token", "aws_session_token"])

if not access_key or not secret_key:
    sys.exit("MISSING_REQUIRED_FIELDS")

with open(dst, "w") as out:
    out.write(f"ACCESS_KEY={access_key}\n")
    out.write(f"SECRET_KEY={secret_key}\n")
    if session_token:
        out.write(f"SESSION_TOKEN={session_token}\n")
PYEOF

if [ ! -s "$PARSED_TMP" ]; then
  echo "❌ Could not find access key / secret key in $CRED_FILE"
  echo "   Expected a label line followed by its value line, e.g.:"
  echo "     aws key id"
  echo "     ASIA..."
  exit 1
fi

# shellcheck disable=SC1090
source "$PARSED_TMP"

mkdir -p ~/.aws
aws configure set aws_access_key_id     "$ACCESS_KEY"
aws configure set aws_secret_access_key "$SECRET_KEY"
aws configure set region                "$REGION"
aws configure set output                json

if [ -n "${SESSION_TOKEN:-}" ]; then
  aws configure set aws_session_token "$SESSION_TOKEN"
  echo "🔑 Session token applied (temporary credentials — will expire, usually within a few hours)"
else
  aws configure set aws_session_token "" 2>/dev/null || true
fi

echo ""
echo "🔍 Verifying with aws sts get-caller-identity..."
if aws sts get-caller-identity; then
  echo ""
  echo "✅ SUCCESS — AWS CLI is configured."
else
  echo ""
  echo "❌ Still failing. Likely causes: expired session token, region mismatch, or a stray character copied into aws.txt."
  exit 1
fi