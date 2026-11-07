# Criterios de `clasificar-casos`

Valores de negocio de la empresa. **Se cambian aquí, no en `SKILL.md`.** Los valores
iniciales salen del documento «Agentes de IA con Claude: casos de uso», versión 2 (5 de noviembre de 2026), caso 5 (crear_caso con categoría, prioridad y resumen), y **están sin confirmar** por la
empresa. Un valor `PENDIENTE` todavía no existe: no lo inventes, dilo en la respuesta.

| Clave | Valor | Qué significa |
|---|---|---|
| `categorias` | los valores de la lista de selección del tipo de caso en Salesforce, o de la columna de categoría en monday service | Categorías posibles; no se inventan otras |
| `prioridades` | los valores de la lista de selección de prioridad, o de la columna de prioridad | Prioridades posibles |
| `reglas_de_prioridad` | PENDIENTE | Qué hace que un caso sea de prioridad alta (por ejemplo, servicio caído, cliente de cierto plan, plazo de SLA) |
| `que_es_sin_clasificar` | estado nuevo y sin tipo, o sin prioridad | Qué casos entran en la revisión |
| `max_casos` | 20 | Cuántos casos revisar por petición, empezando por los más antiguos |

## Mapeo de columnas en monday.com

En monday service, los tableros y columnas los define cada empresa. Hasta que la empresa los
escriba aquí, pregunta al usuario qué tablero y qué columna corresponde a cada dato.

| Dato | Tablero | Columna |
|---|---|---|
| Tickets (monday service): Asunto, descripción, categoría, prioridad, estado, fecha de creación, cliente | PENDIENTE | PENDIENTE |
