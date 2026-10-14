# AI Customer Support Agent — Amazon Bedrock AgentCore + Strands

Customer support agent deployed to **AgentCore Runtime**. It uses Gateway MCP tools
(order tracking via API Gateway, refunds via Lambda), a Bedrock Knowledge Base (RAG),
AgentCore Memory (cross-session recall), the Code Interpreter (loyalty discounts), and
the AgentCore Browser.

- Code: [`main.py`](main.py)
- Reflection (200–400 words): [`REFLECTION.md`](REFLECTION.md)
- Test screenshots: [`screenshots/`](screenshots/)

## Rubric → evidence

| Rubric criterion | Code | Test evidence |
|---|---|---|
| Deploy to cloud runtime | `app = BedrockAgentCoreApp()`, `@app.entrypoint async def invoke`, `app.run()` | All screenshots show `agentcore invoke` responses from the runtime ARN |
| MCP tools via Gateway | `MCPClient(streamable_http_client(GATEWAY_URL))`, `list_tools_sync()`, Gateway failure handling with `logger.exception` | `test1-order-tracking.png` (API Gateway target), `test2-refund.png` (Lambda target) |
| Code Interpreter | `calculate_loyalty_discount` → `code_session(REGION).invoke("executeCode", clearContext=True)` + fallback | `test5-loyalty-discount.png` |
| RAG | `search_knowledge_base` → `retrieve()`; chunks joined into one formatted string; KB_ID guard | `test3-knowledge-base.png` |
| Cross-session memory | `get_namespaces`, `MemoryHook` (`retrieve_customer_context`, `save_support_interaction`) | `test4a-memory-session-a.png`, `test4b-memory-session-b.png` |
| Browser tool | `AgentCoreBrowser(region=REGION)` → `agent_core_browser.browser` | `test6-browser.png` |
| Reflection | — | `REFLECTION.md` |

## Deploy

```bash
uv sync --python 3.13
uv run agentcore configure --entrypoint main.py --name customer_support_agent \
  --deployment-type direct_code_deploy --runtime PYTHON_3_13 --disable-memory
uv run agentcore deploy
uv run setup_permissions.py   # grants KB Retrieve, Memory and Browser to the runtime role
```

## Cleanup

`agentcore destroy`, then delete the Gateway, Memory, Knowledge Base, OpenSearch
Serverless collection, S3 bucket, REST API and both Lambda functions.
