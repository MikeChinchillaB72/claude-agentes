# Levantamiento de requisitos: Seguimiento de oportunidades

> Plugin `ventas-seguimiento` 0.2.0. Actualizado: 2026-11-07.
> **Estado: pendiente de la información del cliente.** Lo marcado `PENDIENTE` no se ha
> inventado: lo tiene que aportar la empresa (P1 en [pendientes](../../../docs/pendientes.md)).

## Objetivo

Encuentra las oportunidades abiertas que llevan días sin actividad, lee el historial reciente de cada una y redacta un correo de seguimiento y un próximo paso. Con la confirmación del vendedor, actualiza el próximo paso, crea una tarea de seguimiento o mueve la fecha de cierre vencida. El correo lo envía el vendedor él mismo.

- **Usuarios:** Vendedores y ejecutivos de cuenta que gestionan oportunidades abiertas.
- **Plataformas:** Salesforce Sales Cloud o monday CRM.
- **Origen:** documento «Agentes de IA con Claude: casos de uso», versión 2 (5 de noviembre de 2026), caso 1 (asistente de seguimiento de ventas).

## Lo que ya está decidido

| Decisión | Motivo |
|---|---|
| Se entrega como plugin de Claude | Lo usan personas que ya trabajan con Claude, sin servidor propio |
| Un mismo plugin sirve para Salesforce y para monday.com | Decisión de Miguel del 2026-11-06; la empresa conecta solo el conector de su plataforma |
| Escribe en el CRM solo tres acciones, siempre confirmadas | Decisión de Miguel del 2026-11-07: actualizar el próximo paso, crear una tarea de seguimiento y mover la fecha de cierre. Nada se borra ni se envía al cliente |
| En Salesforce, las acciones son Apex en un servidor MCP personalizado | Decisión de Miguel del 2026-11-07: Claude solo puede ejecutar esas acciones, con sus validaciones, en vez de editar cualquier campo ([salesforce/](../../../salesforce/README.md)) |
| La confirmación tiene dos llaves | La skill pide el sí del vendedor, y el Owner de Claude pone las herramientas de escritura en *Needs approval* |
| Usa los servidores MCP alojados por Salesforce y monday.com | Sin infraestructura que mantener; respetan los permisos de cada usuario |

## Lo que debe aportar la empresa

### Comunes a todos los plugins

| # | Pregunta | Para qué | Respuesta |
|---|---|---|---|
| G1 | ¿Qué plataforma usa la empresa: Salesforce o monday.com? ¿Qué edición o plan? | Define qué conector se añade y qué permisos hay que dar | PENDIENTE |
| G2 | ¿Quiénes forman el grupo piloto y cuántos usuarios tendrá después? | Define a quién se le asigna el Permission Set o la app, y la disponibilidad en Claude | PENDIENTE |
| G3 | ¿Quién es el responsable del plugin en la empresa? | Aprueba los criterios, firma las pruebas de aceptación y atiende incidencias | PENDIENTE |
| G4 | ¿En qué idioma deben salir las respuestas? | Las skills responden en el idioma del usuario si no se indica otro | PENDIENTE |
| G5 | ¿Qué campos no se deben usar o mostrar (datos personales o sensibles)? | Se quitan del Permission Set o de los tableros, y se anotan en 02-seguridad-y-datos.md | PENDIENTE |
| G6 | ¿En qué países están los clientes cuyos datos se tratan? | Define la ley de protección de datos que aplica | PENDIENTE |
| G7 | ¿Qué plan de Claude tiene la empresa (Team, Enterprise u otro)? | Define si se reparte a toda la organización o usuario por usuario | PENDIENTE |

### De este plugin

