# Acciones de Salesforce para los plugins

> Actualizado: 2026-11-07. **Estado:** sintaxis comprobada con un analizador de Apex; **sin
> compilar ni probar en una org** (P10 en [pendientes](../docs/pendientes.md)).

Proyecto de Salesforce con las acciones que los plugins de Claude pueden ejecutar en el CRM. Cada
acción es una clase Apex `@InvocableMethod` que se publica como herramienta de un **servidor MCP
personalizado** llamado `AgentesCRM`. Ese servidor junta las herramientas de lectura de
`sobject-reads` con estas acciones. Claude no recibe permiso para escribir en cualquier campo: solo
para ejecutar estas acciones, cada una con sus validaciones.

## Acciones

| Clase | Herramienta | Qué hace | Plugin |
|---|---|---|---|
| `AgentesActualizarProximoPaso` | Actualizar próximo paso de una oportunidad | Reemplaza `NextStep` de oportunidades abiertas | `ventas-seguimiento` |
| `AgentesCrearTareaSeguimiento` | Crear tarea de seguimiento en una oportunidad | Crea una `Task` ligada a la oportunidad, asignada al usuario conectado | `ventas-seguimiento` |
| `AgentesMoverFechaCierre` | Mover fecha de cierre de una oportunidad | Cambia `CloseDate` a hoy o una fecha posterior | `ventas-seguimiento` |

`AgentesCrmAcciones` guarda las reglas comunes (regla T10) y `AgentesCrmAccionesTest` las prueba,
también rotas a propósito (regla T2).

## Reglas que cumplen todas

- **Permisos del usuario:** las clases son `with sharing` y consultan y guardan en
  `AccessLevel.USER_MODE`, así que respetan compartición, permisos de objeto y de campo
  ([Salesforce Developers](https://developer.salesforce.com/blogs/2026/05/expose-custom-apex-as-a-hosted-mcp-tool-for-agents)).
- **Solo oportunidades abiertas.** Una cerrada no se modifica.
- **Ninguna fecha pasada.** Las fechas se comparan con el día del usuario.
- **Nada se borra.** Ninguna acción elimina registros.
- **Cada solicitud por separado:** si una falla, las demás siguen, y el resultado dice cuál falló y por qué.
- **El SOQL no recibe texto de fuera:** los campos de la consulta salen de una lista fija.

## Desplegar

Con [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli), desde esta carpeta:

```bash
sf org login web --alias agentes-crm
sf project deploy start --target-org agentes-crm --test-level RunSpecifiedTests --tests AgentesCrmAccionesTest
```

En producción, Salesforce exige que las pruebas pasen y cubran al menos el 75 % del Apex.

## Crear el servidor MCP personalizado

En **Setup > MCP Servers > Salesforce Servers > Create Salesforce MCP Server**
([taller de Salesforce](https://developer.salesforce.com/workshops/headless-360-workshop/explore-salesforce-hosted-mcps/3-create-and-test-custom-server)):

1. **Label** `Agentes CRM`, **Name** `AgentesCRM`. El nombre tiene que ser exactamente ese, porque
   forma la URL que traen los plugins.
2. **Add Server Assets > Add Tools**, tipo **Apex actions**: añadir las acciones que la empresa
   habilite (`acciones_habilitadas` en el `criterios.md` del plugin). Lo que no se añade aquí, Claude no lo puede hacer.
3. **Add Server Assets > Add from Server > sobject-reads**: añadir las seis herramientas de lectura.
4. **Activate**, y copiar la **Server URL**. En producción y Developer Edition debe ser
   `https://api.salesforce.com/platform/mcp/v1/custom/AgentesCRM`.
5. Asignar el Permission Set **Agentes CRM - Acciones** (`Agentes_CRM_Acciones`) a los usuarios
   del plugin. Solo da acceso a las clases; lo que pueden editar lo deciden sus otros permisos.

La guía completa para el cliente está en [instalacion-salesforce.md](../docs/cliente/instalacion-salesforce.md).

## Sin comprobar

- Que las clases compilen y las pruebas pasen en una org (P10).
- La URL del servidor personalizado en un sandbox: siguiendo el patrón de los servidores estándar
  sería `https://api.salesforce.com/platform/mcp/v1/sandbox/custom/AgentesCRM`. Hay que copiarla de Setup.
- El nombre exacto con que el servidor publica cada herramienta. Las skills nombran las acciones
  por su etiqueta, no por ese nombre.
- Si el servidor marca las herramientas como de lectura o de escritura para que claude.ai las agrupe
  en *Tool permissions*. Por eso la guía pide poner cada acción en **Needs approval** a mano.
