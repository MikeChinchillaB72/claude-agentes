# Añadir los plugins a Claude

> Actualizado: 2026-11-07. Pasos según la documentación oficial de Claude consultada el
> 2026-11-06 y el 2026-11-07 (fuentes al final). Los nombres de menú pueden cambiar; si
> no coinciden, manda la documentación oficial.

Antes de este paso, el administrador del CRM tiene que haber preparado la plataforma:
[Salesforce](instalacion-salesforce.md) o [monday.com](instalacion-monday.md).

## Qué recibe Claude

Los seis plugins están en un catálogo (*marketplace*) dentro de este repositorio:
[`.claude-plugin/marketplace.json`](../../.claude-plugin/marketplace.json). El catálogo se llama
`agentes-crm`. Cada plugin está en `plugins/<nombre>/` y trae:

| Pieza | Para qué | Dónde funciona |
|---|---|---|
| Skills (`skills/`) | Las instrucciones de cada tarea | claude.ai, Cowork y Claude Code |
| Conectores (`.mcp.json`) | Las conexiones a Salesforce y a monday.com | claude.ai y Cowork (pestaña **Connectors** del plugin) y Claude Code |
| Documentos (`docs/`) | Requisitos, instalación, uso, pruebas y preguntas frecuentes | Para leer; Claude no los carga |

Los plugins no traen carpeta `bin/` (impediría instalarlos en claude.ai y Cowork) ni guardan
claves: cada usuario inicia sesión con su propia cuenta.

## 1. Añadir el catálogo a la organización (plan Team o Enterprise)

Lo hace un **Owner** de la organización en Claude.

1. Abrir **Organization settings > Plugins & skills**.
2. Elegir **Add** y luego **Sync from GitHub**, e indicar el repositorio
   `MikeChinchillaB72/claude-agentes`. Si el repositorio es privado, Claude pedirá acceso a GitHub.
3. Elegir para cada plugin su disponibilidad:
   - **Not available**: nadie lo ve.
   - **Available to install**: cada usuario decide si lo instala.
   - **Installed by default**: se instala a todos, y cada uno puede quitarlo.
   - **Required**: se instala a todos y no se puede quitar.

   Recomendación: empezar con **Available to install** solo para el grupo piloto que hará
   las pruebas de aceptación.

## 2. Añadir los conectores a la organización

Los conectores del plugin los añade un **Owner** en **Organization settings > Connectors**.
Los datos que pide cada uno están en el documento de su plataforma:

- Salesforce: la URL del servidor MCP y el *Consumer Key* de la External Client App
  ([instalacion-salesforce.md](instalacion-salesforce.md#4-añadir-el-conector-en-claude)).
- monday.com: la URL del servidor MCP y, si se usa una app propia, su Client ID y Client Secret
  ([instalacion-monday.md](instalacion-monday.md#4-añadir-el-conector-en-claude)).

Cada plugin trae los dos conectores. **Se añade solo el de la plataforma que usa la empresa.**
El otro se queda sin conectar y no hace nada.

## 3. Cada usuario conecta su cuenta

1. Abrir **Customize > Plugins**, elegir el plugin e instalarlo (si no venía instalado).
2. En la pestaña **Connectors** del plugin, conectar `salesforce` o `monday` e iniciar sesión
   con la cuenta propia. Claude verá lo mismo que esa cuenta ve en el CRM, y nada más.
3. Comprobar en un chat nuevo: «¿Qué skills tienes de plugins?». Debe nombrar las del plugin.

## Usuario individual (sin organización)

En **Customize > Plugins > Add** hay dos caminos:

- **Add marketplace**, con la URL del repositorio. Recibe las actualizaciones del catálogo.
- **Upload plugin**, con un `.zip` de la carpeta del plugin (por ejemplo `plugins/ventas-seguimiento`).
  El `.zip` debe tener `.claude-plugin/plugin.json` en su raíz o dentro de una sola carpeta.

Luego se añade el conector en **Customize > Connectors > + > Add custom connector** con los
mismos datos del paso 2 (la URL va en el campo principal; el Client ID, en **Advanced settings**).

## Claude Code

```bash
/plugin marketplace add MikeChinchillaB72/claude-agentes
/plugin install ventas-seguimiento@agentes-crm
```

O en un solo paso (Claude Code 2.1.275 o posterior):
`/plugin install ventas-seguimiento --marketplace MikeChinchillaB72/claude-agentes`.

Al instalar se elige el alcance (usuario, proyecto o local). Claude Code conecta los
servidores del `.mcp.json` directamente y `/mcp` muestra su estado.

**Sin comprobar todavía:** la autenticación de Salesforce desde Claude Code. El servidor de
Salesforce usa la External Client App de la empresa, y Claude Code necesita su Client ID. Si
`/mcp` no logra iniciar sesión, se puede añadir el servidor a mano con
`claude mcp add --transport http --client-id <Consumer Key> --callback-port <puerto> salesforce <URL>`
usando como callback `http://localhost:<puerto>/callback` en la External Client App.
Queda como pendiente de la prueba real (P5 en [pendientes.md](../pendientes.md)).

## Actualizar y desinstalar

- **Actualizar:** al subir la versión en el repositorio, la sincronización de la organización
  (o el catálogo del usuario) trae la nueva. Cada versión dice qué cambió en
  [costos-y-soporte.md](costos-y-soporte.md#versiones).
- **Apagar un plugin para todos:** en **Organization settings > Plugins & skills**, ponerlo en
  **Not available**. No hace falta tocar el repositorio.
- **Cortar el acceso a los datos:** revocar la app de conexión en Salesforce o en monday.com
  (ver [seguridad.md](seguridad.md#interruptor-de-apagado)).

## Fuentes

Consultadas el 2026-11-06 y el 2026-11-07.

- [Plugin structure and testing](https://claude.com/docs/plugins/build) (claude.com)
- [Manage plugins for your organization](https://claude.com/docs/plugins/admin) (claude.com)
- [Plugin marketplaces](https://code.claude.com/docs/en/plugin-marketplaces) (Claude Code)
- [Plugin components](https://code.claude.com/docs/en/plugins/components) (Claude Code)
- [MCP en Claude Code](https://code.claude.com/docs/en/mcp): `--client-id`, `--callback-port` y `/mcp`
