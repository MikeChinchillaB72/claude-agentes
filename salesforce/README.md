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

`AgentesCrmAcciones` guarda las reglas comunes (regla T10).

## Pruebas

Cada clase tiene su clase de prueba, como pide Salesforce
([Apex Developer Guide: Testing Best Practices](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_testing_best_practices.htm)):

| Clase | Su prueba |
|---|---|
| `AgentesCrmAcciones` | `AgentesCrmAccionesTest` |
| `AgentesActualizarProximoPaso` | `AgentesActualizarProximoPasoTest` |
| `AgentesCrearTareaSeguimiento` | `AgentesCrearTareaSeguimientoTest` |
| `AgentesMoverFechaCierre` | `AgentesMoverFechaCierreTest` |

Los datos los crea una sola fábrica, `AgentesTestDataFactory` (`@IsTest`). Cada clase de prueba:

- Prueba el caso válido y cada regla rota a propósito (regla T2), y en los casos que fallan
  comprueba que el registro no cambió.
- Corre un lote de 200 registros (el tamaño de un lote de trigger) en una sola llamada.
- Corre la acción con `System.runAs` como dos usuarios con permisos mínimos: uno que no lee
  oportunidades y otro que solo las lee (con un Permission Set creado en la prueba). Las dos deben
  fallar sin cambiar nada, sea cual sea la compartición de la org.
- Usa `Test.startTest()`/`Test.stopTest()` en cada prueba y la clase `Assert`.

El perfil de los usuarios de prueba se busca por sus permisos, no por su nombre, porque Salesforce traduce
los nombres de los perfiles estándar al idioma del usuario. En una org nueva, la búsqueda da
«Minimum Access - Salesforce».

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
sf project deploy start --target-org agentes-crm --test-level RunSpecifiedTests --tests AgentesCrmAccionesTest --tests AgentesActualizarProximoPasoTest --tests AgentesCrearTareaSeguimientoTest --tests AgentesMoverFechaCierreTest
```

En producción, Salesforce exige que las pruebas pasen y cubran al menos el 75 % del Apex.

Sin CLI, en Developer Console: crear primero `AgentesTestDataFactory` y luego las cuatro clases de prueba
(**File > New > Apex Class**), y correrlas con **Test > New Run**. La cobertura de cada clase sale en la
pestaña **Tests** y en **Overall Code Coverage**.

## Crear el servidor MCP personalizado

En **Setup > MCP Servers > Salesforce Servers > Create Salesforce MCP Server**
([taller de Salesforce](https://developer.salesforce.com/workshops/headless-360-workshop/explore-salesforce-hosted-mcps/3-create-and-test-custom-server)):

1. **Label** `Agentes CRM`, **Name** `AgentesCRM`. El nombre forma parte de la URL del servidor.
2. **Add Server Assets > Add Tools**, tipo **Apex actions**: añadir las acciones que la empresa
   habilite (`acciones_habilitadas` en el `criterios.md` del plugin). Lo que no se añade aquí, Claude no lo puede hacer.
3. **Add Server Assets > Add from Server > sobject-reads**: añadir las seis herramientas de lectura.
4. **Activate**, y copiar la **Server URL** tal como la muestra Setup. Un servidor personalizado lleva
   el dominio de la org: `https://api.salesforce.com/platform/mcp/v1/d/<dominio>/<tipo>/custom/AgentesCRM`. En la Developer Edition
   de prueba fue `https://api.salesforce.com/platform/mcp/v1/d/orgfarm-812b871b57-dev-ed/develop/custom/AgentesCRM`
   (2026-11-07). Los servidores estándar, como `sobject-reads`, sí usan una URL general sin dominio.
5. Asignar el Permission Set **Agentes CRM - Acciones** (`Agentes_CRM_Acciones`) a los usuarios
   del plugin. Solo da acceso a las clases; lo que pueden editar lo deciden sus otros permisos.

La guía completa para el cliente está en [instalacion-salesforce.md](../docs/cliente/instalacion-salesforce.md).

## Las descripciones son instrucciones para Claude

Claude no ve el código Apex. Para elegir una acción y llenar sus datos solo ve lo que el servidor
publica de cada clase:

| Lo que ve Claude | De dónde sale |
|---|---|
| Nombre de la herramienta | El nombre de la clase (`AgentesMoverFechaCierre`) |
| Descripción de la herramienta | `description` de `@InvocableMethod` |
| Datos de entrada y su formato | Cada `@InvocableVariable` de `Solicitud`: tipo, `label`, `description` y `required` |
| Lo que devuelve | Cada `@InvocableVariable` de `Resultado` |

Por eso esos textos se escriben como instrucciones: qué hace la acción (con el nombre del campo en la
API y en palabras del usuario), qué no hace y cuándo usarla. Si dos acciones se parecen, sus
descripciones deben distinguirlas. **Cambiar una descripción cambia cómo se comporta Claude**, así que
todo cambio se vuelve a probar con las pruebas de aceptación del plugin, no solo con las de Apex.

## Comprobado en la Developer Edition (2026-11-07)

- Las clases compilan y las 37 pruebas de Apex pasan.
- El servidor publica cada acción con el nombre de su clase, y claude.ai la agrupa en *Tool permissions*
  como **Write/delete tools**, aparte de las seis de lectura.
- Las acciones funcionan desde claude.ai (pruebas P6 a P9 de `ventas-seguimiento`).

## Sin comprobar

- La URL del servidor en un sandbox y en producción. Se copia de Setup.
- Qué ediciones incluyen los servidores personalizados y si cobran por llamada (P9).
