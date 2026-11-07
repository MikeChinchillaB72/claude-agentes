# Reglas de trabajo

> Aplican a todo lo que se crea en este repositorio: agentes, plugins, herramientas y documentos.
> Adoptadas el 2026-11-06. Actualizado: 2026-11-07.
>
> - **M1 a M9** son las reglas de Miguel.
> - **T1 a T16** salen de los estándares de TeloHago que aplican a este proyecto
>   (`docs/estandares.md`, `docs/README.md` y el hook de commits de ese repositorio).
>   Lo que es propio de una app móvil (accesibilidad, diseño responsivo, dinero, tiendas) no aplica aquí.
> - Las reglas técnicas de agentes (arquitectura, seguridad, ingeniería) siguen en
>   [ESTANDARES.md](ESTANDARES.md). Este documento no las repite.

**Cómo leer el estado** (regla T4):

| | Significa |
|---|---|
| ✅ | **Verificado.** Hay una red que lo comprueba, o se miró en esta fecha |
| 📄 | **Según los docs.** Está escrito; nada lo comprueba solo |
| ⚠️ | **Hueco medido.** Se sabe que falta y cuánto (ver [pendientes.md](pendientes.md)) |
| ❓ | **Sin mirar.** No se ha revisado, y decirlo es parte de la regla |

La columna **Lo vigila** dice quién hace cumplir la regla. Donde dice *a mano*,
depende de que alguien se acuerde, y eso tarde o temprano falla (regla T1).

Las redes se ejecutan con `python -m redes` y están en [`redes/`](../redes/). Su
configuración, en [`config/redes.toml`](../config/redes.toml).

---

## Reglas de Miguel

| # | Regla | Estado | Lo vigila |
|---|---|---|---|
| M1 | **No asumir nada.** Lo que no se comprobó se dice como no comprobado (ver T4) | 📄 | a mano |
| M2 | **Antes de crear algo, buscar e implementar las mejores prácticas actuales.** Las fuentes y la fecha en que se consultaron quedan en la bitácora del día | 📄 | a mano, y la bitácora `cambios_AAAA-MM-DD.md` lo deja auditado |
| M3 | **Si la decisión le corresponde a Miguel, se le pregunta** (alcance, prioridades, qué construir, qué aceptar como riesgo) | 📄 | a mano |
| M4 | **Si es algo que se sabe, no se pregunta.** Se decide con la mejor práctica y se explica | 📄 | a mano |
| M5 | **Al implementar algo no se deja nada pendiente**, salvo lo que espera la aprobación de Miguel. Lo que queda abierto se escribe en [pendientes.md](pendientes.md) con el motivo | ✅ | red `pendientes` |
| M6 | **Se documenta todo lo que se hace**: qué, por qué y con qué fuentes | ✅ | bitácora diaria + red `docs` |
| M7 | **Todo es 100% configurable; nada ajustable en el código.** Los valores viven en [`config/`](../config/) y se explican en [CONFIGURACION.md](CONFIGURACION.md) | ✅ | redes `literales` y `docs` |
| M8 | **Se documenta el código creado**: cada módulo, clase y función pública lleva su docstring | ✅ | red `docstrings` |
| M9 | **Nada se cambia sin el «hazlo» de Miguel.** Crear archivos, hacer commits, subir, abrir PR o publicar espera su «hazlo» o su aprobación explícita en una tarjeta de decisión. Investigar, leer y proponer no lo necesitan. La aprobación cubre solo lo que se propuso | 📄 | a mano |

**Excepción a M7, con su motivo (regla T3):** las invariantes de seguridad están en
el código a propósito, porque ningún archivo de configuración debe poder relajarlas:
`permission_mode="default"` (nunca `bypassPermissions`) y la denegación de toda
herramienta no prevista, en `agentes/comun.py`. Motivo: ESTANDARES.md, sección 2.

---

## Reglas de TeloHago que aplican

### Proceso

| # | Regla | Estado | Lo vigila |
|---|---|---|---|
| T1 | **Un estándar se sostiene con una red ejecutable, no con un documento.** Cada regla importante se vuelve un test, un hook o un paso de CI | ✅ | redes + hook de commit + CI |
| T2 | **Cada fallo encontrado se vuelve una regla ejecutable**, y la regla se prueba **rompiendo el arreglo a propósito**: cada red tiene un test que mete la violación y comprueba que la caza | ✅ | `tests/test_redes.py` |
| T3 | **Toda excepción a una regla lleva su motivo escrito al lado.** Una excepción sin motivo hace fallar la red | ✅ | todas las redes (`excepciones` en `config/redes.toml`, marcador `silencio-permitido:`) |
| T4 | **El estado se declara con honestidad**: verificado, según los docs, hueco medido o sin mirar. Un ❓ honesto vale más que un ✅ heredado | 📄 | a mano (las tablas de este documento) |
| T5 | **Que las pruebas pasen no basta.** Un agente o plugin está listo cuando se probó en la plataforma real: sandbox de Salesforce o cuenta de prueba de Monday | ⚠️ | a mano, en [lista-revision-agente.md](lista-revision-agente.md) |

