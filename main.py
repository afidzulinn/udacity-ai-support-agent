# """
# Customer Support AI Agent — Starter Code
# ==========================================
# Your task is to complete this file by implementing all sections marked
# with # TODO comments.

# Reference the step-by-step solution files and INSTRUCTIONS.md for guidance.
# Do NOT copy the solution directly — work through each section yourself.

# Run locally (after filling in config values):
#   uv run main.py '{"prompt": "Hello", "customer_id": "CUST-123", "session_id": "s1"}'

# Deploy to AgentCore:
#   agentcore deploy

# Invoke deployed agent:
#   agentcore invoke '{"prompt": "Hello", "customer_id": "CUST-123", "session_id": "s1"}'
# """

# # ── Imports ───────────────────────────────────────────────────────────────────
# # These imports are provided. Do not remove them.
# from strands import Agent, tool
# from bedrock_agentcore.runtime import BedrockAgentCoreApp
# from bedrock_agentcore.memory import MemoryClient
# from strands.models import BedrockModel
# from strands.tools.mcp.mcp_client import MCPClient
# from mcp.client.streamable_http import streamable_http_client
# import argparse, json
# import os, asyncio, boto3
# from strands.hooks import (
#     HookProvider, AfterInvocationEvent, HookRegistry, MessageAddedEvent,
# )
# import logging
# import uuid
# from typing import Dict
# from bedrock_agentcore.tools.code_interpreter_client import code_session
# from strands_tools.browser import AgentCoreBrowser


# logging.basicConfig(level=logging.WARNING)
# logger = logging.getLogger("CSAI_Agent")

# # ── TODO 1 — App Initialisation ───────────────────────────────────────────────
# # Create a BedrockAgentCoreApp instance.
# # This registers the ASGI server for AgentCore deployment.
# # There must be exactly one instance per deployment.
# #
# # Hint: app = BedrockAgentCoreApp()

# # TODO: Create the BedrockAgentCoreApp instance
# app = None  # Replace this line


# # Suppress interactive tool-consent prompts (required in headless deployments).
# os.environ["BYPASS_TOOL_CONSENT"] = "true"


# # ── TODO 2 — Configuration ────────────────────────────────────────────────────
# # Replace the placeholder strings with your actual AWS resource values.
# # You collected these in Part 1 of the INSTRUCTIONS.
# #
# # GATEWAY_URL format: https://<alias>.gateway.bedrock-agentcore.<region>.amazonaws.com/mcp
# # KB_ID       format: 10-character alphanumeric string from the KB console
# # REGION:     your AWS region, e.g. "us-east-1"
# # MEMORY_ID   format: shown in the AgentCore Memory console

# GATEWAY_URL = "<gateway_url>"   # TODO: Replace with your Gateway URL
# KB_ID       = "<kbid>"          # TODO: Replace with your Knowledge Base ID
# REGION      = "<region>"        # TODO: Replace with your AWS region
# MEMORY_ID   = "<mem_id>"        # TODO: Replace with your Memory ID


# # ── TODO 3 — Model and Clients ────────────────────────────────────────────────
# # Create:
# #   1. A BedrockModel using model_id "global.amazon.nova-2-lite-v1:0"
# #   2. A MemoryClient with region_name=REGION
# #   3. A boto3 client for the "bedrock-agent-runtime" service in REGION
# #
# # Hint: model = BedrockModel(model_id=model_id)

# model_id = "global.amazon.nova-2-lite-v1:0"

# # TODO: Create the BedrockModel instance
# model = None  # Replace this line

# # TODO: Create the MemoryClient instance
# memory_client = None  # Replace this line

# # TODO: Create the boto3 bedrock-agent-runtime client
# _bedrock_runtime = None  # Replace this line


# # ── TODO 4 — Namespace Helper ─────────────────────────────────────────────────
# # Implement get_namespaces() to return a dict mapping strategy type to
# # namespace template string.
# #
# # Steps:
# #   1. Call mem_client.get_memory_strategies(memory_id) to get strategy list
# #   2. Return a dict: { strategy["type"]: strategy["namespaces"][0] for each strategy }
# #
# # Example output:
# #   { "SEMANTIC": "cs_agent/{actorId}/facts",
# #     "USER_PREFERENCE": "cs_agent/{actorId}/preferences" }

