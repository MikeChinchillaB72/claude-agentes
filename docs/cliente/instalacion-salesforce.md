# Preparar Salesforce

> Para el administrador de Salesforce. Actualizado: 2026-11-07. Pasos según la
> documentación oficial de Salesforce y de Claude consultada el 2026-11-06 y el
> 2026-11-07 (fuentes al final). **Pasos 1 a 4 comprobados** el 2026-11-07 en una Developer
> Edition con claude.ai. Las pruebas de cada plugin siguen pendientes (P5 en
> [pendientes.md](../pendientes.md)).

Sirve para los seis plugins. Lo que cambia de uno a otro son los objetos que el usuario
debe poder leer; cada plugin los lista en su `docs/03-instalacion-salesforce.md`.

## Cómo se conecta

Los plugins usan los **servidores MCP alojados por Salesforce** (*hosted MCP servers*).
No hay que mantener un servidor propio. Hay dos:

- Los plugins de solo lectura usan el servidor **SObject Reads** (`sobject-reads`), que según
  Salesforce es de «lectura y consulta, sin cambios»: esquema, SOQL, búsqueda y relaciones.
- **`ventas-seguimiento`** (desde la versión 0.2.0) usa el servidor personalizado **`AgentesCRM`**:
  las mismas herramientas de lectura más tres acciones Apex que se despliegan en la org. Ver
  [Acciones: servidor personalizado AgentesCRM](#acciones-servidor-personalizado-agentescrm).

- Cada llamada corre **con los permisos del usuario conectado**: seguridad a nivel de campo,
  permisos de objeto y reglas de compartición se aplican a cada herramienta.
- Los servidores vienen **desactivados** y los activa un administrador.

| Org | URL del servidor |
|---|---|
| Producción | `https://api.salesforce.com/platform/mcp/v1/platform/sobject-reads` |
| Sandbox o scratch | `https://api.salesforce.com/platform/mcp/v1/sandbox/platform/sobject-reads` |

Los plugins traen la URL de producción en su `.mcp.json`. Para probar en un sandbox, el
conector de la organización se añade con la URL de sandbox (paso 4).

El servidor personalizado `AgentesCRM` no usa esta tabla: su URL lleva el dominio de la org y se copia
de Setup (ver [Acciones](#acciones-servidor-personalizado-agentescrm)).

## 1. Activar el servidor MCP

1. En **Setup**, buscar en Quick Find **MCP Servers** (está en el API Catalog).
2. Si aparece la opción **Enable MCP Service**, activarla.
3. En **Salesforce Servers**, activar **SObject Reads** (`sobject-reads`).

No hay que activar `sobject-all`, `sobject-mutations` ni `sobject-deletes`: escriben o borran
cualquier objeto que el usuario pueda editar. Las escrituras de los plugins van por acciones
concretas en el servidor `AgentesCRM`.

## 2. Crear la External Client App

En **Setup > External Client App Manager > New External Client App**:

| Campo | Valor |
|---|---|
| Basic Information | Nombre (por ejemplo `Claude Plugins CRM`), correo y teléfono de contacto, **Distribution State** `Local` y una descripción de para qué es la app |
| Callback URL | `https://claude.ai/api/mcp/auth_callback` (claude.ai y Cowork). **Salesforce rechaza direcciones `http://`** («Cannot be an HTTP URL»), así que no sirve el callback local de Claude Desktop |
| OAuth Scopes | **Access Salesforce hosted MCP servers (mcp_api)** y **Perform requests at any time (refresh_token, offline_access)**. Solo esos dos |
| Security | Marcar **Issue JSON Web Token (JWT)-based access tokens for named users**. Salesforce ya deja marcados y bloqueados PKCE, la rotación del refresh token y su límite de 30 días. Dejar sin marcar **Require secret for Web Server Flow**, **Require secret for Refresh Token Flow**, **Enforce Refresh Token IP Allowlist** y **DPoP** |
| Política | Que cada usuario pueda autorizarse a sí mismo, o que solo los usuarios pre-autorizados puedan (ver el paso 3) |

Al guardar, en **Settings > OAuth Settings > Consumer Key and Secret**, copiar el **Consumer Key**:
es el *Client ID* que pide Claude. No hace falta el Consumer Secret.

**La app puede tardar hasta 30 minutos en funcionar.** Si antes de eso aparece `invalid_client_id`,
hay que esperar.

## 3. Endurecer el acceso (recomendado)

- **Solo usuarios pre-autorizados:** en la política de la app, permitir solo a los usuarios
  con un Permission Set concreto, y asignarlo al grupo piloto.
- **Restricción por IP**, si la empresa la usa en el resto de sus apps.
- **Refresh token de 30 días o menos**, con rotación (en una org nueva, Salesforce ya lo impone).
- **Single Logout**, para que cerrar sesión en Salesforce corte también a Claude.
- **Permisos de lectura de cada plugin:** que el Permission Set dé lectura solo a los objetos y
  campos que el plugin necesita (lista en el `docs/03-instalacion-salesforce.md` de cada plugin).
  Lo que el usuario no puede leer, Claude tampoco.

## 4. Añadir el conector en Claude

Un Owner de la organización en Claude lo añade en **Organization settings > Connectors**; un usuario
individual, en **Customize > Connectors > + > Add custom connector**. La pantalla (comprobada el
2026-11-07) se llena así:

| Campo | Valor |
|---|---|
| Nombre | `Salesforce` |
| MCP Server URL | `sobject-reads`: la de la tabla de arriba (una Developer Edition usa la de producción). `AgentesCRM`: la que muestra Setup, con el dominio de la org |
| Authentication | **Sign in now**: cada usuario inicia sesión en Salesforce antes de usar nada |
| OAuth client | **Use your own OAuth client**, con el Consumer Key del paso 2 como Client ID y el secreto vacío. No usar *Register automatically*, que registraría clientes nuevos en la org |
| Request headers | Ninguno |
| Advanced > Transport | **Streamable HTTP** |

Al pulsar **Add**, Claude lleva al inicio de sesión de Salesforce.

### Herramientas que expone

El servidor `sobject-reads` ofrece seis herramientas, todas de lectura (comprobado el 2026-11-07):
**Search Across Objects (SOSL)**, **Get Object Schema (Enhanced)**, **Get Related Records**,
**Get Current User Info**, **Get Recently Viewed Records** y **Query Records (SOQL)**. En la página
del conector, **Tool permissions** deja elegir para cada una *Always allow*, *Needs approval* o
*Never*. Para las pruebas conviene **Needs approval**, para ver cada consulta. Luego cada usuario conecta su cuenta desde la pestaña **Connectors** del plugin
([instalar-en-claude.md](instalar-en-claude.md#3-cada-usuario-conecta-su-cuenta)).

## Acciones: servidor personalizado AgentesCRM

Solo si la empresa usa `ventas-seguimiento` 0.2.0 o posterior. **Sin probar todavía en una org**
(P10 en [pendientes.md](../pendientes.md)).

Un servidor personalizado junta herramientas de lectura con acciones de negocio hechas en Apex o
Flow ([Build Custom MCP Servers](https://developer.salesforce.com/docs/platform/hosted-mcp-servers/guide/custom-servers.html)).
Así Claude solo puede hacer lo que esas acciones permiten, con sus validaciones, en vez de editar
cualquier campo.

1. **Desplegar las acciones** de [salesforce/](../../salesforce/README.md) con Salesforce CLI. Las
   pruebas de Apex tienen que pasar.
2. En **Setup > MCP Servers > Salesforce Servers > Create Salesforce MCP Server**: **Label**
   `Agentes CRM` y **Name** `AgentesCRM`. El nombre forma parte de la URL.
3. **Add Server Assets > Add Tools**, tipo **Apex actions**: añadir solo las acciones que la empresa
   habilite (`acciones_habilitadas` en el `criterios.md` del plugin):
   - Actualizar próximo paso de una oportunidad (`AgentesActualizarProximoPaso`)
   - Crear tarea de seguimiento en una oportunidad (`AgentesCrearTareaSeguimiento`)
   - Mover fecha de cierre de una oportunidad (`AgentesMoverFechaCierre`)
4. **Add Server Assets > Add from Server > sobject-reads**: añadir sus seis herramientas de lectura.
5. **Activate** y copiar la **Server URL** tal como la muestra Setup. Lleva el dominio de la org:
   `https://api.salesforce.com/platform/mcp/v1/d/<dominio>/<tipo>/custom/AgentesCRM` (por ejemplo `.../d/miempresa/develop/custom/AgentesCRM`
   en una Developer Edition, comprobado el 2026-11-07). La URL general sin dominio, que sí sirve para
   `sobject-reads`, no sirve para un servidor personalizado.
6. Asignar a los usuarios el Permission Set **Agentes CRM - Acciones** y los permisos de edición
   que lista el `docs/03-instalacion-salesforce.md` del plugin.
7. En Claude, el conector de este plugin usa esa URL (paso 4 de esta guía) y, en **Tool permissions**,
   las tres acciones van en **Needs approval**. Así cada cambio pide el sí del usuario, aunque las
   instrucciones fallen.

Los pasos 2 a 5 siguen el [taller oficial de Salesforce](https://developer.salesforce.com/workshops/headless-360-workshop/explore-salesforce-hosted-mcps/3-create-and-test-custom-server).
Qué ediciones incluyen los servidores personalizados y si cobran por llamada está sin confirmar (P9).

## 5. Comprobar

Con un usuario del grupo piloto, en un chat nuevo: «¿Con qué usuario de Salesforce estoy
conectado?». Claude debe responder con el usuario correcto (comprobado el 2026-11-07). Después, seguir la lista
`docs/06-pruebas-de-aceptacion.md` del plugin.

## Errores frecuentes

| Error | Causa probable | Qué hacer |
|---|---|---|
| `invalid_client_id` | La External Client App aún no se propagó, o el Client ID está mal copiado | Esperar hasta 30 minutos; volver a copiar el Consumer Key |
| `Cannot be an HTTP URL` al crear la app | Hay una Callback URL con `http://` | Dejar solo `https://claude.ai/api/mcp/auth_callback` |
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
- [Build Custom MCP Servers](https://developer.salesforce.com/docs/platform/hosted-mcp-servers/guide/custom-servers.html) (Salesforce, consultada el 2026-11-07): servidores personalizados con Flows y Apex
- [Expose Custom Apex as a Hosted MCP Tool](https://developer.salesforce.com/blogs/2026/05/expose-custom-apex-as-a-hosted-mcp-tool-for-agents) (Salesforce, consultada el 2026-11-07): `@InvocableMethod`, `with sharing` y `USER_MODE`
- [Create a Custom Server](https://developer.salesforce.com/workshops/headless-360-workshop/explore-salesforce-hosted-mcps/3-create-and-test-custom-server) (taller de Salesforce, consultado el 2026-11-07): pasos en Setup y formato de la URL
- [Create an External Client App](https://developer.salesforce.com/docs/platform/hosted-mcp-servers/guide/create-external-client-app.md) (Salesforce)
- [Try Headless 360: activar los servidores](https://developer.salesforce.com/workshops/try-headless-360/1-activate-the-servers) y [conectar Claude](https://developer.salesforce.com/workshops/try-headless-360/3-connect-claude) (Salesforce)
- [Connect Salesforce to Claude Desktop](https://claude.com/docs/third-party/claude-desktop/connectors-salesforce) (Claude): callback, scopes, endurecimiento y errores
- [Salesforce MCP server endpoints and tools](https://www.stacksync.com/blog/salesforce-mcp-server-endpoints-tools) (Stacksync, tercero): cobro por Flex Credits
