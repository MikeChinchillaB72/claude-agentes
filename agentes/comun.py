"""Configuración común y un ejecutor que muestra lo que hace el agente."""

import os

from dotenv import load_dotenv
from claude_agent_sdk import (
    AssistantMessage,
    ClaudeAgentOptions,
    ResultMessage,
    TextBlock,
    ToolUseBlock,
    query,
)

load_dotenv()

MODELO = os.getenv("AGENTE_MODELO", "claude-opus-5-5")


async def ejecutar_agente(prompt: str, opciones: ClaudeAgentOptions) -> str | None:
    """Lanza el agente, imprime su progreso y devuelve el resultado final."""
    resultado = None
    async for mensaje in query(prompt=prompt, options=opciones):
        if isinstance(mensaje, AssistantMessage):
            for bloque in mensaje.content:
                if isinstance(bloque, TextBlock):
                    print(bloque.text)
                elif isinstance(bloque, ToolUseBlock):
                    print(f"  -> usando herramienta: {bloque.name}")
        elif isinstance(mensaje, ResultMessage):
            resultado = mensaje.result
            coste = mensaje.total_cost_usd or 0
            print(f"\n[fin] turnos={mensaje.num_turns} coste=${coste:.4f}")
            if mensaje.is_error:
                print(f"[error] {mensaje.subtype}: {mensaje.errors}")
    return resultado
