"""Red `generados`: las exportaciones de un documento no se versionan.

Regla T9 de docs/REGLAS.md. Un PDF o un .docx generado desde un .md que vive al
lado se separa de su fuente y nadie lo nota hasta que alguien lee el viejo.
"""

from __future__ import annotations

from pathlib import Path
from typing import Any

from redes.comun import Hallazgo, archivos_del_repositorio, excepciones, seccion

NOMBRE = "generados"


def revisar(raiz: Path, config: dict[str, Any]) -> list[Hallazgo]:
    """Señala cada archivo con extensión de documento exportado."""
    conf = seccion(config, NOMBRE)
    exceptuados = excepciones(conf, NOMBRE)
    extensiones = tuple(e.lower() for e in conf["extensiones"])
    return [
        Hallazgo(NOMBRE, archivo, 0, "documento generado: versiona su fuente y genéralo cuando haga falta")
        for archivo in archivos_del_repositorio(raiz, config)
        if archivo.lower().endswith(extensiones) and archivo not in exceptuados
    ]
