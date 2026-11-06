"""Red `vocabulario`: un solo nombre por producto en todo el repositorio.

Regla T16 de docs/REGLAS.md. Los nombres correctos y sus variantes prohibidas
están en config/redes.toml, con la fecha y la fuente en que se comprobaron.
"""

from __future__ import annotations

import re
from pathlib import Path
from typing import Any

from redes.comun import Hallazgo, archivos_del_repositorio, excepciones, leer_texto, seccion

NOMBRE = "vocabulario"


def revisar(raiz: Path, config: dict[str, Any]) -> list[Hallazgo]:
    """Busca cada variante incorrecta (sensible a mayúsculas) como palabra completa."""
    conf = seccion(config, NOMBRE)
    exceptuados = excepciones(conf, NOMBRE)
    extensiones = tuple(conf["extensiones"])
    reglas = [
        (re.compile(rf"(?<![\w-]){re.escape(incorrecto)}(?![\w-])"), incorrecto, termino["correcto"])
        for termino in conf["terminos"]
        for incorrecto in termino["incorrectos"]
    ]

    hallazgos = []
    for archivo in archivos_del_repositorio(raiz, config):
        if not archivo.endswith(extensiones) or archivo in exceptuados:
            continue
        for numero, linea in enumerate((leer_texto(raiz, archivo) or "").splitlines(), start=1):
            for patron, incorrecto, correcto in reglas:
                if patron.search(linea):
                    hallazgos.append(Hallazgo(NOMBRE, archivo, numero, f"«{incorrecto}» se escribe «{correcto}»"))
    return hallazgos