# def get_namespaces(mem_client: MemoryClient, memory_id: str) -> Dict:
#     """Return a dict mapping strategy type → namespace template string."""
#     # TODO: Implement this function
#     pass


# # ── TODO 5 — Memory Hook ──────────────────────────────────────────────────────
# # Implement MemoryHook, a HookProvider subclass that adds long-term memory.
# #
# # The class needs:
# #   __init__(self, actor_id, session_id, memory_client, memory_id)
# #     — store all four as instance attributes
# #     — call get_namespaces() and store the result as self.namespaces
# #
# #   retrieve_customer_context(self, event: MessageAddedEvent)
# #     — only runs for plain-text user messages (not tool results)
# #     — for each strategy namespace, call memory_client.retrieve_memories(
# #          memory_id, namespace (formatted with actorId), query, top_k=5)
# #     — collect non-empty memory texts tagged with their strategy type
# #     — if any memories found, prepend them to the user message as:
# #          "Customer Context:\n<memories>\n\n<original_message>"
# #
# #   save_support_interaction(self, event: AfterInvocationEvent)
# #     — walk the message list backwards to find the last plain-text user
# #       query and the last assistant response
# #     — call memory_client.create_event(memory_id, actor_id, session_id,
# #          messages=[(customer_query, "USER"), (agent_response, "ASSISTANT")])
# #
# #   register_hooks(self, registry: HookRegistry)
# #     — register retrieve_customer_context on MessageAddedEvent
# #     — register save_support_interaction on AfterInvocationEvent

# class MemoryHook(HookProvider):
#     """Long-term memory hook for the customer support agent."""

#     def __init__(
#         self,
#         actor_id: str,
#         session_id: str,
#         memory_client: MemoryClient,
#         memory_id: str,
#     ):
#         # TODO: Store actor_id, session_id, memory_id, memory_client as attributes
#         # TODO: Call get_namespaces() and store the result as self.namespaces
#         pass

#     def retrieve_customer_context(self, event: MessageAddedEvent):
#         """Retrieve relevant memories and prepend them to the user message."""
#         # TODO: Implement memory retrieval
#         # Steps:
#         #   1. Get the last message from event.agent.messages
#         #   2. Check it is a user message and not a tool result
#         #   3. Extract the user query text
#         #   4. For each namespace in self.namespaces, call retrieve_memories()
#         #   5. Collect non-empty memory texts with strategy type tags
#         #   6. If any found, prepend them to the user message
#         pass

#     def save_support_interaction(self, event: AfterInvocationEvent):
#         """Save the completed turn to memory after the agent responds."""
#         # TODO: Implement memory saving
#         # Steps:
#         #   1. Get messages from event.agent.messages
#         #   2. Walk backwards to find the last user query (plain text)
#         #      and the last assistant response
#         #   3. Call memory_client.create_event() with both messages
#         pass

#     def register_hooks(self, registry: HookRegistry) -> None:  # type: ignore
#         """Register both memory callbacks."""
#         # TODO: Register retrieve_customer_context on MessageAddedEvent
#         # TODO: Register save_support_interaction on AfterInvocationEvent
#         pass


# # ── TODO 6 — Knowledge Base Tool ─────────────────────────────────────────────
# # Implement search_knowledge_base(query) using the @tool decorator.
# #
# # Steps:
# #   1. Guard: if KB_ID is empty return "Knowledge base not configured."
# #   2. Call _bedrock_runtime.retrieve(
# #          knowledgeBaseId=KB_ID,
# #          retrievalQuery={"text": query}
# #      )
# #   3. Extract resp["retrievalResults"]; return a message if empty
# #   4. Join the text chunks with "\n---\n" and return the result
# #
# # The docstring is the tool description — the model uses it to decide when
# # to call this tool, so keep it clear and accurate.

# @tool
# def search_knowledge_base(query: str) -> str:
#     """
#     Search the Amazon product catalog and support knowledge base.
#     Use this for product specifications, return policies, warranty
#     information, loyalty program details, and order status definitions.

