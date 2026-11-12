# Pendientes

> Lo que falta, con el motivo de que siga abierto (regla M5). Al cerrarse, cada
> punto se **muda** a [hecho.md](hecho.md) en el mismo commit; no se tacha aquí.

## Esperan una decisión o acción de Miguel

- **P1 · Información del cliente para los seis plugins.** Cada plugin lista lo que falta en su
  `docs/01-requisitos.md`: las preguntas comunes G1–G7 (plataforma, grupo piloto, responsable,
  idioma, campos excluidos, países, plan de Claude) y las suyas (R1–R7: umbrales, rúbricas,
  categorías y el mapeo de tableros de monday.com). Ninguna respuesta se ha inventado.
  `ventas-seguimiento` 0.2.0 añadió R6 y R7 (acciones habilitadas y plazo de las tareas).
- **P11 · Acciones en los otros cinco plugins.** Miguel decidió el 2026-11-07 empezar por
  `ventas-seguimiento` y replicar después. Propuesta pendiente de su «hazlo»: `ventas-analisis-pipeline`
  (tarea al responsable de una oportunidad en riesgo), `ventas-calificacion-leads` (guardar puntuación,
  asignar y cambiar estado; convertir queda fuera), `servicio-clasificacion-casos` (aplicar categoría y
  prioridad, asignar a cola), `servicio-atencion-contexto` (comentario interno y escalar) y
  `servicio-respuestas-conocimiento` (adjuntar artículos y guardar la respuesta como comentario interno).
  Al hacerlo, conviene que todos usen el servidor `AgentesCRM`, para que la organización tenga un solo
  conector de Salesforce.
- **P14 · URL del servidor `AgentesCRM` en el `.mcp.json`.** El plugin trae
  `https://api.salesforce.com/platform/mcp/v1/custom/AgentesCRM`, pero un servidor personalizado lleva el
  dominio de la org (`.../v1/d/<dominio>/<tipo>/custom/AgentesCRM`, comprobado el 2026-11-07), así que cada
  empresa tiene la suya. Mientras tanto, las guías piden añadir un conector personalizado con la URL de
  Setup y dejar sin conectar el conector `salesforce` del plugin. Falta que Miguel decida qué hacer con el
  `.mcp.json` (Claude se lo propone).
- **P15 · Agente de Agentforce para `ventas-seguimiento`.** El agente «Asistente de Seguimiento» está
  creado en la Developer Edition con Claude Sonnet 5.5 y pasa P1, P6 a P9 y P11 en Live Test; está activo y funciona desde el panel de la app Sales (2026-11-08,
  detalle en [salesforce/agentforce/](../salesforce/agentforce/seguimiento-oportunidades.md)). El
  2026-11-08 Miguel decidió pasarlo a español y la bienvenida ya sale en español. La versión con
  `AgentesLeerHistorialOportunidad` y las instrucciones 10 a 12 quedó activa el mismo día. La lectura con el estado de la oportunidad y la
  frase nueva de la 12 pasan en Live Test (19:09 UTC). Esa versión está activa y funciona en la consola.
  La tarjeta de confirmación sale en el idioma del usuario de Salesforce, no del agente. Falta P10.
