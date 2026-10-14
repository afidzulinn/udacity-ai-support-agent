# Reflection — AI Customer Support Agent

## Design decision: AgentCore Code Interpreter for loyalty discounts

For the `calculate_loyalty_discount` tool I chose to encode the business rules as a
self-contained Python string and execute it in the AgentCore Code Interpreter
(`code_session(REGION).invoke("executeCode", ..., clearContext=True)`) instead of
letting Nova Lite do the maths. The rules compound: points are floored to a multiple
of 500, capped at 50% of the order, and the tier discount applies to the subtotal
*after* points. A language model can produce a plausible but wrong total, which in
customer support means a broken promise. Running the arithmetic in a sandbox gives
an exact, reproducible answer (Gold, 4,250 points, $150 → 4,000 points redeemed,
10% tier discount, $99.00 final total, 349 points remaining). `clearContext=True`
keeps every calculation isolated from the previous one. A tier-only fallback still
lets the agent answer if the sandbox is unavailable.

## Challenge: tests passed locally but RAG, memory and browser failed after deploy

After my first deployment, order tracking, refunds and discounts worked, but the
Knowledge Base test returned a generic answer, the second memory session could not
recall "Jane", and the browser test said it was restricted. All three were
permission problems in the runtime execution role, not code bugs. The memory case
was subtle: `agentcore configure` without `--disable-memory` had created a second
memory resource and scoped the role to it, while `main.py` pointed at
`CustomerSupportMemory`. I resolved it by redeploying with `--disable-memory`, then
running `setup_permissions.py`, which grants `bedrock:Retrieve` on my KB, memory
read/write on my memory ID, and browser-session actions. I confirmed each fix in the
CloudWatch runtime logs before re-running the six tests.

## Production consideration: securing and monitoring the Gateway

The Gateway currently uses the `NONE` authorizer, which is acceptable only in a
temporary lab. In production, anyone with the URL could trigger refunds. I would
switch to a Cognito (JWT) or IAM authorizer, pass the customer's identity through
AgentCore Identity, and have the refund Lambda verify that the order belongs to the
caller. For monitoring, the agent now logs Gateway failures with `logger.exception`
and degrades gracefully. I would add a CloudWatch metric filter on those errors with
an alarm (for example, more than 5 in 5 minutes), plus per-customer rate limits on
`refund_processor` to cap cost and abuse.
