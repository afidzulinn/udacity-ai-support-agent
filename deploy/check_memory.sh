#!/usr/bin/env bash
set -euo pipefail
aws bedrock-agentcore-control get-memory \
  --memory-id CustomerSupportMemory-G4A5HB2eLL \
  --region us-east-1 \
  --query 'memory.strategies' \
  --no-cli-pager
