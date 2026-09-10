#!/usr/bin/env bash
set -uo pipefail

GATEWAY_URL="https://customersupportgateway-ygvxwmxcph.gateway.bedrock-agentcore.us-east-1.amazonaws.com/mcp"

echo "############################################################"
echo "# PART 1 — Fix uv PATH and verify the correct agentcore CLI"
echo "############################################################"

echo ""
echo "=== 1. Locate uv ==="
UV_BIN=""
if [ -x "$HOME/.local/bin/uv" ]; then
  UV_BIN="$HOME/.local/bin/uv"
  echo "Found existing uv at $UV_BIN"
else
  echo "uv not found — installing..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  UV_BIN="$HOME/.local/bin/uv"
fi

if [ ! -x "$UV_BIN" ]; then
  echo "❌ Still could not find uv after install. Check the install output above."
  exit 1
fi

echo ""
echo "=== 2. Make uv permanent for future terminals (~/.bashrc) ==="
if ! grep -q '.local/bin' "$HOME/.bashrc" 2>/dev/null; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
  echo "Added ~/.local/bin to PATH in ~/.bashrc"
else
  echo "~/.local/bin already referenced in ~/.bashrc"
fi

export PATH="$HOME/.local/bin:$PATH"

echo ""
echo "=== 3. uv version ==="
uv --version

echo ""
echo "=== 4. uv sync (installs bedrock-agentcore-starter-toolkit into .venv) ==="
cd "$HOME/Project_starter"
uv sync

echo ""
echo "=== 5. Confirm bedrock-agentcore-starter-toolkit is in the venv ==="
uv run pip show bedrock-agentcore-starter-toolkit

echo ""
echo "=== 6. Confirm 'uv run agentcore' resolves to the venv copy, not /usr/local/bin ==="
uv run which agentcore

echo ""
echo "=== 7. Confirm it is the RIGHT CLI (must show 'configure', 'deploy', 'invoke', 'destroy') ==="
uv run agentcore --help

echo ""
echo "############################################################"
echo "# PART 2 — Verify AgentCore Gateway MCP tools"
echo "############################################################"

echo ""
echo "=== 8. Install playwright browser (needed later for Test 6, doing it now) ==="
uv run playwright install chromium

echo ""
echo "=== 9. Write the MCP tool-listing test script ==="
mkdir -p "$HOME/Project_starter/deploy"
cat > "$HOME/Project_starter/deploy/test_gateway_tools.py" << 'PYEOF'
import sys
from strands.tools.mcp.mcp_client import MCPClient
from mcp.client.streamable_http import streamable_http_client

gateway_url = sys.argv[1]

def create_transport():
    return streamable_http_client(gateway_url)

client = MCPClient(create_transport)
with client:
    tools = client.list_tools_sync()
    print(f"Found {len(tools)} tools:")
    for t in tools:
        print(" -", t.tool_name)
PYEOF

echo ""
echo "=== 10. Run the MCP tool-listing test against the Gateway ==="
uv run python "$HOME/Project_starter/deploy/test_gateway_tools.py" "$GATEWAY_URL"

echo ""
echo "============================================================"
echo "✅ DONE. Check above:"
echo "  - Step 7 must show 'configure' / 'deploy' / 'invoke' / 'destroy'"
echo "  - Step 10 must show 6 tools (3 order-tracker___*, 3 refund-processor___*)"
echo "============================================================"
