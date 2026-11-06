"""Ejecución con registro y controles de seguridad comunes a todos los agentes.

Todo agente del repositorio se ejecuta con `ejecutar_agente()` para que:
- cada ejecución deje un registro estructurado (costo, turnos, versión, motivo de parada);
- los rechazos (`refusal`) y errores se detecten en vez de pasar en silencio;
- las herramientas sensibles pasen por una política de aprobación en el código;
- los registros no guarden datos personales (regla T13 de docs/REGLAS.md).

Los valores ajustables salen de config/ (ver `agentes.configuracion`). Lo que sí
está en el código, a propósito, son las invariantes de seguridad que ningún
archivo debe poder relajar: `permission_mode="default"` y la denegación de toda
herramienta no prevista. Motivo: docs/ESTANDARES.md, sección 2.
"""

import json
import logging
import re
from collections.abc import Awaitable, Callable, Iterable
from typing import Any

from dotenv import load_dotenv
from claude_agent_sdk import (
    AgentDefinition,
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

from agentes.configuracion import ConfigAgente, cargar_agente, cargar_config_general

load_dotenv()

CONFIG = cargar_config_general()
MODELO = CONFIG.modelo


class FiltroDatosPersonales(logging.Filter):
    """Tapa en cada registro los datos personales definidos en `datos_personales.patrones`.

    Es el único filtro de datos personales del repositorio: dos listas de patrones
    acabarían separándose, y separarse es dejar de tapar algo.
    """

    def __init__(self, patrones: dict[str, str], reemplazo: str) -> None:
        super().__init__()
        self._patrones = [re.compile(p) for p in patrones.values()]
        self._reemplazo = reemplazo

    def tapar(self, texto: str) -> str:
        """Devuelve `texto` con cada coincidencia sustituida por el reemplazo."""
        for patron in self._patrones:
            texto = patron.sub(self._reemplazo, texto)
        return texto

    def filter(self, record: logging.LogRecord) -> bool:
        """Sustituye el mensaje ya formateado por su versión tapada. Nunca descarta el registro."""
        record.msg = self.tapar(record.getMessage())
        record.args = ()
        return True


registro = logging.getLogger("agentes")
registro.setLevel(CONFIG.nivel_registro)
if not registro.handlers:
    _salida = logging.StreamHandler()
    _salida.setFormatter(logging.Formatter("%(message)s"))
    registro.addHandler(_salida)
    registro.propagate = False
registro.addFilter(FiltroDatosPersonales(CONFIG.patrones_datos_personales, CONFIG.reemplazo_datos_personales))

# Entorno aislado para agentes que ejecutan comandos: sin red salvo los
# dominios de `sandbox.dominios_permitidos` y sin escape del sandbox.
SANDBOX_ESTRICTO = SandboxSettings(
    enabled=True,
    allowUnsandboxedCommands=False,
    network={"allowedDomains": list(CONFIG.dominios_sandbox)},
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


def opciones_de_agente(agente: ConfigAgente, aprobador: Aprobador | None = None, **extra: Any) -> ClaudeAgentOptions:
    """Construye las opciones del SDK a partir de la configuración del agente.

    `aprobador` decide las herramientas sensibles; sin él, se deniegan todas.
    `extra` pasa opciones que no son valores sino objetos de código, como
    `mcp_servers` con herramientas escritas en Python.
    """
    return ClaudeAgentOptions(
        model=agente.modelo,
        system_prompt=agente.instrucciones,
        allowed_tools=list(agente.herramientas_lectura),
        can_use_tool=politica_de_herramientas(agente.herramientas_sensibles, aprobador or denegar_siempre),
        permission_mode="default",  # invariante de seguridad: nunca "bypassPermissions"
        sandbox=SANDBOX_ESTRICTO if agente.sandbox else None,
        max_turns=agente.max_turnos,
        max_budget_usd=agente.max_presupuesto_usd,
        agents={
            clave: AgentDefinition(description=sub.descripcion, prompt=sub.instrucciones, tools=list(sub.herramientas))
            for clave, sub in agente.subagentes.items()
        }
        or None,
        **extra,
    )


def cargar(nombre: str) -> ConfigAgente:
    """Atajo: carga config/agentes/<nombre>.toml con la configuración general ya leída."""
    return cargar_agente(nombre, CONFIG)


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
