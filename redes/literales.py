"""Red `literales`: los valores ajustables no se escriben en el código.

Regla M7 de docs/REGLAS.md (100% configurable). Busca en el código Python los
patrones de config/redes.toml, como identificadores de modelo o límites
escritos a mano. Su sitio es config/.
"""

from __future__ import annotations

import re
from pathlib import Path
from typing import Any

from redes.comun import Hallazgo, archivos_del_repositorio, excepciones, leer_texto, seccion

NOMBRE = "literales"


def revisar(raiz: Path, config: dict[str, Any]) -> list[Hallazgo]:
    """Señala cada línea de código que contiene un valor que debería estar en config/."""
    conf = seccion(config, NOMBRE)
    exceptuados = excepciones(conf, NOMBRE)
    carpetas = tuple(c.rstrip("/") + "/" for c in conf["carpetas"])
    patrones = {nombre: re.compile(p) for nombre, p in conf["patrones"].items()}

    hallazgos = []
    for archivo in archivos_del_repositorio(raiz, config):
        if not archivo.endswith(".py") or not archivo.startswith(carpetas) or archivo in exceptuados:
            continue
        for numero, linea in enumerate((leer_texto(raiz, archivo) or "").splitlines(), start=1):
            for nombre, patron in patrones.items():
                if patron.search(linea):
                    hallazgos.append(Hallazgo(NOMBRE, archivo, numero, f"valor ajustable en el código ({nombre}); muévelo a config/"))
    return hallazgos
