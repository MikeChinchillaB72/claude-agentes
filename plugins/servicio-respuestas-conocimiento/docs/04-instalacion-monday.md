# Instalación en monday.com: Respuestas con la base de conocimiento

> Plugin `servicio-respuestas-conocimiento` 0.1.1. Actualizado: 2026-11-07.

Los pasos completos están en [instalacion-monday.md](../../../docs/cliente/instalacion-monday.md).
Aquí va lo que necesita este plugin en monday service.

## Resumen

1. Crear la app OAuth propia (**Developers > + Create app**), activar **New OAuth flow** y añadir
   la Redirect URL `https://claude.ai/api/mcp/auth_callback`.
2. Marcar **solo** estos *scopes* de lectura: `me:read`, `account:read`, `workspaces:read`, `boards:read`, `updates:read`, `docs:read`. Ningún `:write`.
3. Desactivar el conector MCP alojado genérico en la administración de monday.com.
4. Añadir el conector `monday` en Claude con la URL `https://mcp.monday.com/mcp`, el Client ID y el Client Secret
   ([instalar-en-claude.md](../../../docs/cliente/instalar-en-claude.md)).

Si varios plugins usan la misma app, la app lleva la unión de sus *scopes*, todos de lectura.

## Tableros que necesita

| Tablero | Datos | Para qué |
|---|---|---|
| Tickets (monday service) | Asunto, descripción, actualizaciones | Pregunta del ticket |
| Base de conocimiento (tablero de artículos o docs de monday.com) | Título, contenido, estado de publicación | Buscar y leer artículos |

Los nombres reales y sus columnas se anotan en el mapeo de
[`references/criterios.md`](../skills/responder-con-conocimiento/references/criterios.md). Los usuarios deben
tener acceso a esos tableros en monday.com; Claude no ve tableros a los que el usuario no llega.

## Comprobar

1. En un chat nuevo: «¿Qué le respondo al caso 00012345?». Debe responder con elementos reales del tablero.
2. Pedir un cambio (por ejemplo, «cambia el estado de este elemento»): debe negarse, y si se
   forzara, monday.com lo rechazaría por falta de *scope*. Es la prueba de que la app es de solo lectura.
3. Seguir [06-pruebas-de-aceptacion.md](06-pruebas-de-aceptacion.md).