#     Args:
#         query: The question or topic to search for

#     Returns:
#         Relevant information retrieved from the knowledge base
#     """
#     # TODO: Implement the Knowledge Base search
#     pass


# # ── TODO 7 — Loyalty Discount Tool (Code Interpreter) ────────────────────────
# # Implement calculate_loyalty_discount() using the @tool decorator.
# #
# # The tool must:
# #   1. Build a self-contained Python code string that:
# #        • Defines earn_rates: {"standard": 1, "device": 2, "fresh": 5}
# #        • Defines tier_rates: {"Silver": 0.00, "Gold": 0.10, "Platinum": 0.15}
# #        • Calculates points_redeemed (floor to nearest 500, cap at 50% of order)
# #        • Calculates tier_discount (applied to subtotal after points)
# #        • Calculates final_total, total_savings, points_earned, remaining_points
# #        • Prints a JSON result dict
# #   2. Execute the code with code_session(REGION).invoke("executeCode", {...})
# #      using language="python" and clearContext=True
# #   3. Return the first result event as a JSON string
# #   4. Include a fallback that computes only the tier discount if the
# #      Code Interpreter is unavailable

# @tool
# def calculate_loyalty_discount(
#     loyalty_points: int,
#     tier: str,
#     order_total: float,
#     product_category: str = "standard",
# ) -> str:
#     """
#     Calculate the loyalty discount for a customer order using the
#     AgentCore Code Interpreter. Runs exact arithmetic in a secure sandbox.

#     Args:
#         loyalty_points:   Customer's current points balance
#         tier:             Customer tier — Silver, Gold, or Platinum
#         order_total:      Order total in USD
#         product_category: standard, device, or fresh

#     Returns:
#         Full discount breakdown and final price
#     """
#     # TODO: Build the code string (use an f-string to inject the arguments)
#     code = ""  # Replace with your code string

#     try:
#         # TODO: Execute the code using code_session and return the result
#         pass

#     except Exception as e:
#         # TODO: Implement fallback calculation using tier discount only
#         pass


# # ── TODO 8 — Agent Entrypoint ─────────────────────────────────────────────────
# # Implement the invoke() function decorated with @app.entrypoint.
# #
# # Steps:
# #   1. Extract user_input, actor_id, and session_id from the payload
# #      (generate a UUID if session_id is missing)
# #   2. Instantiate MemoryHook for this actor/session
# #   3. Instantiate AgentCoreBrowser(region=REGION)
# #   4. Build the tools list: [search_knowledge_base, calculate_loyalty_discount,
# #                              agent_core_browser.browser]
# #   5. Connect to the Gateway via MCPClient, load gateway_tools, extend tools list
# #   6. Create and invoke the Agent with all tools, hooks, and system_prompt
# #   7. Return the text from the first content block of the response
# #   8. Handle exceptions gracefully

# @app.entrypoint
# async def invoke(payload, context=None):
#     """
#     Main handler called by AgentCore for every incoming request.

#     Expected payload keys:
#       prompt      (str, required) — the customer's message
#       customer_id (str, optional) — unique customer identifier
#       session_id  (str, optional) — session identifier; generated if absent
#     """
#     # TODO: Implement the agent invocation
#     pass


# # ── CLI entry point (do not modify) ──────────────────────────────────────────
# def main():
#     """Run one invocation from the command line for local testing."""
#     parser = argparse.ArgumentParser()
#     parser.add_argument("payload", type=str)
#     args = parser.parse_args()
#     response = asyncio.run(invoke(json.loads(args.payload)))
#     print(response)


# if __name__ == "__main__":
#     app.run()
#     # Uncomment the line below and comment app.run() for local CLI testing:
#     # main()

