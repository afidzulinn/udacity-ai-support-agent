#!/usr/bin/env bash
# =============================================================================
# setup_git.sh — initialise the repo, verify no secrets are staged, and commit
#
# Usage:
#   bash setup_git.sh
#   # then follow the printed instructions to add your remote and push
# =============================================================================
set -uo pipefail

cd "$(dirname "$0")"

echo "=== 1. Safety check — make sure .gitignore exists ==="
if [ ! -f ".gitignore" ]; then
  echo "❌ .gitignore missing. Add it before running this script."
  exit 1
fi
echo "✅ .gitignore present"

echo ""
echo "=== 2. Initialise repo (if needed) ==="
if [ -d ".git" ]; then
  echo "Repo already initialised."
else
  git init
  git branch -M main
fi

echo ""
echo "=== 3. Stage files ==="
git add -A

echo ""
echo "=== 4. SECRET SCAN — verifying nothing sensitive is staged ==="
LEAKS=0

check_staged() {
  local PATTERN="$1"
  local LABEL="$2"
  if git diff --cached --name-only | grep -qE "$PATTERN"; then
    echo "❌ DANGER: $LABEL is staged!"
    git diff --cached --name-only | grep -E "$PATTERN"
    LEAKS=1
  fi
}

check_staged '(^|/)aws\.txt$'              "aws.txt (AWS credentials)"
check_staged '(^|/)\.aws/'                 ".aws directory"
check_staged '(^|/)credentials$'           "credentials file"
check_staged '\.bedrock_agentcore\.yaml$'  ".bedrock_agentcore.yaml"
check_staged '\.pem$|\.key$'               "private key file"

# Scan staged file *contents* for AWS key patterns.
if git diff --cached | grep -qE '(ASIA|AKIA)[A-Z0-9]{16}'; then
  echo "❌ DANGER: an AWS access key ID pattern was found in staged content!"
  git diff --cached | grep -nE '(ASIA|AKIA)[A-Z0-9]{16}' | head -5
  LEAKS=1
fi

if [ "$LEAKS" -eq 1 ]; then
  echo ""
  echo "Aborting. Unstage the offending files, fix .gitignore, and re-run:"
  echo "  git reset"
  exit 1
fi
echo "✅ No credentials detected in staged files"

echo ""
echo "=== 5. Files that will be committed ==="
git diff --cached --name-only

echo ""
echo "=== 6. Commit ==="
git -c user.email="you@example.com" -c user.name="Your Name" \
  commit -m "Customer support AI agent with Bedrock AgentCore and Strands SDK" \
  || echo "(nothing new to commit)"

echo ""
echo "============================================================"
echo "✅ Local commit done. Next steps:"
echo ""
echo "1. Create a NEW PUBLIC repo on github.com (no README, no .gitignore)"
echo "2. Then run, replacing the URL with yours:"
echo ""
echo "   git remote add origin https://github.com/<username>/<repo>.git"
echo "   git push -u origin main"
echo ""
echo "3. Open the repo in a browser and confirm aws.txt is NOT there."
echo "4. Submit the repo URL on the Udacity submission page"
echo "   (use the 'Public GitHub Repository' tab, not the zip upload)."
echo "============================================================"
