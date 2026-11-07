# Instalación en monday.com: Atención con contexto del cliente

> Plugin `servicio-atencion-contexto` 0.1.0. Actualizado: 2026-11-07.

Los pasos completos están en [instalacion-monday.md](../../../docs/cliente/instalacion-monday.md).
Aquí va lo que necesita este plugin en monday service.

## Resumen

1. Crear la app OAuth propia (**Developers > + Create app**), activar **New OAuth flow** y añadir
   la Redirect URL `https://claude.ai/api/mcp/auth_callback`.
2. Marcar **solo** estos *scopes* de lectura: `me:read`, `account:read`, `users:read`, `teams:read`, `workspaces:read`, `boards:read`, `updates:read`. Ningún `:write`.
3. Desactivar el conector MCP alojado genérico en la administración de monday.com.
4. Añadir el conector `monday` en Claude con la URL `https://mcp.monday.com/mcp`, el Client ID y el Client Secret
   ([instalar-en-claude.md](../../../docs/cliente/instalar-en-claude.md)).

Si varios plugins usan la misma app, la app lleva la unión de sus *scopes*, todos de lectura.

## Tableros que necesita

| Tablero | Datos | Para qué |
|---|---|---|
| Tickets (monday service) | Cliente, asunto, estado, prioridad, fecha de creación y de cierre, responsable | Casos abiertos y recientes |
| Clientes o contactos | Nombre, email, empresa, plan | Contexto del cliente |

Los nombres reales y sus columnas se anotan en el mapeo de
[`references/criterios.md`](../skills/atender-con-contexto/references/criterios.md). Los usuarios deben
tener acceso a esos tableros en monday.com; Claude no ve tableros a los que el usuario no llega.

## Comprobar

1. En un chat nuevo: «¿Cómo está el cliente Acme? Tiene un caso abierto por facturación.». Debe responder con elementos reales del tablero.
2. Pedir un cambio (por ejemplo, «cambia el estado de este elemento»): debe negarse, y si se
   forzara, monday.com lo rechazaría por falta de *scope*. Es la prueba de que la app es de solo lectura.
3. Seguir [06-pruebas-de-aceptacion.md](06-pruebas-de-aceptacion.md).
