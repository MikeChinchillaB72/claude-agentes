# Configuración

> Regla M7: todo valor ajustable vive en [`config/`](../config/), nunca en el código.
> La red `docs` exige que cada clave de `config/agentes.toml` y de
> `config/agentes/plantilla.toml` aparezca en este documento.
> Actualizado: 2026-11-06.

El código lee la configuración solo a través de `agentes/configuracion.py`. Si
falta una clave obligatoria o tiene un tipo no válido, el agente no arranca y
dice qué falta (regla T12: fallar hace ruido). No hay valores por defecto
escondidos en el código.

## Archivos

| Archivo | Qué contiene |
|---|---|
| `config/agentes.toml` | Valores comunes a todos los agentes |
| `config/agentes/<nombre>.toml` | Un archivo por agente. `plantilla.toml` es el punto de partida |
| `config/datos/` | Datos de prueba de los ejemplos |
| `config/redes.toml` | Configuración de las redes (ver [REGLAS.md](REGLAS.md)) |

La carpeta `config/` se puede cambiar con la variable `AGENTES_CONFIG_DIR`, por
ejemplo para usar una configuración de pre-producción.

## `config/agentes.toml`

| Clave | Tipo | Qué hace |
|---|---|---|
| `modelo` | sección | Modelo que usan los agentes |
| `modelo.nombre` | texto | Identificador del modelo por defecto. Un agente puede cambiarlo con `agente.modelo` |
| `registro` | sección | Registros de ejecución |
| `registro.nivel` | texto | `DEBUG`, `INFO`, `WARNING` o `ERROR` |
| `sandbox` | sección | Entorno aislado de los agentes que ejecutan comandos |
| `sandbox.dominios_permitidos` | lista de textos | Dominios a los que puede salir un agente con sandbox. Vacía = sin red |
| `datos_personales` | sección | Lo que se tapa en los registros (regla T13) |
| `datos_personales.reemplazo` | texto | Texto que sustituye a cada dato personal |
| `datos_personales.patrones` | tabla | Expresiones regulares, una por tipo de dato. Se pueden añadir más |
| `datos_personales.patrones.email` | texto | Direcciones de correo |
| `datos_personales.patrones.telefono` | texto | Números de teléfono |
| `datos_personales.patrones.tarjeta` | texto | Números de tarjeta |

### Variables de entorno que sustituyen claves

Una variable con valor manda sobre el archivo. Sirven para cambiar un valor en
un entorno sin tocar el repositorio. Los secretos van **solo** en variables de
entorno o en un gestor de secretos, nunca en `config/`.

| Variable | Sustituye a |
|---|---|
| `AGENTE_MODELO` | `modelo.nombre` |
| `AGENTE_LOG_NIVEL` | `registro.nivel` |
| `AGENTES_CONFIG_DIR` | La carpeta `config/` entera |
| `ANTHROPIC_API_KEY` | (secreto; no tiene equivalente en archivo) |

## `config/agentes/<nombre>.toml`

| Clave | Tipo | Obligatoria | Qué hace |
|---|---|---|---|
| `agente` | sección | sí | Identidad y comportamiento |
| `agente.nombre` | texto | sí | Nombre con que aparece en los registros |
| `agente.version` | texto | sí | Súbela cuando cambien instrucciones o herramientas; se registra en cada ejecución |
| `agente.descripcion` | texto | sí | Para qué sirve, en una frase |
| `agente.modelo` | texto | no | Modelo propio del agente. Si falta, se usa `modelo.nombre` |
| `agente.instrucciones` | texto | sí | System prompt. Explica las reglas; no las impone (eso lo hacen el código y los permisos) |
| `agente.peticion_por_defecto` | texto | sí | Petición si se ejecuta sin argumentos |
| `herramientas` | sección | sí | Qué puede usar el agente |
| `herramientas.lectura` | lista de textos | sí | Herramientas de solo lectura. Se aprueban solas |
| `herramientas.sensibles` | lista de textos | sí | Herramientas que escriben o tienen efectos. Necesitan aprobador; sin él, se deniegan. Una herramienta no puede estar en las dos listas |
| `limites` | sección | sí | Límites de seguridad |
| `limites.max_turnos` | entero > 0 | sí | Máximo de turnos por ejecución |
| `limites.max_presupuesto_usd` | número > 0 | sí | Tope de gasto por ejecución, en dólares |
| `limites.sandbox` | booleano | sí | Si el agente corre en el entorno aislado. Obligatorio si tiene `Bash` |
| `subagentes.<clave>` | tabla | no | Un subagente en el que puede delegar: `descripcion`, `instrucciones` y `herramientas` |
| `datos.<clave>` | texto | no | Ruta, desde la raíz del repositorio, de un archivo de datos del agente |

## Lo que no es configurable, a propósito

Las invariantes de seguridad están en `agentes/comun.py` y ningún archivo las
puede relajar: `permission_mode="default"` y la denegación de cualquier
herramienta que no esté en `herramientas.lectura` ni aprobada en
`herramientas.sensibles`. Motivo en [REGLAS.md](REGLAS.md), excepción a M7.
