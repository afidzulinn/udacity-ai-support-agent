#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

cat > .gitignore << 'EOF'
# ── AWS credentials — NEVER commit these ─────────────────────────────────────
aws.txt
.aws/
credentials
*.pem
*.key

# ── AgentCore deployment config (contains account-specific ARNs) ─────────────
.bedrock_agentcore.yaml
Dockerfile
.dockerignore

# ── Generated IAM / target policy documents ──────────────────────────────────
deploy/*.json

# ── Python ───────────────────────────────────────────────────────────────────
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
.venv/
venv/
env/
*.egg-info/
dist/
build/
uv.lock

# ── Editors / OS ─────────────────────────────────────────────────────────────
.vscode/
.idea/
.DS_Store
Thumbs.db

# ── Misc ─────────────────────────────────────────────────────────────────────
*.log
*.zip
.env
EOF

echo "✅ .gitignore created at $(pwd)/.gitignore"
echo ""
echo "=== Verifying it will actually catch aws.txt ==="
if [ -f "aws.txt" ]; then
  echo "aws.txt exists in this folder — checking git ignore status..."
  git check-ignore -v aws.txt 2>&1 && echo "✅ aws.txt WILL be ignored" || echo "⚠️  aws.txt NOT ignored (git repo may not be initialised yet — that's fine, check again after setup_git.sh runs git init)"
else
  echo "(aws.txt not found in this folder — good, or it lives elsewhere like /voc/work/aws.txt)"
fi

echo ""
echo "Now run: bash setup_git.sh"
