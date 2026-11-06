# Pendientes

> Lo que falta, con el motivo de que siga abierto (regla M5). Al cerrarse, cada
> punto se **muda** a [hecho.md](hecho.md) en el mismo commit; no se tacha aquí.

## Esperan una decisión o acción de Miguel

- **P1 · Información para los plugins de Sales Cloud, Service Cloud, monday CRM y monday service.**
  Hacen falta los casos de uso del cliente para definir los 3 plugins de cada producto.
- **P2 · Proteger la rama `main`** (Settings → Rules del repositorio): una regla que exija
  los checks `redes-y-pytest` y `secretos` antes de fusionar. Solo el dueño del repositorio
  puede hacerlo.

## Huecos medidos

- **P3 · Dependencias sin fijar.** ESTANDARES.md (sección 2, regla 10) pide versiones fijadas
  y `pyproject.toml` usa rangos (`>=`). Falta un archivo de bloqueo. Venía de antes del 2026-11-06.
- **P4 · Sin evaluaciones.** No existe `evals/` todavía. Cuando haya agentes reales, sus
  valores esperados se calculan aparte (regla T15).
- **P5 · Sin prueba en plataforma real** (regla T5). No hay sandbox de Salesforce ni cuenta
  de prueba de Monday conectados a este proyecto.
