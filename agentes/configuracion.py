"""Carga la configuración de los agentes desde archivos TOML.

Regla M7 de docs/REGLAS.md: ningún valor ajustable vive en el código. Este
módulo es el único que lee la configuración; el resto del código recibe
objetos ya validados.

Dónde se busca la configuración:
- `config/agentes.toml`: valores generales (modelo, registro, sandbox, datos personales).
- `config/agentes/<nombre>.toml`: un archivo por agente (instrucciones, herramientas, límites).
- La carpeta `config/` se puede cambiar con la variable de entorno `AGENTES_CONFIG_DIR`.

Precedencia: una variable de entorno (ver `SUSTITUCIONES_POR_ENTORNO`) manda sobre
el archivo. No hay valores por defecto escondidos en el código: si falta una clave
obligatoria, se lanza `ErrorDeConfiguracion` (regla T12: fallar hace ruido).

Las claves están documentadas en docs/CONFIGURACION.md.
"""

from __future__ import annotations

import os
import tomllib
from dataclasses import dataclass
from pathlib import Path
from typing import Any

RAIZ_REPOSITORIO = Path(__file__).resolve().parent.parent

# Variables de entorno que sustituyen claves de config/agentes.toml.
# Clave: (sección, clave) del TOML. Valor: nombre de la variable.
SUSTITUCIONES_POR_ENTORNO: dict[tuple[str, str], str] = {
    ("modelo", "nombre"): "AGENTE_MODELO",
    ("registro", "nivel"): "AGENTE_LOG_NIVEL",
}


class ErrorDeConfiguracion(Exception):
    """La configuración falta, está mal escrita o le falta una clave obligatoria."""


@dataclass(frozen=True)
class ConfigGeneral:
    """Valores comunes a todos los agentes (config/agentes.toml)."""

    modelo: str
    nivel_registro: str
    dominios_sandbox: tuple[str, ...]
    reemplazo_datos_personales: str
    patrones_datos_personales: dict[str, str]


@dataclass(frozen=True)
class ConfigSubagente:
    """Un subagente en el que el agente principal puede delegar."""

    descripcion: str
    instrucciones: str
    herramientas: tuple[str, ...]


@dataclass(frozen=True)
class ConfigAgente:
    """Configuración de un agente (config/agentes/<nombre>.toml)."""

    nombre: str
    version: str
    descripcion: str
    modelo: str
    instrucciones: str
    peticion_por_defecto: str
    herramientas_lectura: tuple[str, ...]
    herramientas_sensibles: tuple[str, ...]
    max_turnos: int
    max_presupuesto_usd: float
    sandbox: bool
    subagentes: dict[str, ConfigSubagente]
    datos: dict[str, str]


def carpeta_config() -> Path:
    """Carpeta de configuración: `AGENTES_CONFIG_DIR` o `config/` en la raíz del repositorio."""
    return Path(os.getenv("AGENTES_CONFIG_DIR") or RAIZ_REPOSITORIO / "config")


def leer_toml(ruta: Path) -> dict[str, Any]:
    """Lee un archivo TOML y explica con claridad por qué falló si no se puede."""
    if not ruta.is_file():
        raise ErrorDeConfiguracion(f"No existe el archivo de configuración {ruta}.")
    try:
        with ruta.open("rb") as archivo:
            return tomllib.load(archivo)
    except tomllib.TOMLDecodeError as error:
        raise ErrorDeConfiguracion(f"{ruta} no es TOML válido: {error}") from error


def _obligatorio(datos: dict[str, Any], seccion: str, clave: str, tipo: type | tuple[type, ...], origen: Path) -> Any:
    """Devuelve `datos[seccion][clave]` comprobando que existe y que tiene el tipo esperado."""
    try:
        valor = datos[seccion][clave]
    except KeyError as error:
        raise ErrorDeConfiguracion(f"Falta `{seccion}.{clave}` en {origen}.") from error
    # bool es subclase de int: un `true` no debe pasar por un número.
    if not isinstance(valor, tipo) or (isinstance(valor, bool) and bool not in _como_tupla(tipo)):
        raise ErrorDeConfiguracion(f"`{seccion}.{clave}` en {origen} tiene un tipo no válido: {valor!r}.")
    return valor


def _como_tupla(tipo: type | tuple[type, ...]) -> tuple[type, ...]:
    return tipo if isinstance(tipo, tuple) else (tipo,)


def _lista_de_textos(valor: Any, nombre: str, origen: Path) -> tuple[str, ...]:
    if not isinstance(valor, list) or not all(isinstance(v, str) for v in valor):
        raise ErrorDeConfiguracion(f"`{nombre}` en {origen} debe ser una lista de textos.")
    return tuple(valor)


