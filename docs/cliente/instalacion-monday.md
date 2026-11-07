# Preparar monday.com

> Para el administrador de la cuenta de monday.com. Actualizado: 2026-11-07. Pasos según
> la documentación oficial de monday.com consultada el 2026-11-06 y el 2026-11-07 (fuentes
> al final). **Sin probar todavía en una cuenta real** (P5 en [pendientes.md](../pendientes.md)).

Sirve para los seis plugins. Lo que cambia de uno a otro son los tableros que deben existir
y los permisos (*scopes*) que necesita; cada plugin los lista en su
`docs/04-instalacion-monday.md`.

## Cómo se conecta

Los plugins usan el **servidor MCP alojado por monday.com**: `https://mcp.monday.com/mcp`.
No hay que instalar nada ni mantener un servidor propio.

- Cada llamada corre **en el contexto del usuario conectado**: ve lo que ese usuario ve.
- El servidor tiene herramientas que leen (`get_board_items_by_name`, `get_board_schema`,
  `list_users_and_teams`...) y herramientas que escriben (`create_item`,
  `change_item_column_values`, `create_update`, `delete_item`...).
- El servidor alojado **no documenta un modo de solo lectura**. La forma de garantizar que los
  plugins solo lean es una **app OAuth propia con permisos de solo lectura**: el token
  «no puede pasar ninguno de los dos límites», ni los permisos del usuario ni los *scopes* de la app.

## Elegir cómo conectar

| Opción | Qué da | Cuándo |
|---|---|---|
| **A. App OAuth propia** (recomendada) | Solo lectura garantizada por los *scopes*; la empresa controla y revoca la app | Siempre que se use con datos reales |
| B. Conector alojado de monday.com, sin app propia | El usuario autoriza con todos sus permisos, incluido escribir | Solo para una prueba rápida con una cuenta de prueba |

Con la opción B, nada impide técnicamente que Claude escriba si alguien se lo pide; solo lo
frenan las instrucciones del plugin y la confirmación que Claude pide antes de usar una
herramienta. Por eso no se recomienda con datos reales.

## 1. Crear la app OAuth propia

1. Clic en la foto de perfil (arriba a la derecha) > **Developers** > **+ Create app**. Poner
   nombre y *slug* (por ejemplo `claude-plugins-crm`) y **Create app**.
2. En **Build > OAuth & Permissions**, activar **New OAuth flow**. Sin esto, la app no sirve para MCP.
3. En la pestaña **Scopes**, marcar **solo** los de lectura que pide el plugin. El conjunto
   para los seis plugins es:
   - `me:read`, `account:read`, `users:read`, `teams:read`
   - `workspaces:read`, `boards:read`, `updates:read`
   - `docs:read` (solo para `servicio-respuestas-conocimiento`, si la base de conocimiento está en docs de monday)

   **Ningún `:write`.** Cada plugin dice cuáles usa en su `docs/04-instalacion-monday.md`.
4. En la pestaña **Redirect URLs**, añadir `https://claude.ai/api/mcp/auth_callback` y **Save**.
5. En **General Settings > App Credentials**, copiar el **Client ID** y el **Client Secret**.
   El Client Secret es una credencial: se pega solo en la configuración del conector en Claude,
   nunca en el repositorio ni en un chat.

## 2. Desactivar el conector alojado genérico

En la configuración de administrador de monday.com, **desactivar el conector MCP alojado
integrado**, para que los usuarios solo puedan conectar por la app propia. La documentación de
monday.com no da la ruta exacta del menú; hay que buscarla en la administración de la cuenta.

## 3. Limitar los espacios de trabajo (opcional)

El servidor admite **controles por espacio de trabajo** (*workspace controls*) para limitar a
qué espacios puede llegar. Si la empresa los usa, dejar solo los espacios de ventas o de
servicio que necesita cada plugin.

## 4. Añadir el conector en Claude

Un Owner de la organización en Claude, en **Organization settings > Connectors**, añade el
conector `monday` del plugin con:

- **MCP Server URL:** `https://mcp.monday.com/mcp`
- **Authentication:** **Sign in now**.
- **OAuth client:** **Use your own OAuth client**, con el Client ID y el Client Secret del paso 1.

Así se llamaban las opciones en la pantalla de Salesforce el 2026-11-07; con monday.com está sin comprobar.

Un usuario individual lo hace en **Customize > Connectors > + > Add custom connector** con los
mismos datos. Luego cada usuario conecta su cuenta desde la pestaña **Connectors** del plugin
([instalar-en-claude.md](instalar-en-claude.md#3-cada-usuario-conecta-su-cuenta)).

## 5. Comprobar

1. Un usuario del grupo piloto conecta su cuenta y pregunta en un chat nuevo: «¿Con qué
   usuario de monday.com estoy conectado y qué tableros ves?».
2. El administrador confirma en **Developers** que la conexión aparece bajo la app propia.
3. Seguir la lista `docs/06-pruebas-de-aceptacion.md` del plugin, incluida la prueba de que
   una escritura falla.

## Los tableros son de cada empresa

En monday CRM y monday service los tableros y sus columnas se personalizan. Los plugins no
suponen nombres de columnas: leen el esquema del tablero (`get_board_schema`) y usan el
**mapeo de columnas** que la empresa define en el `docs/01-requisitos.md` de cada plugin.
Mientras ese mapeo esté pendiente, Claude pregunta qué columna corresponde a cada dato.

## Alternativa local (solo Claude Code)

Para desarrollo, existe el servidor local `@mondaydotcomorg/monday-api-mcp`, que sí tiene modo
de solo lectura (`--read-only`) y usa un token personal en la variable `MONDAY_TOKEN`:

```bash
npx @mondaydotcomorg/monday-api-mcp --read-only
```

No sirve para claude.ai ni para Cowork en la web, porque se ejecuta en la máquina del usuario.

## Fuentes

Consultadas el 2026-11-06 y el 2026-11-07.

- [monday MCP overview](https://developer.monday.com/api-reference/docs/monday-mcp-overview) (monday.com)
- [Control MCP access with an OAuth app](https://developer.monday.com/api-reference/docs/control-mcp-access-with-oauth-app) (monday.com): pasos, contexto del usuario y límites del token
- [Integrating monday MCP with Claude using a custom app](https://developer.monday.com/api-reference/docs/integrating-monday-mcp-with-claude-custom-app) (monday.com)
- [OAuth: permission scopes](https://developer.monday.com/apps/docs/oauth#set-up-permission-scopes) (monday.com): lista de *scopes*
- [mondaycom/mcp](https://github.com/mondaycom/mcp) (GitHub de monday.com): URL alojada, herramientas, `--read-only`, controles por espacio de trabajo