"""
Customer Support AI Agent
==========================
An AI customer support agent built on Amazon Bedrock AgentCore and the Strands SDK.

Capabilities:
  • Order tracking and refunds  — Lambda tools exposed through AgentCore Gateway (MCP)
  • Product / policy answers    — RAG over a Bedrock Knowledge Base
  • Cross-session recall        — AgentCore Memory with semantic + preference strategies
  • Exact discount arithmetic   — AgentCore Code Interpreter sandbox
  • Live web access             — AgentCore Browser tool

Run locally:
  uv run main.py '{"prompt": "Hello", "customer_id": "CUST-123", "session_id": "s1"}'

Deploy to AgentCore:
  agentcore configure --entrypoint main.py --name customer_support_agent
  agentcore deploy

Invoke deployed agent:
  agentcore invoke '{"prompt": "Hello", "customer_id": "CUST-123", "session_id": "s1"}'
"""

# ── Imports ───────────────────────────────────────────────────────────────────
# These imports are provided. Do not remove them.
from strands import Agent, tool
from bedrock_agentcore.runtime import BedrockAgentCoreApp
from bedrock_agentcore.memory import MemoryClient
from strands.models import BedrockModel
from strands.tools.mcp.mcp_client import MCPClient
from mcp.client.streamable_http import streamable_http_client
import argparse, json
import os, asyncio, boto3
from strands.hooks import (
    HookProvider, AfterInvocationEvent, HookRegistry, MessageAddedEvent,
)
import logging
import uuid
from typing import Dict
from bedrock_agentcore.tools.code_interpreter_client import code_session
from strands_tools.browser import AgentCoreBrowser


logging.basicConfig(level=logging.WARNING)
logger = logging.getLogger("CSAI_Agent")

# ── TODO 1 — App Initialisation ───────────────────────────────────────────────
# The BedrockAgentCoreApp registers the ASGI server that AgentCore Runtime talks
# to. Exactly one instance per deployment; it must exist before @app.entrypoint
# is evaluated further down the module.

app = BedrockAgentCoreApp()


# Suppress interactive tool-consent prompts (required in headless deployments).
os.environ["BYPASS_TOOL_CONSENT"] = "true"


# ── TODO 2 — Configuration ────────────────────────────────────────────────────
# AWS resource identifiers collected during infrastructure setup.

GATEWAY_URL = "https://customersupportgateway-ygvxwmxcph.gateway.bedrock-agentcore.us-east-1.amazonaws.com/mcp"
KB_ID       = "YRNE2IQUMS"
REGION      = "us-east-1"
MEMORY_ID   = "CustomerSupportMemory-G4A5HB2eLL"


# ── TODO 3 — Model and Clients ────────────────────────────────────────────────
# model            — the LLM the Strands Agent reasons with
# memory_client    — high-level AgentCore Memory SDK client (retrieve / create_event)
# _bedrock_runtime — raw boto3 client for the Knowledge Base Retrieve API

model_id = "global.amazon.nova-2-lite-v1:0"

model = BedrockModel(model_id=model_id)

memory_client = MemoryClient(region_name=REGION)

_bedrock_runtime = boto3.client("bedrock-agent-runtime", region_name=REGION)


# ── TODO 4 — Namespace Helper ─────────────────────────────────────────────────
# Reads the namespace template for every strategy configured on the memory
# resource, keyed by strategy type. Newer API versions return the template under
# "namespaceTemplates"; older ones use "namespaces", so both are handled.
#
# Example output:
#   { "SEMANTIC": "cs_agent/{actorId}/facts",
#     "USER_PREFERENCE": "cs_agent/{actorId}/preferences" }

def get_namespaces(mem_client: MemoryClient, memory_id: str) -> Dict:
    """Return a dict mapping strategy type → namespace template string."""
    try:
        strategies = mem_client.get_memory_strategies(memory_id)
    except Exception as e:
        logger.warning("Could not load memory strategies: %s", e)
        return {}

    namespaces = {}
    for strategy in strategies:
        strategy_type = strategy.get("type") or strategy.get("memoryStrategyType")
        # Prefer the current field name, fall back to the legacy one.
        templates = strategy.get("namespaceTemplates") or strategy.get("namespaces") or []
        if strategy_type and templates:
            namespaces[strategy_type] = templates[0]

    logger.info("Loaded namespaces: %s", namespaces)
    return namespaces


# ── TODO 5 — Memory Hook ──────────────────────────────────────────────────────
# Wires long-term memory into the agent's lifecycle:
#   • before the model answers  → inject relevant memories into the user message
#   • after the model answers   → persist the (user, assistant) turn as an event
#
# AgentCore extracts long-term memory records from saved events asynchronously,
# which is why recall in a *new* session needs a short delay after the first one.