- **P16 · Agentes de servicio con conocimiento en Agentforce.** Guía en
  [salesforce/agentforce/servicio-conocimiento.md](../salesforce/agentforce/servicio-conocimiento.md),
  con la investigación en el Claude Doc
  [Agentes avanzados de conocimiento para Service Cloud](https://claude.ai/artifact/UimtZf9wd5yd54R19WyLqY).
  Las fases 0, 1 y 2 están hechas y probadas en la Developer Edition el 2026-11-09 y 10, con el agente
  «Asistente de Servicio» ([bitácora](cambios_2026-11-10.md)). El 2026-11-12 se afinaron S3 y la tabla
  de otros casos y se comprobó que un artículo nuevo llega solo al agente ([bitácora](cambios_2026-11-12.md)). Ese día también se añadió la búsqueda de un
  caso por número o asunto, con acciones estándar. Falta: (1) probar S7 desde el registro en la consola
  de servicio; (2) borrar el Data Library «Conocimiento de servicio v2», que no usa nadie;
  (3) decidir si el Service Agent para clientes por chat entra ahora. La fase 3 (clasificación) espera las categorías de la
  empresa (P1), y la fase 4 (borradores de artículo) está sin empezar.
- **P12 · Acciones de alto riesgo (fase 2).** Fuera por decisión de Miguel del 2026-11-07: enviar correos
  a clientes, convertir leads y responder casos al cliente. Se retoman cuando él lo pida.

## Esperan a la empresa cliente

- **P13 · ¿Plugins de Claude o Agentforce?** Cada usuario de un plugin necesita un asiento de Claude
  (Team o Enterprise). Si los vendedores y agentes de la empresa no van a tener Claude, o se quiere atender
  a clientes finales, el camino es un agente de Agentforce con Claude como modelo: usa las mismas clases
  Apex, y la skill se reescribe como instrucciones del *topic*. Además, Salesforce tiene su propio plugin,
  «Salesforce in Claude», con 37 skills de ventas, que estaba en piloto con beta abierta prevista para
  septiembre de 2026 ([Claudeforce](https://www.salesforce.com/claudeforce/), consultado el 2026-11-07) y
  puede solaparse con los plugins de ventas. Miguel pidió el 2026-11-07 pasar a la versión dentro de
  Salesforce después de actualizar los documentos.

- **P9 · Costos de las plataformas.** Confirmar con Salesforce el cobro por Flex Credits de los
  servidores MCP y qué ediciones los incluyen, y con monday.com en qué planes está su servidor MCP
  y sus límites. Detalle en [cliente/costos-y-soporte.md](cliente/costos-y-soporte.md).

## Huecos medidos

- **P10 · Acciones de Salesforce sin desplegar.** Las clases de [salesforce/](../salesforce/README.md)
  están probadas en la Developer Edition de Miguel (2026-11-07): compilan, pasan las 37 pruebas de Apex,
  el servidor `AgentesCRM` publica cada acción con el nombre de su clase, claude.ai las agrupa como
  *Write/delete tools*, y pasan las pruebas P6 a P9 y P13 de `ventas-seguimiento`. Falta: la URL en un
  sandbox, las pruebas P10 a P12 (P11 no se completó: en un cambio no apareció la ventana de aprobación y
  no se investigó) y quitar del Permission Set de la Developer Edition las seis clases que no son acciones
  (desde el 2026-11-08 son cuatro acciones: se suma `AgentesBuscarOportunidadesSinActividad`). En monday.com, comprobar que una app con `boards:write` y las
  herramientas sobrantes en *Never* no puede hacer más que las tres acciones.
- **P3 · Dependencias sin fijar.** ESTANDARES.md (sección 2, regla 10) pide versiones fijadas
  y `pyproject.toml` usa rangos (`>=`). Falta un archivo de bloqueo. Venía de antes del 2026-11-06.
- **P4 · Sin evaluaciones.** No existe `evals/` todavía. Cuando haya agentes reales, sus
  valores esperados se calculan aparte (regla T15). Los plugins traen sus pruebas de aceptación
  en `docs/06-pruebas-de-aceptacion.md`, que son manuales.
- **P5 · Pruebas en plataforma real a medias** (regla T5). El 2026-11-07 se conectó el servidor
  `sobject-reads` de una Developer Edition de Salesforce con claude.ai. Faltan:
  - las pruebas de aceptación de cada plugin. De `ventas-seguimiento` ya pasan P1 y P5
    (2026-11-07, versión 0.1.1, datos `PRUEBA-` de la Developer Edition);
  - una cuenta de prueba de monday.com y sus pruebas;
  - la autenticación de Salesforce desde Claude Code: necesita un callback `http://localhost`
    y la External Client App rechaza direcciones `http://`;
  - si la base de conocimiento integrada de monday service se puede leer por el servidor MCP;
  - qué registro de auditoría deja cada llamada en Salesforce y en monday.com;
  - la ruta exacta para desactivar el conector MCP genérico en la administración de monday.com.
