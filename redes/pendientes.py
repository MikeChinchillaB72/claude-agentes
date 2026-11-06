"""Red `pendientes`: la lista de pendientes no miente sobre su propio estado.

Reglas M5 y T8 de docs/REGLAS.md. Un pendiente cerrado se muda a docs/hecho.md en el
mismo commit. Tacharlo (`~~`) o marcarlo (`- [x]`) en el sitio lo deja
pareciendo abierto para quien lee rápido.
"""

from __future__ import annotations

import re
from pathlib import Path
from typing import Any

from redes.comun import Hallazgo, seccion

NOMBRE = "pendientes"

_CERRADO = re.compile(r"^\s*[-*]\s*\[[xX]\]|~~")


def revisar(raiz: Path, config: dict[str, Any]) -> list[Hallazgo]:
    """Comprueba que existen los dos archivos y que pendientes no tiene nada cerrado."""
    conf = seccion(config, NOMBRE)
    hallazgos = [
        Hallazgo(NOMBRE, conf[clave], 0, "falta el archivo")
        for clave in ("archivo", "hecho")
        if not (raiz / conf[clave]).is_file()
    ]
    if hallazgos:
        return hallazgos
    texto = (raiz / conf["archivo"]).read_text(encoding="utf-8")
    for numero, linea in enumerate(texto.splitlines(), start=1):
        if _CERRADO.search(linea):
            hallazgos.append(Hallazgo(NOMBRE, conf["archivo"], numero, f"pendiente cerrado: muévelo a {conf['hecho']}"))
    return hallazgos
