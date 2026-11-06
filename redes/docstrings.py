"""Red `docstrings`: el código creado está documentado.

Regla M8 de docs/REGLAS.md. Cada módulo, clase y función pública (las que no
empiezan por `_`) de las carpetas configuradas lleva su docstring. Los métodos
especiales (`__str__`...) y las funciones privadas quedan fuera.
"""

from __future__ import annotations

import ast
from pathlib import Path
from typing import Any

from redes.comun import ErrorDeRed, Hallazgo, archivos_del_repositorio, excepciones, leer_texto, seccion

NOMBRE = "docstrings"


def _publicos(arbol: ast.Module):
    """Clases y funciones públicas del módulo, incluidas las de dentro de una clase."""
    for nodo in arbol.body:
        if isinstance(nodo, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)) and not nodo.name.startswith("_"):
            yield nodo
            if isinstance(nodo, ast.ClassDef):
                for miembro in nodo.body:
                    if isinstance(miembro, (ast.FunctionDef, ast.AsyncFunctionDef)) and not miembro.name.startswith("_"):
                        yield miembro


def revisar(raiz: Path, config: dict[str, Any]) -> list[Hallazgo]:
    """Señala módulos, clases y funciones públicas sin docstring."""
    conf = seccion(config, NOMBRE)
    exceptuados = excepciones(conf, NOMBRE)
    carpetas = tuple(c.rstrip("/") + "/" for c in conf["carpetas"])

    hallazgos = []
    for archivo in archivos_del_repositorio(raiz, config):
        if not archivo.endswith(".py") or not archivo.startswith(carpetas) or archivo in exceptuados:
            continue
        try:
            arbol = ast.parse(leer_texto(raiz, archivo) or "", filename=archivo)
        except SyntaxError as error:
            raise ErrorDeRed(f"[{NOMBRE}] {archivo} no es Python válido: {error}") from error
        if not ast.get_docstring(arbol):
            hallazgos.append(Hallazgo(NOMBRE, archivo, 1, "el módulo no tiene docstring"))
        for nodo in _publicos(arbol):
            if not ast.get_docstring(nodo):
                hallazgos.append(Hallazgo(NOMBRE, archivo, nodo.lineno, f"`{nodo.name}` no tiene docstring"))
    return hallazgos