| # | Pregunta | Para qué | Respuesta |
|---|---|---|---|
| R1 | ¿Cuántos días sin actividad hacen que una oportunidad necesite seguimiento? ¿Cambia por etapa? | El documento de casos de uso propone 7 días; falta confirmarlo | PENDIENTE |
| R2 | ¿Qué cuenta como actividad: tareas, eventos, correos registrados, llamadas? | Define qué se lee y qué fecha se usa | PENDIENTE |
| R3 | ¿Hay plantillas, tono o firma obligatoria para los correos? | Se ponen en `tono_del_correo` | PENDIENTE |
| R4 | ¿Qué etapas se excluyen (por ejemplo, las que esperan al cliente)? | Evita seguimientos innecesarios | PENDIENTE |
| R5 | monday CRM: ¿cómo se llaman el tablero de negocios y sus columnas de responsable, monto, etapa, cierre, última actividad y próximo paso? ¿Usan un tablero de tareas? | Mapeo de columnas | PENDIENTE |
| R6 | ¿Qué acciones se habilitan: actualizar el próximo paso, crear tareas, mover la fecha de cierre? | `acciones_habilitadas` y las herramientas del servidor | PENDIENTE |
| R7 | ¿Con cuántos días de plazo se crea una tarea de seguimiento? | `vencimiento_tarea` (se propone 2 días) | PENDIENTE |

## Criterios de negocio

Viven en [`skills/seguimiento-oportunidades/references/criterios.md`](../skills/seguimiento-oportunidades/references/criterios.md).
Ahí se cambian, sin tocar las instrucciones. Valores iniciales, **sin confirmar**:

| Clave | Valor inicial | Qué significa |
|---|---|---|
| `dias_sin_actividad` | 7 | Días sin actividad para considerar que una oportunidad necesita seguimiento |
| `max_oportunidades` | 10 | Cuántas oportunidades revisar por petición, empezando por las de mayor monto |
| `interacciones_a_leer` | 5 | Cuántas actividades recientes leer por oportunidad (el documento de casos de uso dice de 3 a 5) |
| `monto_minimo` | sin mínimo | Monto a partir del cual se incluye una oportunidad |
| `tono_del_correo` | profesional y breve | Tono y firma de los correos que redacta |
| `acciones_habilitadas` | `actualizar_proximo_paso`, `crear_tarea`, `mover_fecha_cierre` | Acciones que puede ejecutar con confirmación |
| `vencimiento_tarea` | 2 días después de hoy | Vencimiento que se propone para una tarea |
| `max_acciones_por_confirmacion` | 10 | Cuántas acciones se confirman de una vez |

## Datos que usa

| Salesforce (Sales Cloud) | Campos | Para qué |
|---|---|---|
| `Opportunity` | Id, Name, AccountId, Amount, StageName, CloseDate, LastActivityDate, NextStep, OwnerId, IsClosed | Buscar las oportunidades sin actividad |
| `Account` | Id, Name | Nombre de la cuenta |
| `Contact` | Id, Name, Email, Title | Destinatario del correo |
| `OpportunityContactRole` | OpportunityId, ContactId, IsPrimary, Role | Contacto principal de la oportunidad |
| `Task y Event` | WhatId, Subject, ActivityDate, Description | Historial reciente |
| `User` | Id, Name | Usuario conectado |

Son campos estándar. Si la empresa usa campos personalizados para lo mismo, hay que anotarlos aquí.

| Salesforce: lo que escribe | Campos | Acción |
|---|---|---|
| `Opportunity` (solo abiertas) | NextStep | `actualizar_proximo_paso` |
| `Opportunity` (solo abiertas) | CloseDate (hoy o después) | `mover_fecha_cierre` |
| `Task` (nueva) | WhatId, WhoId, Subject, ActivityDate, Description, OwnerId (el usuario conectado) | `crear_tarea` |

| monday CRM | Datos | Para qué |
|---|---|---|
| Negocios (*Deals*) | Responsable, monto, etapa, fecha de cierre, fecha de última actividad, contacto vinculado | Buscar los negocios sin actividad |
| Contactos (*Contacts*) | Nombre, email, cargo, cuenta | Destinatario del correo |

Los nombres reales del tablero y sus columnas: PENDIENTE (mapeo en `references/criterios.md`).

## Fuera del alcance de esta versión

- Cualquier escritura fuera de las tres acciones: cambiar la etapa, el monto o el responsable, y borrar registros.
- Enviar correos o mensajes al cliente (fase 2, decisión de Miguel del 2026-11-07).
- Ejecutarse sola (programada o por un evento): un plugin responde cuando alguien le pregunta.
- Uso por clientes finales.

## Aceptación

El plugin se acepta cuando pasa [06-pruebas-de-aceptacion.md](06-pruebas-de-aceptacion.md) en
un sandbox de Salesforce o una cuenta de prueba de monday.com (regla T5), con la firma del
responsable del plugin: PENDIENTE.
