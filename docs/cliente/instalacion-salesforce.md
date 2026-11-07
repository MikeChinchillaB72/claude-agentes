# Preparar Salesforce

> Para el administrador de Salesforce. Actualizado: 2026-11-07. Pasos según la
> documentación oficial de Salesforce y de Claude consultada el 2026-11-06 y el
> 2026-11-07 (fuentes al final). **Sin probar todavía en un sandbox real** (P5 en
> [pendientes.md](../pendientes.md)).

Sirve para los seis plugins. Lo que cambia de uno a otro son los objetos que el usuario
debe poder leer; cada plugin los lista en su `docs/03-instalacion-salesforce.md`.

## Cómo se conecta

Los plugins usan los **servidores MCP alojados por Salesforce** (*hosted MCP servers*).
No hay que instalar nada en la org ni mantener un servidor propio. Todos los plugins usan
el servidor **SObject Reads** (`sobject-reads`), que según Salesforce es de
«lectura y consulta, sin cambios»: esquema, SOQL, búsqueda y relaciones.

- Cada llamada corre **con los permisos del usuario conectado**: seguridad a nivel de campo,
  permisos de objeto y reglas de compartición se aplican a cada herramienta.
- Los servidores vienen **desactivados** y los activa un administrador.

| Org | URL del servidor |
|---|---|
| Producción | `https://api.salesforce.com/platform/mcp/v1/platform/sobject-reads` |
| Sandbox o scratch | `https://api.salesforce.com/platform/mcp/v1/sandbox/platform/sobject-reads` |

Los plugins traen la URL de producción en su `.mcp.json`. Para probar en un sandbox, el
conector de la organización se añade con la URL de sandbox (paso 4).

## 1. Activar el servidor MCP

1. En **Setup**, buscar en Quick Find **MCP Servers** (está en el API Catalog).
2. Si aparece la opción **Enable MCP Service**, activarla.
3. En **Salesforce Servers**, activar **SObject Reads** (`sobject-reads`).

No hace falta activar `sobject-all`, `sobject-mutations` ni `sobject-deletes`: escriben o borran,
y esta versión de los plugins solo lee.

## 2. Crear la External Client App

En **Setup > External Client App Manager > New External Client App**:

| Campo | Valor |
|---|---|
| Callback URL | `https://claude.ai/api/mcp/auth_callback` (claude.ai y Cowork). Para Claude Desktop local, además `http://127.0.0.1:53280/callback` |
| OAuth Scopes | `mcp_api` y `refresh_token` (solo esos dos) |
| PKCE | Obligatorio (activado) |
| Tokens | Emitir tokens de acceso JWT para usuarios nombrados |
| Política | Que cada usuario pueda autorizarse a sí mismo, o que solo los usuarios pre-autorizados puedan (ver el paso 3) |

Al guardar, copiar el **Consumer Key**: es el *Client ID* que pide Claude. No hace falta el
Consumer Secret.

**La app puede tardar hasta 30 minutos en funcionar.** Si antes de eso aparece `invalid_client_id`,
hay que esperar.

## 3. Endurecer el acceso (recomendado)

- **Solo usuarios pre-autorizados:** en la política de la app, permitir solo a los usuarios
  con un Permission Set concreto, y asignarlo al grupo piloto.
- **Restricción por IP**, si la empresa la usa en el resto de sus apps.
- **Refresh token de 30 días o menos**, con rotación.
- **Single Logout**, para que cerrar sesión en Salesforce corte también a Claude.
- **Permisos de lectura de cada plugin:** que el Permission Set dé lectura solo a los objetos y
  campos que el plugin necesita (lista en el `docs/03-instalacion-salesforce.md` de cada plugin).
  Lo que el usuario no puede leer, Claude tampoco.

## 4. Añadir el conector en Claude

Un Owner de la organización en Claude, en **Organization settings > Connectors**, añade el
conector `salesforce` del plugin con:

- **URL:** la del servidor (producción o sandbox, tabla de arriba).
- **OAuth Client ID** (en **Advanced settings**): el Consumer Key del paso 2.

Un usuario individual lo hace en **Customize > Connectors > + > Add custom connector** con los
mismos datos. Luego cada usuario conecta su cuenta desde la pestaña **Connectors** del plugin
([instalar-en-claude.md](instalar-en-claude.md#3-cada-usuario-conecta-su-cuenta)).

## 5. Comprobar

Con un usuario del grupo piloto, en un chat nuevo: «¿Con qué usuario de Salesforce estoy
conectado?». Claude debe responder con el usuario correcto. Después, seguir la lista
`docs/06-pruebas-de-aceptacion.md` del plugin.

## Errores frecuentes

| Error | Causa probable | Qué hacer |
|---|---|---|
| `invalid_client_id` | La External Client App aún no se propagó, o el Client ID está mal copiado | Esperar hasta 30 minutos; volver a copiar el Consumer Key |
| Error de redirección (*redirect_uri*) | Falta la Callback URL exacta | Revisar que esté `https://claude.ai/api/mcp/auth_callback`, sin espacios ni barra final |
| Error de token o JWT | No está activada la emisión de JWT para usuarios nombrados | Activarla en la app |
| Claude no ve un campo u objeto | Seguridad a nivel de campo o permisos del objeto | Dar lectura en el Permission Set del usuario |
| El usuario no puede autorizarse | La política exige pre-autorización y no tiene el Permission Set | Asignárselo |

## Costos de Salesforce

Salesforce anunció que cobrará **Flex Credits por cada llamada correcta** de un agente registrado
en una org de producción. El 23 de octubre de 2026 la tarifa aún no estaba publicada, y los
sandboxes, scratch orgs y Developer Edition quedarían fuera del cobro. Esto viene de un
artículo de un tercero ([Stacksync](https://www.stacksync.com/blog/salesforce-mcp-server-endpoints-tools));
**la empresa debe confirmarlo con su ejecutivo de Salesforce**, junto con qué ediciones
incluyen los servidores MCP alojados.

## Fuentes

Consultadas el 2026-11-06 y el 2026-11-07.

- [Standard MCP Servers Reference](https://developer.salesforce.com/docs/platform/hosted-mcp-servers/guide/servers-reference.html) (Salesforce): servidores, solo lectura de SObject Reads, permisos por usuario
- [Create an External Client App](https://developer.salesforce.com/docs/platform/hosted-mcp-servers/guide/create-external-client-app.md) (Salesforce)
- [Try Headless 360: activar los servidores](https://developer.salesforce.com/workshops/try-headless-360/1-activate-the-servers) y [conectar Claude](https://developer.salesforce.com/workshops/try-headless-360/3-connect-claude) (Salesforce)
- [Connect Salesforce to Claude Desktop](https://claude.com/docs/third-party/claude-desktop/connectors-salesforce) (Claude): callback, scopes, endurecimiento y errores
- [Salesforce MCP server endpoints and tools](https://www.stacksync.com/blog/salesforce-mcp-server-endpoints-tools) (Stacksync, tercero): cobro por Flex Credits
