"""Red `secretos`: ninguna credencial entra al repositorio.

Regla T11 de docs/REGLAS.md. Es la única red cuyo fallo no se deshace: cuando un
secreto llega al historial, lo único que queda es revocarlo. Por eso corre antes
del commit. Es una red de apoyo con patrones conocidos; la revisión completa la
hace gitleaks (ver .pre-commit-config.yaml y el workflow de CI).
"""

from __future__ import annotations

import fnmatch
import re
from pathlib import Path
from typing import Any

from redes.comun import Hallazgo, archivos_del_repositorio, excepciones, leer_texto, seccion

NOMBRE = "secretos"


def revisar(raiz: Path, config: dict[str, Any]) -> list[Hallazgo]:
    """Busca archivos prohibidos y textos con forma de credencial."""
    conf = seccion(config, NOMBRE)
    exceptuados = excepciones(conf, NOMBRE)
    patrones = {nombre: re.compile(p) for nombre, p in conf.get("patrones", {}).items()}
    prohibidos = conf.get("archivos_prohibidos", [])

    hallazgos = []
    for archivo in archivos_del_repositorio(raiz, config):
        if archivo in exceptuados:
            continue
        base = Path(archivo).name
        if any(fnmatch.fnmatch(base, patron) for patron in prohibidos):
            hallazgos.append(Hallazgo(NOMBRE, archivo, 0, "este tipo de archivo nunca se versiona"))
            continue
        texto = leer_texto(raiz, archivo)
        if texto is None:
            continue
        for numero, linea in enumerate(texto.splitlines(), start=1):
            for nombre, patron in patrones.items():
                if patron.search(linea):
                    # No se imprime el valor: el registro de la red no debe filtrar el secreto.
                    hallazgos.append(Hallazgo(NOMBRE, archivo, numero, f"posible credencial ({nombre})"))
    return hallazgos
