"""Ejemplo 2: darle al agente una herramienta escrita en Python."""

import asyncio

from claude_agent_sdk import ClaudeAgentOptions, create_sdk_mcp_server, tool

from agentes import MODELO, ejecutar_agente

# Tus datos o sistemas reales irían aquí (una base de datos, una API...).
INVENTARIO = {"teclado": 12, "ratón": 0, "monitor": 4}


@tool("consultar_stock", "Devuelve las unidades disponibles de un producto", {"producto": str})
async def consultar_stock(args: dict) -> dict:
    producto = args["producto"].lower()
    if producto not in INVENTARIO:
        return {"content": [{"type": "text", "text": f"No existe '{producto}'."}], "is_error": True}
    return {"content": [{"type": "text", "text": f"{producto}: {INVENTARIO[producto]} unidades"}]}


servidor = create_sdk_mcp_server(name="tienda", tools=[consultar_stock])

opciones = ClaudeAgentOptions(
    model=MODELO,
    system_prompt="Eres el asistente de una tienda. Usa consultar_stock antes de responder.",
    mcp_servers={"tienda": servidor},
    # Las herramientas propias se llaman mcp__<servidor>__<herramienta>
    allowed_tools=["mcp__tienda__consultar_stock"],
    max_turns=5,
)

if __name__ == "__main__":
    asyncio.run(ejecutar_agente("¿Tenemos ratones y monitores disponibles?", opciones))
