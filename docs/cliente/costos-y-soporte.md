# Costos, versiones y soporte

> Actualizado: 2026-11-07. Los precios cambian; confírmalos en la página oficial de cada
> proveedor antes de presupuestar.

## Costos

| Concepto | Quién lo cobra | Qué se sabe |
|---|---|---|
| Uso de Claude | Anthropic, dentro del plan de cada usuario (Pro, Max, Team o Enterprise) | Los plugins no tienen costo propio ni se cobran tokens aparte. El uso cuenta para los límites del plan del usuario |
| Distribuir a la organización | Anthropic | Hace falta plan Team o Enterprise |
| Servidores MCP de Salesforce | Salesforce | Anunció cobro en Flex Credits por llamada en producción, con tarifa sin publicar al 23 de octubre de 2026 (fuente de un tercero; ver [instalacion-salesforce.md](instalacion-salesforce.md#costos-de-salesforce)). **A confirmar con Salesforce**, igual que las ediciones que los incluyen |
| Servidor MCP de monday.com | monday.com | La documentación consultada no dice en qué planes está ni si tiene costo o límites propios. **A confirmar con monday.com** |
| Servidor propio | — | No hay. Los dos servidores los aloja cada plataforma |

**Cómo bajar el uso:** pedir resultados acotados («las 10 oportunidades más grandes sin
actividad», no «todas»). Las skills ya piden traer solo los campos necesarios.

## Versiones

Cada plugin lleva su versión en `.claude-plugin/plugin.json` y sigue *semantic versioning*:
el tercer número para correcciones, el segundo para funciones nuevas compatibles y el primero
para cambios que obligan a reconfigurar.

| Versión | Fecha | Cambios |
|---|---|---|
| 0.1.0 | 2026-11-07 | Primera versión: seis plugins de solo lectura, con conectores para Salesforce y monday.com y su documentación. Sin probar en plataforma real |

Una versión 0.x no está lista para producción. Pasa a 1.0.0 cuando la empresa confirme los
requisitos y el plugin pase sus pruebas de aceptación en un sandbox de Salesforce o una cuenta de
prueba de monday.com.

## Soporte

| Problema | A quién |
|---|---|
| El plugin no aparece o no se instala en Claude | Owner de la organización en Claude; ver [instalar-en-claude.md](instalar-en-claude.md) |
| No conecta con Salesforce o monday.com | Administrador del CRM; ver la tabla de errores de [instalacion-salesforce.md](instalacion-salesforce.md#errores-frecuentes) o [instalacion-monday.md](instalacion-monday.md) |
| Claude no ve un dato que el usuario sí ve en el CRM | Administrador del CRM: revisar permisos de campo o *scopes* |
| La respuesta es incorrecta o no sigue los criterios de la empresa | Responsable del plugin: revisar los criterios en la carpeta `references/` de la skill y abrir un *issue* en el repositorio con un ejemplo |
| Incidente de seguridad | Apagar primero ([seguridad.md](seguridad.md#interruptor-de-apagado)) y avisar después |

**Responsable de los plugins:** pendiente de que la empresa lo designe (se anota en el
`docs/01-requisitos.md` de cada plugin).

## Desinstalar

1. Claude: **Organization settings > Plugins & skills**, poner el plugin en **Not available**,
   o cada usuario lo quita en **Customize > Plugins**.
2. Claude: quitar el conector en **Organization settings > Connectors** si ningún otro plugin lo usa.
3. Salesforce: desactivar la External Client App y, si ya no se usa, el servidor `sobject-reads`.
4. monday.com: eliminar la app OAuth propia en **Developers**.

Nada queda instalado dentro de Salesforce ni de monday.com aparte de esa app y la activación del servidor.
