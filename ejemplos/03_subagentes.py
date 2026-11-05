"""Ejemplo 3: un agente principal que delega en subagentes especializados."""

import asyncio

from claude_agent_sdk import AgentDefinition, ClaudeAgentOptions

from agentes import MODELO, ejecutar_agente

opciones = ClaudeAgentOptions(
    model=MODELO,
    system_prompt="Coordinas una revisión. Delega en el subagente adecuado y resume en español.",
    allowed_tools=["Read", "Glob", "Grep", "Agent", "Task"],  # Agent/Task = delegar en subagentes
    agents={
        "revisor": AgentDefinition(
            description="Revisa código Python y señala errores y mejoras.",
            prompt="Eres un revisor de código exigente. Sé concreto: archivo, línea y motivo.",
            tools=["Read", "Glob", "Grep"],
        ),
        "documentador": AgentDefinition(
            description="Propone documentación para funciones sin docstring.",
            prompt="Escribes docstrings breves y claros en español.",
            tools=["Read", "Glob"],
        ),
    },
    max_turns=15,
)

if __name__ == "__main__":
    asyncio.run(ejecutar_agente("Revisa la carpeta agentes/ y propone documentación que falte.", opciones))
