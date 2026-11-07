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
- **P12 · Acciones de alto riesgo (fase 2).** Fuera por decisión de Miguel del 2026-11-07: enviar correos
  a clientes, convertir leads y responder casos al cliente. Se retoman cuando él lo pida.

## Esperan a la empresa cliente

- **P9 · Costos de las plataformas.** Confirmar con Salesforce el cobro por Flex Credits de los
  servidores MCP y qué ediciones los incluyen, y con monday.com en qué planes está su servidor MCP
  y sus límites. Detalle en [cliente/costos-y-soporte.md](cliente/costos-y-soporte.md).

## Huecos medidos

- **P10 · Acciones de Salesforce sin desplegar.** Las clases de [salesforce/](../salesforce/README.md)
  pasan un analizador de sintaxis de Apex (`prettier-plugin-apex`), pero no se han compilado ni probado
  en una org: este entorno no tiene acceso a una. Falta: desplegarlas en la Developer Edition con sus
  pruebas, crear el servidor `AgentesCRM`, comprobar su URL (también en sandbox), el nombre con que
  publica cada herramienta, cómo las agrupa claude.ai en *Tool permissions*, y pasar las pruebas
  P6 a P13 de `ventas-seguimiento`. En monday.com, comprobar que una app con `boards:write` y las
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
