# Instalación en monday.com: Seguimiento de oportunidades

> Plugin `ventas-seguimiento` 0.2.0. Actualizado: 2026-11-07.

Los pasos completos están en [instalacion-monday.md](../../../docs/cliente/instalacion-monday.md).
Aquí va lo que necesita este plugin en monday CRM.

## Resumen

1. Crear la app OAuth propia (**Developers > + Create app**), activar **New OAuth flow** y añadir
   la Redirect URL `https://claude.ai/api/mcp/auth_callback`.
2. Marcar estos *scopes*: de lectura `me:read`, `account:read`, `users:read`, `workspaces:read`,
   `boards:read`, `updates:read`, y de escritura **solo** `boards:write` (próximo paso, fecha de cierre
   y tareas) y `updates:write` (tarea como comentario si no hay tablero de tareas).
3. Desactivar el conector MCP alojado genérico en la administración de monday.com.
4. Añadir el conector `monday` en Claude con la URL `https://mcp.monday.com/mcp`, el Client ID y el Client Secret
   ([instalar-en-claude.md](../../../docs/cliente/instalar-en-claude.md)).
5. **Obligatorio:** en *Tool permissions* del conector, poner en **Never** todas las herramientas de
   escritura salvo `change_item_column_values`, `create_item` y `create_update`, y esas tres en
   **Needs approval**. En especial, bloquear `all_monday_api`, que puede ejecutar cualquier cambio.

`boards:write` permite más que estas tres acciones (por ejemplo, crear tableros): los *scopes* de
monday.com no distinguen columnas. Por eso el paso 5 es obligatorio. Si varios plugins usan la
misma app, la app lleva la unión de sus *scopes*; los demás plugins siguen siendo de solo lectura.

## Tableros que necesita

| Tablero | Datos | Para qué |
|---|---|---|
| Negocios (*Deals*) | Responsable, monto, etapa, fecha de cierre, fecha de última actividad, contacto vinculado | Buscar los negocios sin actividad |
| Negocios (*Deals*): columnas que escribe | Próximo paso (texto) y fecha de cierre | `actualizar_proximo_paso` y `mover_fecha_cierre` |
| Tareas (opcional) | Nombre, negocio vinculado, responsable, fecha | `crear_tarea`; si no existe, la tarea va como comentario en el negocio |
| Contactos (*Contacts*) | Nombre, email, cargo, cuenta | Destinatario del correo |

Los nombres reales y sus columnas se anotan en el mapeo de
[`references/criterios.md`](../skills/seguimiento-oportunidades/references/criterios.md). Los usuarios deben
tener acceso a esos tableros en monday.com; Claude no ve tableros a los que el usuario no llega.

## Comprobar

1. En un chat nuevo: «¿Qué oportunidades mías llevan más de una semana sin actividad?». Debe responder con elementos reales del tablero.
2. Pedir un cambio fuera de las tres acciones (por ejemplo, «cambia el estado de este elemento»):
   debe negarse. Pedir «crea un tablero nuevo»: debe negarse, y si se forzara, Claude no podría porque
   `create_board` está en *Never*.
3. Pedir que aplique un próximo paso: debe mostrar la tabla, esperar el sí y luego pedir la aprobación de la herramienta.
4. Seguir [06-pruebas-de-aceptacion.md](06-pruebas-de-aceptacion.md).
