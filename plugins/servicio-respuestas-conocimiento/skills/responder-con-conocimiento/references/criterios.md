# Criterios de `responder-con-conocimiento`

Valores de negocio de la empresa. **Se cambian aquí, no en `SKILL.md`.** Los valores
iniciales salen del documento «Agentes de IA con Claude: casos de uso», versión 2 (5 de noviembre de 2026), caso 5 (responder con la base de conocimiento), y **están sin confirmar** por la
empresa. Un valor `PENDIENTE` todavía no existe: no lo inventes, dilo en la respuesta.

| Clave | Valor | Qué significa |
|---|---|---|
| `idioma_de_articulos` | es | Idioma de los artículos que se buscan (código de idioma de Salesforce Knowledge) |
| `campo_de_contenido` | PENDIENTE | Campo que guarda el cuerpo del artículo en Salesforce (es personalizado en cada org) o dónde está la base de conocimiento en monday.com |
| `max_articulos` | 3 | Cuántos artículos citar como máximo |
| `solo_publicados` | sí | Usar solo artículos publicados |
| `tono_de_respuesta` | cordial y claro | Tono de la respuesta al cliente |

## Mapeo de columnas en monday.com

En monday service, los tableros y columnas los define cada empresa. Hasta que la empresa los
escriba aquí, pregunta al usuario qué tablero y qué columna corresponde a cada dato.

| Dato | Tablero | Columna |
|---|---|---|
| Tickets (monday service): Asunto, descripción, actualizaciones | PENDIENTE | PENDIENTE |
| Base de conocimiento (tablero de artículos o docs de monday.com): Título, contenido, estado de publicación | PENDIENTE | PENDIENTE |
