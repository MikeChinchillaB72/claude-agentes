# Seguridad y datos: Seguimiento de oportunidades

> Plugin `ventas-seguimiento` 0.2.0. Actualizado: 2026-11-07.

El modelo común está en [seguridad.md](../../../docs/cliente/seguridad.md). Aquí va lo propio de este plugin.

## Qué puede hacer

| Puede | No puede |
|---|---|
| Leer los registros que el usuario conectado puede ver | Borrar registros |
| Redactar textos y propuestas en el chat | Enviar correos o mensajes |
| Con confirmación: actualizar el próximo paso de una oportunidad abierta | Cambiar etapa, monto, responsable u otros campos |
| Con confirmación: crear una tarea de seguimiento asignada al usuario | Tocar oportunidades cerradas o poner fechas pasadas |
| Con confirmación: mover la fecha de cierre a hoy o después | Ver o editar lo que el usuario no puede en el CRM |

**Cómo se controla la escritura, de lo más fuerte a lo más débil:**

| Capa | Salesforce | monday.com |
|---|---|---|
| 1. Qué herramientas existen | El servidor `AgentesCRM` solo tiene las herramientas de lectura y las acciones Apex que el administrador añadió. Cada acción valida sus datos y corre con los permisos del usuario ([salesforce/](../../../salesforce/README.md)) | La app OAuth propia tiene `boards:write` y `updates:write`, que permiten más cosas que estas tres acciones |
| 2. Qué herramientas puede usar Claude | En **Tool permissions** del conector, el Owner pone las acciones en *Needs approval*: cada ejecución pide el sí del usuario | El Owner bloquea todas las herramientas de escritura salvo `change_item_column_values`, `create_item` y `create_update`, y pone esas en *Needs approval* |
| 3. Instrucciones | La skill solo propone las acciones de `acciones_habilitadas` y espera la confirmación del usuario en el chat | Igual |

En monday.com la capa 1 es más débil, porque los *scopes* no distinguen columnas ni tableros.
Por eso ahí la capa 2 es obligatoria ([instalacion-monday.md](../../../docs/cliente/instalacion-monday.md#elegir-cómo-conectar)).

## Datos que lee

| Salesforce | Campos |
|---|---|
| `Opportunity` | Id, Name, AccountId, Amount, StageName, CloseDate, LastActivityDate, NextStep, OwnerId, IsClosed |
| `Account` | Id, Name |
| `Contact` | Id, Name, Email, Title |
| `OpportunityContactRole` | OpportunityId, ContactId, IsPrimary, Role |
| `Task y Event` | WhatId, Subject, ActivityDate, Description |
| `User` | Id, Name |

| monday.com | Datos |
|---|---|
| Negocios (*Deals*) | Responsable, monto, etapa, fecha de cierre, fecha de última actividad, contacto vinculado |
| Contactos (*Contacts*) | Nombre, email, cargo, cuenta |

Estos registros pasan a la conversación con Claude. Para que Claude no vea un campo, se le quita
la lectura en el Permission Set (Salesforce) o se deja la columna fuera de los tableros del usuario
(monday.com).

## Datos personales

Puede tratar nombres, correos, cargos e historial de interacciones de contactos y clientes.
Campos que la empresa decide excluir: PENDIENTE (pregunta G5 de [01-requisitos.md](01-requisitos.md)).

## Riesgos y cómo se cubren

| Riesgo | Cobertura |
|---|---|
| Un texto del CRM intenta dar órdenes a Claude | La skill lo trata como dato y nunca como confirmación; y cada escritura pide aprobación al usuario (*Needs approval*). En Salesforce, además, no hay herramientas para borrar ni para editar otros campos |
| Claude aplica un cambio que el usuario no quería | Doble confirmación: la tabla con el cambio exacto en el chat y la aprobación de cada herramienta en Claude |
| Una acción falla a medias | Cada solicitud se resuelve por separado y el resultado dice cuál falló y por qué; la skill informa fila por fila |
| Claude afirma algo que no está en el CRM | La skill exige citar el Id de cada registro; las pruebas de aceptación lo comprueban |
| Un usuario ve datos de otro equipo | Cada llamada usa los permisos del usuario conectado |
| En monday.com, el token puede escribir más de lo que el plugin necesita | App propia con solo `boards:write` y `updates:write` como escritura, herramientas sobrantes en *Never*, conector genérico desactivado |
