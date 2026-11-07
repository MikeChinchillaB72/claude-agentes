# Instalación en Salesforce: Clasificación y priorización de casos

> Plugin `servicio-clasificacion-casos` 0.1.0. Actualizado: 2026-11-07.

Los pasos completos están en [instalacion-salesforce.md](../../../docs/cliente/instalacion-salesforce.md).
Aquí va lo que necesita este plugin.

## Resumen

1. Activar el servidor **SObject Reads** (`sobject-reads`) en **Setup > MCP Servers**.
2. Crear la External Client App (callback `https://claude.ai/api/mcp/auth_callback`, *scopes*
   `mcp_api` y `refresh_token`, PKCE, JWT) y copiar su Consumer Key.
3. Dar a los usuarios del plugin un Permission Set con **lectura** de los objetos y campos de abajo.
4. Añadir el conector `salesforce` en Claude con la URL y el Consumer Key
   ([instalar-en-claude.md](../../../docs/cliente/instalar-en-claude.md)).

## Conector

| Org | URL |
|---|---|
| Producción (la que trae el plugin) | `https://api.salesforce.com/platform/mcp/v1/platform/sobject-reads` |
| Sandbox | `https://api.salesforce.com/platform/mcp/v1/sandbox/platform/sobject-reads` |

## Permisos de lectura que necesita

Permission Set sugerido: `Claude Clasificación y priorización de casos` (lectura, sin crear, editar ni borrar).

| Objeto | Campos | Para qué |
|---|---|---|
| `Case` | Id, CaseNumber, Subject, Description, Origin, Type, Reason, Priority, Status, CreatedDate, IsClosed, AccountId | Leer y clasificar los casos |
| `Account` | Id, Name y el campo de plan, si existe | Reglas de prioridad que dependen del cliente |

Si la empresa guarda estos datos en campos personalizados, se añaden al Permission Set y a
[01-requisitos.md](01-requisitos.md).

## Comprobar

En un chat nuevo, con un usuario del grupo piloto: «Clasifica los casos nuevos de hoy.». Debe responder con
registros reales que ese usuario puede ver, citando su Id. Después, seguir
[06-pruebas-de-aceptacion.md](06-pruebas-de-aceptacion.md).
