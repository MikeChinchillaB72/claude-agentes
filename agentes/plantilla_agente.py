"""Plantilla: copia este archivo para crear un agente nuevo.

Todo lo ajustable (instrucciones, herramientas, límites, modelo) vive en
config/agentes/plantilla.toml. Para un agente nuevo, copia los dos archivos y
cambia `NOMBRE`, que es el nombre de su archivo de configuración.

Antes de ponerlo en producción, recorre docs/lista-revision-agente.md.
Uso:  python -m agentes.plantilla_agente "tu petición"
"""

import asyncio
import sys

from agentes.comun import cargar, ejecutar_agente, opciones_de_agente

# Nombre del archivo config/agentes/<NOMBRE>.toml.
NOMBRE = "plantilla"


async def main() -> None:
    """Carga la configuración del agente y lo ejecuta con la petición de la línea de comandos."""
    agente = cargar(NOMBRE)
    peticion = " ".join(sys.argv[1:]) or agente.peticion_por_defecto
    # Sin aprobador, las herramientas sensibles se deniegan. Para aprobarlas,
    # pasa `aprobador=` con una función que pregunte a una persona.
    await ejecutar_agente(peticion, opciones_de_agente(agente), agente=agente.nombre, version=agente.version)


if __name__ == "__main__":
    asyncio.run(main())