class MemoryHook(HookProvider):
    """Long-term memory hook for the customer support agent."""

    def __init__(
        self,
        actor_id: str,
        session_id: str,
        memory_client: MemoryClient,
        memory_id: str,
    ):
        self.actor_id = actor_id
        self.session_id = session_id
        self.memory_client = memory_client
        self.memory_id = memory_id
        self.namespaces = get_namespaces(memory_client, memory_id)

    def retrieve_customer_context(self, event: MessageAddedEvent):
        """Retrieve relevant memories and prepend them to the user message."""
        messages = event.agent.messages
        if not messages:
            return

        last_message = messages[-1]

        # Only act on plain-text user messages. Tool results are also delivered
        # with role "user", so they are filtered out explicitly.
        if last_message.get("role") != "user":
            return
        content = last_message.get("content") or []
        if not content or "text" not in content[0]:
            return

        user_query = content[0]["text"]

        try:
            all_context = []

            for strategy_type, namespace_template in self.namespaces.items():
                namespace = namespace_template.replace("{actorId}", self.actor_id)

                memories = self.memory_client.retrieve_memories(
                    memory_id=self.memory_id,
                    namespace=namespace,
                    query=user_query,
                    top_k=5,
                )

                for memory in memories:
                    if not isinstance(memory, dict):
                        continue
                    memory_content = memory.get("content")
                    if isinstance(memory_content, dict):
                        text = memory_content.get("text", "").strip()
                        if text:
                            # Tag each memory with the strategy that produced it
                            # so the model knows whether it is a fact or a preference.
                            all_context.append(f"[{strategy_type}] {text}")

            if all_context:
                context_text = "\n".join(all_context)
                last_message["content"][0]["text"] = (
                    f"Customer Context:\n{context_text}\n\n{user_query}"
                )
                logger.info("Injected %d memories into the user message", len(all_context))

        except Exception as e:
            logger.error("Failed to retrieve customer context: %s", e)

    def save_support_interaction(self, event: AfterInvocationEvent):
        """Save the completed turn to memory after the agent responds."""
        try:
            messages = event.agent.messages
            if not messages:
                return

            customer_query = None
            agent_response = None

            # Walk backwards: the assistant reply comes last, the user query
            # that triggered it is the closest plain-text user message before it.
            for message in reversed(messages):
                content = message.get("content") or []
                if not content or "text" not in content[0]:
                    continue

                if agent_response is None and message.get("role") == "assistant":
                    agent_response = content[0]["text"]
                elif customer_query is None and message.get("role") == "user":
                    customer_query = content[0]["text"]

                if customer_query and agent_response:
                    break

            if customer_query and agent_response:
                self.memory_client.create_event(
                    memory_id=self.memory_id,
                    actor_id=self.actor_id,
                    session_id=self.session_id,
                    messages=[
                        (customer_query, "USER"),
                        (agent_response, "ASSISTANT"),
                    ],
                )
                logger.info("Saved interaction to memory for actor %s", self.actor_id)

        except Exception as e:
            logger.error("Failed to save support interaction: %s", e)

    def register_hooks(self, registry: HookRegistry) -> None:  # type: ignore
        """Register both memory callbacks."""
        registry.add_callback(MessageAddedEvent, self.retrieve_customer_context)
        registry.add_callback(AfterInvocationEvent, self.save_support_interaction)


# ── TODO 6 — Knowledge Base Tool ─────────────────────────────────────────────
# Grounds the agent's product and policy answers in the Bedrock Knowledge Base
# instead of the model's parametric knowledge.

