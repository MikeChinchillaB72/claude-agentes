# Pendientes

> Lo que falta, con el motivo de que siga abierto (regla M5). Al cerrarse, cada
> punto se **muda** a [hecho.md](hecho.md) en el mismo commit; no se tacha aquí.

## Esperan una decisión o acción de Miguel

- **P1 · Información del cliente para los seis plugins.** Cada plugin lista lo que falta en su
  `docs/01-requisitos.md`: las preguntas comunes G1–G7 (plataforma, grupo piloto, responsable,
  idioma, campos excluidos, países, plan de Claude) y las suyas (R1–R6: umbrales, rúbricas,
  categorías y el mapeo de tableros de monday.com). Ninguna respuesta se ha inventado.
  Cuando lleguen, se vuelve a decidir si algún plugin escribe en el CRM (decisión del 2026-11-07:
  solo lectura por ahora; ver [hecho.md](hecho.md)).

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
- **P5 · Pruebas en plataforma real a medias** (regla T5). El 2026-11-07 se conectó el servidor
  `sobject-reads` de una Developer Edition de Salesforce con claude.ai. Faltan:
  - las pruebas de aceptación de cada plugin, empezando por `ventas-seguimiento` con los datos
    `PRUEBA-` de la Developer Edition;
  - una cuenta de prueba de monday.com y sus pruebas;
  - la autenticación de Salesforce desde Claude Code: necesita un callback `http://localhost`
    y la External Client App rechaza direcciones `http://`;
  - si la base de conocimiento integrada de monday service se puede leer por el servidor MCP;
  - qué registro de auditoría deja cada llamada en Salesforce y en monday.com;
  - la ruta exacta para desactivar el conector MCP genérico en la administración de monday.com.
