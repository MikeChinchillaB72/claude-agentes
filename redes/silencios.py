"""Red `silencios`: fallar hace ruido.

Regla T12 de docs/REGLAS.md. Un `except` cuyo cuerpo solo es `pass`, `...`,
`return`, `return None` o `continue` vuelve un fallo idéntico a "no hay dato",
que es el fallo que nadie encuentra. Se permite solo con el marcador de
config/redes.toml y su motivo en la línea del `except`.
"""

from __future__ import annotations

import ast
from pathlib import Path
from typing import Any

from redes.comun import ErrorDeRed, Hallazgo, archivos_del_repositorio, leer_texto, seccion

NOMBRE = "silencios"


def _es_silencioso(manejador: ast.ExceptHandler) -> bool:
    """True si el `except` se traga el error sin hacer nada con él."""
    if len(manejador.body) != 1:
        return False
    orden = manejador.body[0]
    if isinstance(orden, (ast.Pass, ast.Continue)):
        return True
    if isinstance(orden, ast.Expr) and isinstance(orden.value, ast.Constant) and orden.value.value is Ellipsis:
        return True
    if isinstance(orden, ast.Return):
        return orden.value is None or (isinstance(orden.value, ast.Constant) and orden.value.value is None)
    return False


def revisar(raiz: Path, config: dict[str, Any]) -> list[Hallazgo]:
    """Recorre el código Python de las carpetas configuradas buscando `except` silenciosos."""
    conf = seccion(config, NOMBRE)
    carpetas = tuple(c.rstrip("/") + "/" for c in conf["carpetas"])
    marcador = conf["marcador"]

    hallazgos = []
    for archivo in archivos_del_repositorio(raiz, config):
        if not archivo.endswith(".py") or not archivo.startswith(carpetas):
            continue
        texto = leer_texto(raiz, archivo) or ""
        try:
            arbol = ast.parse(texto, filename=archivo)
        except SyntaxError as error:
            raise ErrorDeRed(f"[{NOMBRE}] {archivo} no es Python válido: {error}") from error
        lineas = texto.splitlines()
        for nodo in ast.walk(arbol):
            if isinstance(nodo, ast.ExceptHandler) and _es_silencioso(nodo):
                linea = lineas[nodo.lineno - 1]
                motivo = linea.split(marcador, 1)[1].strip() if marcador in linea else ""
                if not motivo:
                    hallazgos.append(
                        Hallazgo(NOMBRE, archivo, nodo.lineno, f"`except` que se traga el error sin `# {marcador} <motivo>`")
                    )
    return hallazgos
