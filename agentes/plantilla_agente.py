"""Plantilla: copia este archivo para crear un agente nuevo.

Uso:  python -m agentes.plantilla_agente "tu petición"
"""

import asyncio
import sys

from claude_agent_sdk import ClaudeAgentOptions

from agentes.comun import MODELO, ejecutar_agente

# 1. Qué es y cómo se comporta el agente.
INSTRUCCIONES = """Eres un asistente que ayuda con <tarea>.
Responde en español, de forma clara y breve."""

# 2. Qué puede hacer. Herramientas integradas: Read, Write, Edit, Bash,
#    Glob, Grep, WebSearch, WebFetch... Empieza con solo lectura.
HERRAMIENTAS = ["Read", "Glob", "Grep"]

OPCIONES = ClaudeAgentOptions(
    model=MODELO,
    system_prompt=INSTRUCCIONES,
    allowed_tools=HERRAMIENTAS,
    permission_mode="default",  # "acceptEdits" si le dejas editar archivos
    max_turns=10,               # límite de seguridad
    max_budget_usd=1.0,         # tope de gasto por ejecución
)


async def main() -> None:
    peticion = " ".join(sys.argv[1:]) or "Resume qué hay en esta carpeta."
    await ejecutar_agente(peticion, OPCIONES)


if __name__ == "__main__":
    asyncio.run(main())
