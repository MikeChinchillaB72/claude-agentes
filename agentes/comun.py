"""Configuración común, ejecución con registro y controles de seguridad.

Todo agente del repositorio se ejecuta con `ejecutar_agente()` para que:
- cada ejecución deje un registro estructurado (costo, turnos, versión, motivo de parada);
- los rechazos (`refusal`) y errores se detecten en vez de pasar en silencio;
- las herramientas sensibles pasen por una política de aprobación en el código.
"""

import json
import logging
import os
from collections.abc import Awaitable, Callable, Iterable
from typing import Any

from dotenv import load_dotenv
from claude_agent_sdk import (
    AssistantMessage,
    ClaudeAgentOptions,
    PermissionResultAllow,
    PermissionResultDeny,
    ResultMessage,
    SandboxSettings,
    TextBlock,
    ToolPermissionContext,
    ToolUseBlock,
    query,
)

load_dotenv()

MODELO = os.getenv("AGENTE_MODELO", "claude-opus-5-5")

registro = logging.getLogger("agentes")
if not registro.handlers:
    logging.basicConfig(level=os.getenv("AGENTE_LOG_NIVEL", "INFO"), format="%(message)s")

# Entorno aislado por defecto para agentes que ejecutan comandos:
# sin red salvo los dominios que se listen y sin escape del sandbox.
SANDBOX_ESTRICTO = SandboxSettings(
    enabled=True,
    allowUnsandboxedCommands=False,
    network={"allowedDomains": []},
)

Aprobador = Callable[[str, dict[str, Any]], Awaitable[bool]]


async def denegar_siempre(nombre: str, entrada: dict[str, Any]) -> bool:
    """Aprobador por defecto: sin una persona que apruebe, no se ejecuta."""
    return False


def politica_de_herramientas(
    sensibles: Iterable[str],
    aprobador: Aprobador = denegar_siempre,
) -> Callable[[str, dict[str, Any], ToolPermissionContext], Awaitable[Any]]:
    """Crea un `can_use_tool` que pide aprobación para las herramientas sensibles.

    Importante: las herramientas listadas en `allowed_tools` se aprueban solas y
    nunca llegan aquí. Pon en `allowed_tools` solo las de lectura y deja las
    sensibles fuera. Cualquier otra herramienta no prevista se deniega.
    """
    sensibles = set(sensibles)

    async def can_use_tool(nombre: str, entrada: dict[str, Any], _ctx: ToolPermissionContext):
        if nombre in sensibles and await aprobador(nombre, entrada):
            registro.info(json.dumps({"evento": "herramienta_aprobada", "herramienta": nombre}))
            return PermissionResultAllow()
        motivo = "requiere aprobación" if nombre in sensibles else "no permitida"
        registro.warning(json.dumps({"evento": "herramienta_denegada", "herramienta": nombre, "motivo": motivo}))
        return PermissionResultDeny(message=f"La herramienta {nombre} {motivo}.")

    return can_use_tool


async def _como_flujo(prompt: str):
    # `can_use_tool` necesita el modo de flujo del SDK.
    yield {"type": "user", "message": {"role": "user", "content": prompt}}


async def ejecutar_agente(
    prompt: str,
    opciones: ClaudeAgentOptions,
    *,
    agente: str = "sin_nombre",
    version: str = "0",
) -> str | None:
    """Lanza el agente, muestra su progreso y registra el resultado.

    Devuelve el texto final, o None si el agente falló o el modelo rechazó la tarea.
    """
    resultado: str | None = None
    entrada = _como_flujo(prompt) if opciones.can_use_tool else prompt
    async for mensaje in query(prompt=entrada, options=opciones):
        if isinstance(mensaje, AssistantMessage):
            for bloque in mensaje.content:
                if isinstance(bloque, TextBlock):
                    print(bloque.text)
                elif isinstance(bloque, ToolUseBlock):
                    print(f"  -> usando herramienta: {bloque.name}")
        elif isinstance(mensaje, ResultMessage):
            registro.info(json.dumps({
                "evento": "ejecucion_terminada",
                "agente": agente,
                "version": version,
                "modelo": opciones.model,
                "sesion": mensaje.session_id,
                "turnos": mensaje.num_turns,
                "duracion_ms": mensaje.duration_ms,
                "costo_usd": mensaje.total_cost_usd,
                "motivo": mensaje.stop_reason,
                "error": mensaje.is_error,
            }))
            if mensaje.stop_reason == "refusal":
                registro.warning(json.dumps({"evento": "rechazo", "agente": agente}))
            elif not mensaje.is_error:
                resultado = mensaje.result
    return resultado
