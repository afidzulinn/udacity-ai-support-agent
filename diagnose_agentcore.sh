#!/usr/bin/env bash
set -uo pipefail

echo "=== 1. All 'agentcore' binaries found in PATH ==="
which -a agentcore 2>&1 || echo "(none found via 'which')"

echo ""
echo "=== 2. What the bare 'agentcore' command resolves to ==="
type agentcore 2>&1

echo ""
echo "=== 3. Version / identity of the bare 'agentcore' ==="
agentcore --version 2>&1 || echo "(no --version support)"

echo ""
echo "=== 4. Is bedrock-agentcore-starter-toolkit installed in the project venv? ==="
uv run pip show bedrock-agentcore-starter-toolkit 2>&1

echo ""
echo "=== 5. What 'uv run agentcore' resolves to (should be the venv's own copy) ==="
uv run which agentcore 2>&1

echo ""
echo "=== 6. Help output from 'uv run agentcore' — does it have 'configure'? ==="
uv run agentcore --help 2>&1

echo ""
echo "=== 7. Any globally npm-installed agentcore package? ==="
npm ls -g --depth=0 2>&1 | grep -i agentcore || echo "(none via npm, or npm not present)"

echo ""
echo "=== 8. Any pipx-installed agentcore package? ==="
pipx list 2>&1 | grep -i agentcore || echo "(none via pipx, or pipx not present)"

echo ""
echo "=== 9. Any other pip-installed agentcore-* packages globally (outside the venv)? ==="
pip list 2>&1 | grep -i agentcore || echo "(none found globally)"
