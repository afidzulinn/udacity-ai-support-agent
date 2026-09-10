#!/usr/bin/env bash
set -euo pipefail

aws bedrock-agent-runtime retrieve \
  --knowledge-base-id YRNE2IQUMS \
  --retrieval-query '{"text": "What is the return policy for electronics?"}' \
  --region us-east-1