def cargar_config_general(carpeta: Path | None = None) -> ConfigGeneral:
    """Lee config/agentes.toml y aplica las sustituciones por variable de entorno."""
    ruta = (carpeta or carpeta_config()) / "agentes.toml"
    datos = leer_toml(ruta)
    for (seccion, clave), variable in SUSTITUCIONES_POR_ENTORNO.items():
        if os.getenv(variable):
            datos.setdefault(seccion, {})[clave] = os.environ[variable]

    patrones = _obligatorio(datos, "datos_personales", "patrones", dict, ruta)
    if not all(isinstance(v, str) for v in patrones.values()):
        raise ErrorDeConfiguracion(f"`datos_personales.patrones` en {ruta} debe contener solo textos.")

    return ConfigGeneral(
        modelo=_obligatorio(datos, "modelo", "nombre", str, ruta),
        nivel_registro=_obligatorio(datos, "registro", "nivel", str, ruta),
        dominios_sandbox=_lista_de_textos(
            _obligatorio(datos, "sandbox", "dominios_permitidos", list, ruta), "sandbox.dominios_permitidos", ruta
        ),
        reemplazo_datos_personales=_obligatorio(datos, "datos_personales", "reemplazo", str, ruta),
        patrones_datos_personales=dict(patrones),
    )


def cargar_agente(nombre: str, general: ConfigGeneral, carpeta: Path | None = None) -> ConfigAgente:
    """Lee config/agentes/<nombre>.toml. El modelo, si el agente no lo fija, sale de `general`."""
    ruta = (carpeta or carpeta_config()) / "agentes" / f"{nombre}.toml"
    datos = leer_toml(ruta)

    subagentes = {}
    for clave, sub in datos.get("subagentes", {}).items():
        envoltorio = {"subagente": sub}
        subagentes[clave] = ConfigSubagente(
            descripcion=_obligatorio(envoltorio, "subagente", "descripcion", str, ruta),
            instrucciones=_obligatorio(envoltorio, "subagente", "instrucciones", str, ruta),
            herramientas=_lista_de_textos(sub.get("herramientas"), f"subagentes.{clave}.herramientas", ruta),
        )

    lectura = _lista_de_textos(_obligatorio(datos, "herramientas", "lectura", list, ruta), "herramientas.lectura", ruta)
    sensibles = _lista_de_textos(
        _obligatorio(datos, "herramientas", "sensibles", list, ruta), "herramientas.sensibles", ruta
    )
    repetidas = set(lectura) & set(sensibles)
    if repetidas:
        # Una herramienta en `lectura` se aprueba sola: si además es sensible, la aprobación se saltaría.
        raise ErrorDeConfiguracion(f"{ruta}: {sorted(repetidas)} están en `lectura` y en `sensibles` a la vez.")

    max_turnos = _obligatorio(datos, "limites", "max_turnos", int, ruta)
    presupuesto = float(_obligatorio(datos, "limites", "max_presupuesto_usd", (int, float), ruta))
    if max_turnos <= 0 or presupuesto <= 0:
        raise ErrorDeConfiguracion(f"{ruta}: los límites deben ser mayores que cero.")

    datos_extra = datos.get("datos", {})
    if not all(isinstance(v, str) for v in datos_extra.values()):
        raise ErrorDeConfiguracion(f"`datos` en {ruta} debe contener solo rutas de texto.")

    return ConfigAgente(
        nombre=_obligatorio(datos, "agente", "nombre", str, ruta),
        version=_obligatorio(datos, "agente", "version", str, ruta),
        descripcion=_obligatorio(datos, "agente", "descripcion", str, ruta),
        modelo=datos["agente"].get("modelo") or general.modelo,
        instrucciones=_obligatorio(datos, "agente", "instrucciones", str, ruta),
        peticion_por_defecto=_obligatorio(datos, "agente", "peticion_por_defecto", str, ruta),
        herramientas_lectura=lectura,
        herramientas_sensibles=sensibles,
        max_turnos=max_turnos,
        max_presupuesto_usd=presupuesto,
        sandbox=_obligatorio(datos, "limites", "sandbox", bool, ruta),
        subagentes=subagentes,
        datos=dict(datos_extra),
    )


def ruta_de_datos(agente: ConfigAgente, clave: str) -> Path:
    """Ruta absoluta de un archivo de datos declarado en `[datos]` del agente."""
    if clave not in agente.datos:
        raise ErrorDeConfiguracion(f"El agente {agente.nombre} no declara `datos.{clave}`.")
    return RAIZ_REPOSITORIO / agente.datos[clave]
