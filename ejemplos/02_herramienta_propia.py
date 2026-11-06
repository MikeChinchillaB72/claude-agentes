"""Ejemplo 2: darle al agente una herramienta escrita en Python.

Su configuración está en config/agentes/ejemplo_herramienta_propia.toml y el
inventario de prueba en config/datos/inventario_ejemplo.toml.
"""

import asyncio

from claude_agent_sdk import create_sdk_mcp_server, tool

from agentes import cargar, ejecutar_agente, opciones_de_agente
from agentes.configuracion import leer_toml, ruta_de_datos

agente = cargar("ejemplo_herramienta_propia")

# En un agente real, los datos vendrían de tu sistema (base de datos, API...).
INVENTARIO: dict[str, int] = leer_toml(ruta_de_datos(agente, "inventario"))["productos"]


@tool("consultar_stock", "Devuelve las unidades disponibles de un producto", {"producto": str})
async def consultar_stock(args: dict) -> dict:
    """Devuelve las unidades de `producto`, o un error si no existe en el inventario."""
    producto = args["producto"].lower()
    if producto not in INVENTARIO:
        return {"content": [{"type": "text", "text": f"No existe '{producto}'."}], "is_error": True}
    return {"content": [{"type": "text", "text": f"{producto}: {INVENTARIO[producto]} unidades"}]}


servidor = create_sdk_mcp_server(name="tienda", tools=[consultar_stock])

if __name__ == "__main__":
    opciones = opciones_de_agente(agente, mcp_servers={"tienda": servidor})
    asyncio.run(ejecutar_agente(agente.peticion_por_defecto, opciones, agente=agente.nombre, version=agente.version))