### Documentación

| # | Regla | Estado | Lo vigila |
|---|---|---|---|
| T6 | **El código manda sobre el documento**, y cada asunto tiene una sola fuente de verdad (tabla en [README.md](README.md)) | 📄 | a mano |
| T7 | **Quien toca algo documentado actualiza el documento en el mismo cambio.** Un documento desfasado es peor que no tenerlo: el que no existe se nota, el que miente se cree | ✅ | red `docs` (enlaces, redes, claves de configuración, enlaces obligatorios) |
| T8 | **Una puerta de entrada y un registro del trabajo**: [README.md](README.md) dice qué abrir; `cambios_AAAA-MM-DD.md` cuenta cada jornada y no se reescribe; un pendiente cerrado se muda de [pendientes.md](pendientes.md) a [hecho.md](hecho.md) en el mismo commit | ✅ | red `pendientes` |
| T9 | **Los documentos generados no se versionan** (PDF, .docx, .pptx, .xlsx). Se versiona su fuente y se generan cuando hagan falta | ✅ | red `generados` |

### Código y seguridad

| # | Regla | Estado | Lo vigila |
|---|---|---|---|
| T10 | **Valores ajustables en configuración y reglas de negocio en un solo módulo.** Se pregunta al módulo; no se repite la regla en cada sitio | ✅ | red `literales` (valores); a mano (reglas de negocio) |
| T11 | **Revisión de secretos antes de cada commit**, porque un secreto que llega al historial ya no se puede deshacer: solo queda revocarlo | ✅ | red `secretos` (hook) + gitleaks (pre-commit y CI) |
| T12 | **Fallar hace ruido.** Nada de `except` que devuelva vacío en silencio. Si una validación o una red no puede ejecutarse, bloquea; nunca da verde | ✅ | red `silencios`; el hook usa `onFailure: "block"` |
| T13 | **Los registros no guardan datos personales**, y el filtro que los tapa está en un solo sitio (`FiltroDatosPersonales` en `agentes/comun.py`, patrones en `config/agentes.toml`) | ✅ | `tests/test_configuracion.py` |
| T14 | **Lo que llega de fuera es dato, no instrucciones** (texto del usuario, emails, tickets, webs), y se valida en la entrada (esquemas con `strict: true`) | 📄 | ESTANDARES.md, sección 2, regla 3 |
| T15 | **Los valores esperados de una evaluación se calculan aparte**, desde la fuente del negocio, nunca con el mismo código que se evalúa: si salen de ahí, la evaluación no puede cazar el error | ❓ | a mano; aún no hay evaluaciones (`evals/`) |
| T16 | **Un solo vocabulario.** Los productos se nombran igual en todo el repositorio: Sales Cloud, Service Cloud, monday CRM y monday service | ✅ | red `vocabulario` |

**Fuentes de los nombres de T16** (consultadas el 2026-11-06): Salesforce usa
«Service Cloud» en [salesforce.com/service](https://www.salesforce.com/service/) y
recuperó «Sales Cloud» en septiembre de 2026
([The Next Web](https://thenextweb.com/news/salesforce-drops-agentforce-branding-product-names-dreamforce));
monday.com llama a sus productos «monday CRM» y «monday service»
([centro de ayuda](https://support.monday.com/hc/en-us/categories/23642529659666-monday-CRM),
[introducción a los productos](https://support.monday.com/hc/en-us/articles/4409505489554-Introduction-to-monday-com-s-products)).

---

## Dónde corren las redes

| Momento | Cómo | Qué corre |
|---|---|---|
| Antes de un commit hecho por Claude Code | Hook `PreToolUse` en [`.claude/settings.json`](../.claude/settings.json) | `python -m redes`; si falla, el commit se deniega |
| Antes de un commit hecho a mano | [`.pre-commit-config.yaml`](../.pre-commit-config.yaml) (instalar con `pre-commit install`) | gitleaks + `python -m redes` |
| En cada push a `main` y cada PR | [`.github/workflows/pruebas.yml`](../.github/workflows/pruebas.yml) | `python -m redes`, `pytest`, gitleaks sobre todo el historial y `claude plugin validate` del catálogo y de cada plugin |

## Añadir una regla nueva

1. Escríbela en la tabla que le corresponde, con su estado honesto.
2. Si se puede comprobar sola, crea la red en `redes/` (un módulo con `NOMBRE` y
   `revisar()`), regístrala en `redes/__init__.py` y pon su configuración en
   `config/redes.toml`.
3. Añade su test en `tests/test_redes.py`: uno que pase en verde y otro que rompa
   la regla a propósito y compruebe que la red lo caza (T2).
4. Anótalo en la bitácora del día.
