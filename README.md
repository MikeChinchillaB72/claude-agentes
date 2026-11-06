# Agentes base

Punto de partida para crear agentes con el **Claude Agent SDK** (Python). El SDK trae el
mismo motor que Claude Code: bucle del agente, herramientas integradas (leer/escribir
archivos, Bash, búsqueda web...), herramientas propias, subagentes, permisos y sesiones.

## Puesta en marcha

```bash
python -m venv .venv && source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -e ".[dev]"
cp .env.example .env        # y pon tu ANTHROPIC_API_KEY
pre-commit install          # revisiones antes de cada commit (requiere pre-commit)
python ejemplos/01_basico.py
```

Requisitos: Python 3.11 o superior y una clave de API de https://console.anthropic.com.

## Estructura

| Ruta | Qué es |
|---|---|
| `agentes/comun.py` | `ejecutar_agente()` (registro JSON de costo, turnos y rechazos), `opciones_de_agente()`, `politica_de_herramientas()` (aprobación), `SANDBOX_ESTRICTO` y el filtro de datos personales |
| `agentes/configuracion.py` | Lee y valida `config/`. Es el único módulo que lo hace |
| `agentes/plantilla_agente.py` | Plantilla para copiar al crear un agente nuevo |
| `config/` | Todos los valores ajustables: generales y uno por agente ([docs/CONFIGURACION.md](docs/CONFIGURACION.md)) |
| `redes/` | Revisiones automáticas que hacen cumplir las reglas (`python -m redes`) |
| `ejemplos/01_basico.py` | Agente que lee una carpeta con herramientas integradas |
| `ejemplos/02_herramienta_propia.py` | Agente con una herramienta escrita en Python |
| `ejemplos/03_subagentes.py` | Agente coordinador que delega en subagentes |
| `tests/` | Pruebas de herramientas y políticas sin llamar a la API |
| `docs/` | Reglas, estándares, configuración, pendientes y bitácora. Empieza por [docs/README.md](docs/README.md) |

## Reglas y estándares

Todo trabajo cumple [docs/REGLAS.md](docs/REGLAS.md). Todo agente cumple además
[docs/ESTANDARES.md](docs/ESTANDARES.md) (arquitectura, seguridad e ingeniería) y pasa la
[lista de revisión](docs/lista-revision-agente.md) antes de producción.

## Crear un agente nuevo

1. Copia `agentes/plantilla_agente.py` a `agentes/mi_agente.py` y `config/agentes/plantilla.toml`
   a `config/agentes/mi_agente.toml`. En el `.py`, cambia `NOMBRE = "mi_agente"`.
2. En el `.toml`, cambia `agente.instrucciones` (quién es y cómo responde) y `herramientas`
   (qué puede hacer).
3. Si necesita acceder a tus sistemas, crea herramientas con `@tool` como en el ejemplo 2.
   Las que escriben o tienen efectos van en `herramientas.sensibles`, nunca en `herramientas.lectura`.
4. Ejecuta `python -m agentes.mi_agente "tu petición"`.
5. Añade sus evaluaciones en `evals/mi_agente/` y recorre la lista de revisión.

## Buenas prácticas

- **Empieza con permisos mínimos.** Solo lectura (`Read`, `Glob`, `Grep`) y añade `Write`,
  `Edit` o `Bash` cuando haga falta.
- **Pon límites.** `limites.max_turnos` y `limites.max_presupuesto_usd` evitan bucles y gastos inesperados.
- **Prueba las herramientas por separado** (ver `tests/`), sin gastar tokens.
- **Modelo:** el de `modelo.nombre` en `config/agentes.toml`. Un agente puede usar otro con
  `agente.modelo`, y `AGENTE_MODELO` lo sustituye sin tocar archivos.
- Nunca subas el archivo `.env` al repositorio (ya está en `.gitignore`).

## Pruebas

```bash
python -m redes   # las reglas que se comprueban solas
pytest
```

## Documentación

- Claude Agent SDK: https://code.claude.com/docs/en/agent-sdk
- Claude API: https://platform.claude.com/docs
