"""Ejemplo 1: agente que lee y explica los archivos de una carpeta.

Su configuración está en config/agentes/ejemplo_basico.toml.
"""

import asyncio

from agentes import cargar, ejecutar_agente, opciones_de_agente

agente = cargar("ejemplo_basico")

if __name__ == "__main__":
    asyncio.run(
        ejecutar_agente(
            agente.peticion_por_defecto, opciones_de_agente(agente), agente=agente.nombre, version=agente.version
        )
    )
