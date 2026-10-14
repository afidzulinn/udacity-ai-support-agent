#!/usr/bin/env bash
# Installs dependencies, deploys the agent to AgentCore Runtime and grants the
# runtime role access to the Knowledge Base, Memory and Browser.
# Usage: bash deploy.sh [agent-name]   (default: customer_support_agent)
set -e
cd "$(dirname "$0")"
NAME="${1:-customer_support_agent}"
export AGENTCORE_SUPPRESS_RECOMMENDATION=1

if ! command -v uv >/dev/null; then
  pip install --user uv
  export PATH="$HOME/.local/bin:$PATH"
fi

echo "== 1/4 Installing dependencies"
uv sync --python 3.13

echo "== 2/4 Configuring (press Enter to accept the defaults)"
uv run agentcore configure --entrypoint main.py --name "$NAME" \
  --deployment-type direct_code_deploy --runtime PYTHON_3_13 --disable-memory

echo "== 3/4 Deploying"
uv run agentcore deploy

echo "== 4/4 Granting KB / Memory / Browser permissions"
uv run setup_permissions.py

echo "Waiting 30s for IAM permissions to propagate..."
sleep 30
echo "Done. Next: bash run_tests.sh"
