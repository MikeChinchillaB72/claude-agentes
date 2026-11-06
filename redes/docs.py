"""Red `docs`: la documentación no puede mentir sobre el código.

Reglas M6 y T7 de docs/REGLAS.md. Un documento desfasado es peor que no tenerlo:
el que no existe se nota, el que miente se cree. Comprueba que:
1. todo enlace relativo de un .md apunta a un archivo que existe;
2. el documento de reglas nombra cada red registrada;
3. el documento de configuración nombra cada clave de las fuentes de configuración;
4. cada documento tiene los enlaces que config/redes.toml le exige.
"""

from __future__ import annotations

import re
import tomllib
from pathlib import Path, PurePosixPath
from typing import Any

from redes.comun import ErrorDeRed, Hallazgo, archivos_del_repositorio, leer_texto, seccion

NOMBRE = "docs"

# [texto](destino) de Markdown; se ignora la imagen `!` igual que un enlace.
_ENLACE = re.compile(r"\[[^\]]*\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")


def _destino_local(destino: str) -> str | None:
    """Ruta del destino si es un archivo del repositorio; None si es web, ancla o correo."""
    if re.match(r"^[a-z][a-z0-9+.\-]*:", destino, re.IGNORECASE) or destino.startswith("#"):
        return None
    return destino.split("#", 1)[0] or None


def _claves(datos: dict[str, Any], prefijo: str = "") -> list[str]:
    """Claves de un TOML aplanadas con puntos: `modelo.nombre`, `datos_personales.patrones.email`..."""
    claves = []
    for clave, valor in datos.items():
        completa = f"{prefijo}{clave}"
        claves.append(completa)
        if isinstance(valor, dict):
            claves.extend(_claves(valor, f"{completa}."))
    return claves


def revisar(raiz: Path, config: dict[str, Any]) -> list[Hallazgo]:
    """Aplica las cuatro comprobaciones del docstring del módulo."""
    from redes import REDES  # aquí y no arriba: redes/__init__.py importa este módulo

    conf = seccion(config, NOMBRE)
    hallazgos: list[Hallazgo] = []
    archivos = archivos_del_repositorio(raiz, config)

    # 1. Enlaces relativos rotos.
    for archivo in (a for a in archivos if a.endswith(".md")):
        carpeta = PurePosixPath(archivo).parent
        for numero, linea in enumerate((leer_texto(raiz, archivo) or "").splitlines(), start=1):
            for destino in _ENLACE.findall(linea):
                ruta = _destino_local(destino)
                if ruta and not (raiz / carpeta / ruta).exists():
                    hallazgos.append(Hallazgo(NOMBRE, archivo, numero, f"enlace roto: {destino}"))

    # 2. Cada red aparece en el documento de reglas.
    reglas = _leer_obligatorio(raiz, conf["reglas"])
    for modulo in REDES:
        if f"`{modulo.NOMBRE}`" not in reglas:
            hallazgos.append(Hallazgo(NOMBRE, conf["reglas"], 0, f"no menciona la red `{modulo.NOMBRE}`"))

    # 3. Cada clave de configuración aparece en el documento de configuración.
    documento = _leer_obligatorio(raiz, conf["configuracion"])
    for fuente in conf["fuentes_de_configuracion"]:
        with (raiz / fuente).open("rb") as f:
            datos = tomllib.load(f)
        for clave in _claves(datos):
            if f"`{clave}`" not in documento:
                hallazgos.append(Hallazgo(NOMBRE, conf["configuracion"], 0, f"no documenta la clave `{clave}` de {fuente}"))

    # 4. Enlaces obligatorios.
    for archivo, destinos in conf.get("enlaces_obligatorios", {}).items():
        texto = _leer_obligatorio(raiz, archivo)
        carpeta = PurePosixPath(archivo).parent
        enlazados = {str(PurePosixPath(carpeta, d)) for d in (_destino_local(x) for x in _ENLACE.findall(texto)) if d}
        enlazados = {_normalizar(e) for e in enlazados}
        for destino in destinos:
            if _normalizar(destino) not in enlazados:
                hallazgos.append(Hallazgo(NOMBRE, archivo, 0, f"debe enlazar a {destino}"))
    return hallazgos


def _normalizar(ruta: str) -> str:
    """Resuelve `./` y `../` sin tocar el disco, para comparar rutas relativas."""
    partes: list[str] = []
    for parte in PurePosixPath(ruta).parts:
        if parte == "..":
            if partes:
                partes.pop()
        elif parte != ".":
            partes.append(parte)
    return "/".join(partes)


def _leer_obligatorio(raiz: Path, archivo: str) -> str:
    if not (raiz / archivo).is_file():
        raise ErrorDeRed(f"[{NOMBRE}] no existe {archivo}, que config/redes.toml declara.")
    return (raiz / archivo).read_text(encoding="utf-8")
