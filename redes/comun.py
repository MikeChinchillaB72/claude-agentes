"""Piezas compartidas por todas las redes: hallazgos, configuración y lista de archivos.

Solo usa la biblioteca estándar, para que el hook de commit pueda ejecutarlo
con cualquier Python 3.11+ sin instalar nada.
"""

from __future__ import annotations

import fnmatch
import subprocess
import tomllib
from dataclasses import dataclass
from pathlib import Path
from typing import Any

RUTA_CONFIG = Path("config") / "redes.toml"


class ErrorDeRed(Exception):
    """La red no pudo ejecutarse (configuración rota, git ausente...). Nunca es un "verde"."""


@dataclass(frozen=True)
class Hallazgo:
    """Una violación de una regla, con su ubicación."""

    red: str
    archivo: str
    linea: int
    mensaje: str

    def __str__(self) -> str:
        ubicacion = f"{self.archivo}:{self.linea}" if self.linea else self.archivo
        return f"[{self.red}] {ubicacion}: {self.mensaje}"


def cargar_config(raiz: Path) -> dict[str, Any]:
    """Lee config/redes.toml desde la raíz del repositorio."""
    ruta = raiz / RUTA_CONFIG
    if not ruta.is_file():
        raise ErrorDeRed(f"No existe {ruta}.")
    try:
        with ruta.open("rb") as archivo:
            return tomllib.load(archivo)
    except tomllib.TOMLDecodeError as error:
        raise ErrorDeRed(f"{ruta} no es TOML válido: {error}") from error


def seccion(config: dict[str, Any], nombre: str) -> dict[str, Any]:
    """Devuelve una sección obligatoria de la configuración."""
    if nombre not in config:
        raise ErrorDeRed(f"Falta la sección [{nombre}] en {RUTA_CONFIG}.")
    return config[nombre]


def excepciones(config_red: dict[str, Any], red: str) -> set[str]:
    """Archivos exceptuados de una red. Cada excepción debe tener `archivo` y `motivo`."""
    resultado = set()
    for excepcion in config_red.get("excepciones", []):
        if not str(excepcion.get("motivo", "")).strip():
            raise ErrorDeRed(f"[{red}] la excepción de {excepcion.get('archivo')!r} no tiene motivo escrito.")
        resultado.add(excepcion["archivo"])
    return resultado


def archivos_del_repositorio(raiz: Path, config: dict[str, Any]) -> list[str]:
    """Archivos versionados y nuevos no ignorados, relativos a la raíz y con `/`.

    Se pide a git para respetar .gitignore. Si git falla, la red falla: revisar
    "lo que se pueda" sería un verde falso.
    """
    try:
        salida = subprocess.run(
            ["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"],
            cwd=raiz,
            capture_output=True,
            check=True,
        ).stdout
    except (OSError, subprocess.CalledProcessError) as error:
        raise ErrorDeRed(f"No se pudo listar los archivos con git en {raiz}: {error}") from error

    excluir = seccion(config, "general").get("excluir", [])
    archivos = []
    for nombre in sorted(set(salida.decode("utf-8").split("\0"))):
        if not nombre or not (raiz / nombre).is_file():
            continue  # vacío del separador final, o archivo borrado sin confirmar
        if any(nombre.startswith(prefijo) or fnmatch.fnmatch(nombre, prefijo) for prefijo in excluir):
            continue
        archivos.append(nombre)
    return archivos


def leer_texto(raiz: Path, nombre: str) -> str | None:
    """Contenido de un archivo de texto, o None si es binario (no se puede revisar como texto)."""
    try:
        return (raiz / nombre).read_text(encoding="utf-8")
    except UnicodeDecodeError:  # silencio-permitido: un binario no tiene texto que revisar; `generados` cubre los binarios
        return None