@tool
def search_knowledge_base(query: str) -> str:
    """
    Search the Amazon product catalog and support knowledge base.
    Use this for product specifications, return policies, warranty
    information, loyalty program details, and order status definitions.

    Args:
        query: The question or topic to search for

    Returns:
        Relevant information retrieved from the knowledge base
    """
    # Guard clause: without a configured KB there is nothing to search.
    if not KB_ID or KB_ID.startswith("<"):
        return "Knowledge base not configured."

    try:
        resp = _bedrock_runtime.retrieve(
            knowledgeBaseId=KB_ID,
            retrievalQuery={"text": query},
        )

        results = resp.get("retrievalResults", [])
        if not results:
            return f"No information found in the knowledge base for: {query}"

        chunks = [
            r["content"]["text"]
            for r in results
            if r.get("content", {}).get("text")
        ]
        if not chunks:
            return f"No information found in the knowledge base for: {query}"

        return "\n---\n".join(chunks)

    except Exception as e:
        logger.error("Knowledge base search failed: %s", e)
        return f"Knowledge base search failed: {e}"


# ── TODO 7 — Loyalty Discount Tool (Code Interpreter) ────────────────────────
# Loyalty arithmetic has compounding rules (points floor, 50% cap, tier discount
# on the post-points subtotal) that an LLM can easily get subtly wrong. The rules
# are therefore encoded as Python and executed in the AgentCore sandbox, so the
# numbers are computed rather than predicted.

@tool
def calculate_loyalty_discount(
    loyalty_points: int,
    tier: str,
    order_total: float,
    product_category: str = "standard",
) -> str:
    """
    Calculate the loyalty discount for a customer order using the
    AgentCore Code Interpreter. Runs exact arithmetic in a secure sandbox.

    Args:
        loyalty_points:   Customer's current points balance
        tier:             Customer tier — Silver, Gold, or Platinum
        order_total:      Order total in USD
        product_category: standard, device, or fresh

    Returns:
        Full discount breakdown and final price
    """
    code = f"""
import json

# ── Business rules (from the loyalty programme in the product catalogue) ──
earn_rates = {{"standard": 1, "device": 2, "fresh": 5}}
tier_rates = {{"Silver": 0.00, "Gold": 0.10, "Platinum": 0.15}}

loyalty_points   = {int(loyalty_points)}
tier             = "{tier}"
order_total      = {float(order_total)}
product_category = "{product_category}"

# ── Points redemption: 100 points = $1, minimum 500, floor to a 500 multiple,
#    and never worth more than 50% of the order total. ──
max_discount_from_points = order_total * 0.50
max_points_usable = int(max_discount_from_points * 100)

usable_points = min(loyalty_points, max_points_usable)
points_redeemed = (usable_points // 500) * 500
if points_redeemed < 500:
    points_redeemed = 0

points_value = round(points_redeemed / 100.0, 2)

# ── Tier discount applies to what is left after points are redeemed. ──
subtotal_after_points = round(order_total - points_value, 2)
tier_discount_pct = tier_rates.get(tier, 0.00)
tier_discount_amount = round(subtotal_after_points * tier_discount_pct, 2)

final_total   = round(subtotal_after_points - tier_discount_amount, 2)
total_savings = round(points_value + tier_discount_amount, 2)

# ── Points earned on what the customer actually pays. ──
earn_rate     = earn_rates.get(product_category, 1)
points_earned = int(final_total * earn_rate)

remaining_points = loyalty_points - points_redeemed + points_earned

result = {{
    "order_total": round(order_total, 2),
    "tier": tier,
    "product_category": product_category,
    "points_redeemed": points_redeemed,
    "points_value_usd": points_value,
    "subtotal_after_points": subtotal_after_points,
    "tier_discount_pct": round(tier_discount_pct * 100, 2),
    "tier_discount_amount": tier_discount_amount,
    "final_total": final_total,
    "total_savings": total_savings,
    "points_earned": points_earned,
    "remaining_points": remaining_points,
}}

print(json.dumps(result, indent=2))
"""

    try:
        with code_session(REGION) as code_client:
            response = code_client.invoke(
                "executeCode",
                {
                    "code": code,
                    "language": "python",
                    "clearContext": True,
                },
            )

            # The sandbox streams result events; the first one carries the output.
            for event in response["stream"]:
                return json.dumps(event["result"])

        return "Code interpreter returned no result."

    except Exception as e:
        # Fallback: tier discount only, so the agent can still answer if the
        # sandbox is unavailable. Points redemption is deliberately skipped here
        # to avoid quoting a discount that was never actually validated.
        logger.error("Code interpreter unavailable, using fallback: %s", e)

        tier_rates = {"Silver": 0.00, "Gold": 0.10, "Platinum": 0.15}
        tier_discount_pct = tier_rates.get(tier, 0.00)
        tier_discount_amount = round(order_total * tier_discount_pct, 2)
        final_total = round(order_total - tier_discount_amount, 2)

        return json.dumps({
            "order_total": round(order_total, 2),
            "tier": tier,
            "points_redeemed": 0,
            "tier_discount_pct": round(tier_discount_pct * 100, 2),
            "tier_discount_amount": tier_discount_amount,
            "final_total": final_total,
            "total_savings": tier_discount_amount,
            "points_earned": 0,
            "remaining_points": loyalty_points,
            "note": (
                "Code interpreter unavailable — tier discount only, "
                "points redemption not applied."
            ),
        })


