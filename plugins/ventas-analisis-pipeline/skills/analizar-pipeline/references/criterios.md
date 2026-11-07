# Criterios de `analizar-pipeline`

Valores de negocio de la empresa. **Se cambian aquí, no en `SKILL.md`.** Los valores
iniciales salen del documento «Agentes de IA con Claude: casos de uso», versión 2 (5 de noviembre de 2026), caso 3 (analista de pipeline bajo demanda), y **están sin confirmar** por la
empresa. Un valor `PENDIENTE` todavía no existe: no lo inventes, dilo en la respuesta.

| Clave | Valor | Qué significa |
|---|---|---|
| `dias_sin_actividad_riesgo` | 14 | Días sin actividad para marcar una oportunidad en riesgo |
| `cierre_vencido_es_riesgo` | sí | Si una fecha de cierre ya pasada marca riesgo |
| `monto_relevante` | 10000 | Monto desde el que una oportunidad se considera relevante (en la moneda de la org) |
| `periodo_por_defecto` | trimestre fiscal actual | Periodo si el usuario no dice otro |
| `max_registros` | 2000 | Máximo de oportunidades que se traen para un análisis; si hay más, se pide acotar |

## Mapeo de columnas en monday.com

En monday CRM, los tableros y columnas los define cada empresa. Hasta que la empresa los
escriba aquí, pregunta al usuario qué tablero y qué columna corresponde a cada dato.

| Dato | Tablero | Columna |
|---|---|---|
| Negocios (*Deals*): Responsable, monto, etapa, probabilidad, fecha de cierre, fecha de última actividad, cuenta | PENDIENTE | PENDIENTE |
