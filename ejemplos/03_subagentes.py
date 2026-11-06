"""Ejemplo 3: un agente principal que delega en subagentes especializados.

El agente y sus subagentes (revisor y documentador) están definidos en
config/agentes/ejemplo_subagentes.toml.
"""

import asyncio

from agentes import cargar, ejecutar_agente, opciones_de_agente

agente = cargar("ejemplo_subagentes")

if __name__ == "__main__":
    asyncio.run(
        ejecutar_agente(
            agente.peticion_por_defecto, opciones_de_agente(agente), agente=agente.nombre, version=agente.version
        )
    )