SYSTEM_PROMPT = """You are a helpful customer support agent for an Amazon-style e-commerce store.

You can:
- Look up orders, customer profiles, and order history through the order tracking tools.
- Initiate refunds, check refund status, and generate return labels through the refund tools.
- Answer product, warranty, return-policy, and loyalty-programme questions using search_knowledge_base.
- Compute exact loyalty discounts using calculate_loyalty_discount.
- Browse live web pages when the customer asks about something on the public internet.

Guidelines:
- Always call a tool when the answer depends on live data, stored policy, or arithmetic.
  Never guess an order status, a policy detail, or a discount figure.
- When a "Customer Context:" block appears before a question, treat it as things you
  already know about this customer from previous conversations, and use it naturally.
- Report tool results faithfully: quote tracking numbers, refund IDs, and totals exactly
  as returned.
- Be clear, concise, and friendly.
"""


# ── TODO 8 — Agent Entrypoint ─────────────────────────────────────────────────
# Called by AgentCore Runtime for every request. Assembles the full tool set —
# local @tool functions, the browser, and the MCP tools loaded from the Gateway —
# then runs one agent turn with the memory hook attached.

@app.entrypoint
async def invoke(payload, context=None):
    """
    Main handler called by AgentCore for every incoming request.

    Expected payload keys:
      prompt      (str, required) — the customer's message
      customer_id (str, optional) — unique customer identifier
      session_id  (str, optional) — session identifier; generated if absent
    """
    user_input = payload.get("prompt", "")
    actor_id   = payload.get("customer_id", "default_customer")
    session_id = payload.get("session_id") or str(uuid.uuid4())

    if not user_input:
        return "No prompt provided."

    try:
        memory_hook = MemoryHook(
            actor_id=actor_id,
            session_id=session_id,
            memory_client=memory_client,
            memory_id=MEMORY_ID,
        )

        agent_core_browser = AgentCoreBrowser(region=REGION)

        tools = [
            search_knowledge_base,
            calculate_loyalty_discount,
            agent_core_browser.browser,
        ]

        def create_transport():
            return streamable_http_client(GATEWAY_URL)

        gateway_client = MCPClient(create_transport)

        # The MCP session must stay open for the whole agent turn, because the
        # Gateway tools are invoked lazily during the model's reasoning loop.
        with gateway_client:
            gateway_tools = gateway_client.list_tools_sync()
            logger.info("Loaded %d tools from the Gateway", len(gateway_tools))
            tools.extend(gateway_tools)

            agent = Agent(
                model=model,
                tools=tools,
                hooks=[memory_hook],
                system_prompt=SYSTEM_PROMPT,
            )

            response = agent(user_input)

        return response.message["content"][0]["text"]

    except Exception as e:
        logger.exception("Agent invocation failed")
        return f"An error occurred while handling your request: {e}"


# ── CLI entry point (do not modify) ──────────────────────────────────────────
def main():
    """Run one invocation from the command line for local testing."""
    parser = argparse.ArgumentParser()
    parser.add_argument("payload", type=str)
    args = parser.parse_args()
    response = asyncio.run(invoke(json.loads(args.payload)))
    print(response)


if __name__ == "__main__":
    app.run()
    # Uncomment the line below and comment app.run() for local CLI testing:
    # main()