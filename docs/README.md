# La documentación de claude-agentes

> La puerta de entrada (regla T8). No repite lo que dicen los demás documentos:
> dice cuál abrir y cuál manda cuando dos no coinciden.
> Actualizado: 2026-11-06.

## Según lo que vengas a hacer

| Si vienes a… | Abre |
|---|---|
| Saber **cómo se trabaja** aquí | [REGLAS.md](REGLAS.md) ← empieza por aquí |
| Crear o cambiar un **agente** | [ESTANDARES.md](ESTANDARES.md) y [lista-revision-agente.md](lista-revision-agente.md) |
| Cambiar un **valor** (modelo, límites, instrucciones, herramientas) | [CONFIGURACION.md](CONFIGURACION.md) |
| Saber **qué falta** | [pendientes.md](pendientes.md) · lo cerrado, en [hecho.md](hecho.md) |
| Saber **qué se hizo un día** y con qué fuentes | `cambios_AAAA-MM-DD.md`, una por jornada |

## Quién manda cuando dos no dicen lo mismo

> **El código manda sobre el documento** (regla T6). Un documento explica una
> decisión; no es la decisión.

| Asunto | Fuente de verdad | Lo que no manda |
|---|---|---|
| Valores de los agentes (modelo, límites, instrucciones, herramientas) | `config/agentes.toml` y `config/agentes/*.toml` | Cualquier documento que cite un valor |
| Qué revisan las redes y sus excepciones | `config/redes.toml` | |
| Las invariantes de seguridad | `agentes/comun.py` | |
| Las reglas de trabajo | [REGLAS.md](REGLAS.md) | |

## Lo que no se reescribe

- **Las bitácoras `cambios_AAAA-MM-DD.md`** son el archivo de lo que pasó, con
  los nombres que se usaban ese día. Corregirlas las volvería un documento que
  nunca existió. Si algo cambió, se cuenta en la bitácora del día nuevo.
- **Un pendiente cerrado se muda** de [pendientes.md](pendientes.md) a
  [hecho.md](hecho.md) en el mismo commit. No se tacha en el sitio: la red
  `pendientes` lo bloquea.
