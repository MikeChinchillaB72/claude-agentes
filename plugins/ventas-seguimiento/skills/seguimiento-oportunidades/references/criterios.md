# Criterios de `seguimiento-oportunidades`

Valores de negocio de la empresa. **Se cambian aquí, no en `SKILL.md`.** Los valores
iniciales salen del documento «Agentes de IA con Claude: casos de uso», versión 2 (5 de noviembre de 2026), caso 1 (asistente de seguimiento de ventas), y **están sin confirmar** por la
empresa. Un valor `PENDIENTE` todavía no existe: no lo inventes, dilo en la respuesta.

| Clave | Valor | Qué significa |
|---|---|---|
| `dias_sin_actividad` | 7 | Días sin actividad para considerar que una oportunidad necesita seguimiento |
| `max_oportunidades` | 10 | Cuántas oportunidades revisar por petición, empezando por las de mayor monto |
| `interacciones_a_leer` | 5 | Cuántas actividades recientes leer por oportunidad (el documento de casos de uso dice de 3 a 5) |
| `monto_minimo` | sin mínimo | Monto a partir del cual se incluye una oportunidad |
| `tono_del_correo` | profesional y breve | Tono y firma de los correos que redacta |

## Mapeo de columnas en monday.com

En monday CRM, los tableros y columnas los define cada empresa. Hasta que la empresa los
escriba aquí, pregunta al usuario qué tablero y qué columna corresponde a cada dato.

| Dato | Tablero | Columna |
|---|---|---|
| Negocios (*Deals*): Responsable, monto, etapa, fecha de cierre, fecha de última actividad, contacto vinculado | PENDIENTE | PENDIENTE |
| Contactos (*Contacts*): Nombre, email, cargo, cuenta | PENDIENTE | PENDIENTE |
