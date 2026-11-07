# La documentación de claude-agentes

> La puerta de entrada (regla T8). No repite lo que dicen los demás documentos:
> dice cuál abrir y cuál manda cuando dos no coinciden.
> Actualizado: 2026-11-07.

## Según lo que vengas a hacer

| Si vienes a… | Abre |
|---|---|
| Saber **cómo se trabaja** aquí | [REGLAS.md](REGLAS.md) ← empieza por aquí |
| Crear o cambiar un **agente** | [ESTANDARES.md](ESTANDARES.md) y [lista-revision-agente.md](lista-revision-agente.md) |
| Cambiar un **valor** (modelo, límites, instrucciones, herramientas) | [CONFIGURACION.md](CONFIGURACION.md) |
| **Instalar o usar los plugins** en una empresa (Salesforce o monday.com) | [cliente/README.md](cliente/README.md), la guía del cliente |
| Cambiar un **plugin** | Su carpeta en `plugins/` (README y `docs/`) y la sección Plugins de [CONFIGURACION.md](CONFIGURACION.md#plugins-pluginsnombre) |
| Cambiar una **acción de Salesforce** que ejecuta un plugin | [salesforce/README.md](../salesforce/README.md) |
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
| Qué hace cada plugin | Su `skills/<skill>/SKILL.md` y sus criterios en `references/criterios.md` | Los documentos de `plugins/<nombre>/docs/` y de `cliente/` |
| Qué puede escribir un plugin en Salesforce y con qué validaciones | Las clases Apex de `salesforce/` | La skill, que solo las nombra |
| Pasos de instalación en Salesforce, monday.com y Claude | La documentación oficial de cada proveedor (enlazada en cada guía) | Las guías de `cliente/`, que la resumen con fecha |

## Lo que no se reescribe

- **Las bitácoras `cambios_AAAA-MM-DD.md`** son el archivo de lo que pasó, con
  los nombres que se usaban ese día. Corregirlas las volvería un documento que
  nunca existió. Si algo cambió, se cuenta en la bitácora del día nuevo.
- **Un pendiente cerrado se muda** de [pendientes.md](pendientes.md) a
  [hecho.md](hecho.md) en el mismo commit. No se tacha en el sitio: la red
  `pendientes` lo bloquea.
