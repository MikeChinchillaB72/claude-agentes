"""Ejemplo 1: agente que lee y explica los archivos de una carpeta."""

import asyncio

from claude_agent_sdk import ClaudeAgentOptions

from agentes import MODELO, ejecutar_agente

opciones = ClaudeAgentOptions(
    model=MODELO,
    system_prompt="Eres un analista de código. Responde en español.",
    allowed_tools=["Read", "Glob", "Grep"],
    max_turns=8,
)

if __name__ == "__main__":
    asyncio.run(ejecutar_agente("Explica en 5 líneas qué hace este proyecto.", opciones))
