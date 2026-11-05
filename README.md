# Agentes base

Punto de partida para crear agentes con el **Claude Agent SDK** (Python). El SDK trae el
mismo motor que Claude Code: bucle del agente, herramientas integradas (leer/escribir
archivos, Bash, búsqueda web...), herramientas propias, subagentes, permisos y sesiones.

## Puesta en marcha

```bash
python -m venv .venv && source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -e ".[dev]"
cp .env.example .env        # y pon tu ANTHROPIC_API_KEY
python ejemplos/01_basico.py
```

Requisitos: Python 3.10 o superior y una clave de API de https://console.anthropic.com.

## Estructura

| Ruta | Qué es |
|---|---|
| `agentes/comun.py` | Modelo por defecto y `ejecutar_agente()`, que muestra el progreso, el coste y el resultado |
| `agentes/plantilla_agente.py` | Plantilla para copiar al crear un agente nuevo |
| `ejemplos/01_basico.py` | Agente que lee una carpeta con herramientas integradas |
| `ejemplos/02_herramienta_propia.py` | Agente con una herramienta escrita en Python |
| `ejemplos/03_subagentes.py` | Agente coordinador que delega en subagentes |
| `tests/` | Pruebas de las herramientas sin llamar a la API |

## Crear un agente nuevo

1. Copia `agentes/plantilla_agente.py` a `agentes/mi_agente.py`.
2. Cambia `INSTRUCCIONES` (quién es y cómo responde) y `HERRAMIENTAS` (qué puede hacer).
3. Si necesita acceder a tus sistemas, crea herramientas con `@tool` como en el ejemplo 2.
4. Ejecuta `python -m agentes.mi_agente "tu petición"`.

## Buenas prácticas

- **Empieza con permisos mínimos.** Solo lectura (`Read`, `Glob`, `Grep`) y añade `Write`,
  `Edit` o `Bash` cuando haga falta.
- **Pon límites.** `max_turns` y `max_budget_usd` evitan bucles y gastos inesperados.
- **Prueba las herramientas por separado** (ver `tests/`), sin gastar tokens.
- **Modelo:** por defecto `claude-opus-5-5`; cámbialo con `AGENTE_MODELO` en `.env`
  (por ejemplo `claude-sonnet-5-5` o `claude-haiku-5-5` para tareas sencillas y más baratas).
- Nunca subas el archivo `.env` al repositorio (ya está en `.gitignore`).

## Pruebas

```bash
pytest
```

## Documentación

- Claude Agent SDK: https://code.claude.com/docs/en/agent-sdk
- Claude API: https://platform.claude.com/docs
