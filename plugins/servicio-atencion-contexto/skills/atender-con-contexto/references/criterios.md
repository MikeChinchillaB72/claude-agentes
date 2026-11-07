# Criterios de `atender-con-contexto`

Valores de negocio de la empresa. **Se cambian aquí, no en `SKILL.md`.** Los valores
iniciales salen del documento «Agentes de IA con Claude: casos de uso», versión 2 (5 de noviembre de 2026), caso 5 (asistente de atención al cliente con contexto de cuenta), adaptado a agentes internos, y **están sin confirmar** por la
empresa. Un valor `PENDIENTE` todavía no existe: no lo inventes, dilo en la respuesta.

| Clave | Valor | Qué significa |
|---|---|---|
| `casos_recientes` | 5 | Cuántos casos cerrados recientes leer además de los abiertos |
| `campos_de_cuenta` | PENDIENTE | Qué campos de la cuenta describen su plan, estado o nivel de servicio (suelen ser personalizados) |
| `senales_de_escalado` | frustración del cliente, tema que el agente no puede resolver, o más de un caso abierto por el mismo problema | Cuándo proponer escalar (las dos primeras vienen del documento de casos de uso) |
| `a_quien_escalar` | PENDIENTE | Cola, equipo o persona a la que se propone escalar |

## Mapeo de columnas en monday.com

En monday service, los tableros y columnas los define cada empresa. Hasta que la empresa los
escriba aquí, pregunta al usuario qué tablero y qué columna corresponde a cada dato.

| Dato | Tablero | Columna |
|---|---|---|
| Tickets (monday service): Cliente, asunto, estado, prioridad, fecha de creación y de cierre, responsable | PENDIENTE | PENDIENTE |
| Clientes o contactos: Nombre, email, empresa, plan | PENDIENTE | PENDIENTE |
