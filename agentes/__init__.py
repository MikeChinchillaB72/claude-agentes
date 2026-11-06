"""Utilidades compartidas para los agentes del proyecto."""

from agentes.comun import (
    CONFIG,
    MODELO,
    SANDBOX_ESTRICTO,
    FiltroDatosPersonales,
    cargar,
    denegar_siempre,
    ejecutar_agente,
    opciones_de_agente,
    politica_de_herramientas,
)
from agentes.configuracion import ErrorDeConfiguracion

__all__ = [
    "CONFIG",
    "MODELO",
    "SANDBOX_ESTRICTO",
    "ErrorDeConfiguracion",
    "FiltroDatosPersonales",
    "cargar",
    "denegar_siempre",
    "ejecutar_agente",
    "opciones_de_agente",
    "politica_de_herramientas",
]
