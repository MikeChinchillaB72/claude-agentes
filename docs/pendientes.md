# Pendientes

> Lo que falta, con el motivo de que siga abierto (regla M5). Al cerrarse, cada
> punto se **muda** a [hecho.md](hecho.md) en el mismo commit; no se tacha aquí.

## Esperan una decisión o acción de Miguel

- **P1 · Información del cliente para los seis plugins.** Cada plugin lista lo que falta en su
  `docs/01-requisitos.md`: las preguntas comunes G1–G7 (plataforma, grupo piloto, responsable,
  idioma, campos excluidos, países, plan de Claude) y las suyas (R1–R6: umbrales, rúbricas,
  categorías y el mapeo de tableros de monday.com). Ninguna respuesta se ha inventado.
- **P6 · Licencia de los plugins.** No llevan licencia. No hace falta para el catálogo propio,
  pero sí para publicarlos en el directorio de Anthropic. Elegirla es decisión de Miguel.
- **P7 · ¿Algún plugin debe escribir en el CRM?** La versión 0.1.0 solo lee. Los casos de uso
  proponían escribir el próximo paso de una oportunidad (seguimiento) y la categoría y prioridad
  de un caso (clasificación). Hacerlo necesita un servidor con escritura, aprobación previa de la
  persona y su análisis de seguridad.
- **P8 · Validación de plugins en CI.** `claude plugin validate .` pasó a mano el 2026-11-07, pero
  nada lo vuelve a ejecutar (regla T1). Se propone añadirlo a CI; espera el «hazlo» de Miguel.

## Esperan a la empresa cliente

- **P9 · Costos de las plataformas.** Confirmar con Salesforce el cobro por Flex Credits de los
  servidores MCP y qué ediciones los incluyen, y con monday.com en qué planes está su servidor MCP
  y sus límites. Detalle en [cliente/costos-y-soporte.md](cliente/costos-y-soporte.md).

## Huecos medidos

- **P3 · Dependencias sin fijar.** ESTANDARES.md (sección 2, regla 10) pide versiones fijadas
  y `pyproject.toml` usa rangos (`>=`). Falta un archivo de bloqueo. Venía de antes del 2026-11-06.
- **P4 · Sin evaluaciones.** No existe `evals/` todavía. Cuando haya agentes reales, sus
  valores esperados se calculan aparte (regla T15). Los plugins traen sus pruebas de aceptación
  en `docs/06-pruebas-de-aceptacion.md`, que son manuales.
- **P5 · Sin prueba en plataforma real** (regla T5). No hay sandbox de Salesforce ni cuenta
  de prueba de monday.com conectados a este proyecto. Al probar los plugins hay que comprobar,
  además de sus pruebas de aceptación:
  - la autenticación de Salesforce desde Claude Code (Client ID de la External Client App);
  - si la base de conocimiento integrada de monday service se puede leer por el servidor MCP;
  - qué registro de auditoría deja cada llamada en Salesforce y en monday.com;
  - la ruta exacta para desactivar el conector MCP genérico en la administración de monday.com.
