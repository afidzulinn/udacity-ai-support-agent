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
