# Levantamiento de requisitos: Seguimiento de oportunidades

> Plugin `ventas-seguimiento` 0.1.0. Actualizado: 2026-11-07.
> **Estado: pendiente de la información del cliente.** Lo marcado `PENDIENTE` no se ha
> inventado: lo tiene que aportar la empresa (P1 en [pendientes](../../../docs/pendientes.md)).

## Objetivo

Encuentra las oportunidades abiertas que llevan días sin actividad, lee el historial reciente de cada una y redacta un correo de seguimiento y un próximo paso. El vendedor revisa el borrador y lo envía él mismo.

- **Usuarios:** Vendedores y ejecutivos de cuenta que gestionan oportunidades abiertas.
- **Plataformas:** Salesforce Sales Cloud o monday CRM.
- **Origen:** documento «Agentes de IA con Claude: casos de uso», versión 2 (5 de noviembre de 2026), caso 1 (asistente de seguimiento de ventas).

## Lo que ya está decidido

| Decisión | Motivo |
|---|---|
| Se entrega como plugin de Claude | Lo usan personas que ya trabajan con Claude, sin servidor propio |
| Un mismo plugin sirve para Salesforce y para monday.com | Decisión de Miguel del 2026-11-06; la empresa conecta solo el conector de su plataforma |
| Solo lectura en esta versión | Mínimo privilegio: proponer y que la persona aplique. Escribir en el CRM es una decisión pendiente |
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
| R5 | monday CRM: ¿cómo se llaman el tablero de negocios y sus columnas de responsable, monto, etapa, cierre y última actividad? | Mapeo de columnas | PENDIENTE |

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

| monday CRM | Datos | Para qué |
|---|---|---|
| Negocios (*Deals*) | Responsable, monto, etapa, fecha de cierre, fecha de última actividad, contacto vinculado | Buscar los negocios sin actividad |
| Contactos (*Contacts*) | Nombre, email, cargo, cuenta | Destinatario del correo |

Los nombres reales del tablero y sus columnas: PENDIENTE (mapeo en `references/criterios.md`).

## Fuera del alcance de esta versión

- Escribir, crear o borrar registros, y enviar correos o mensajes.
- Ejecutarse sola (programada o por un evento): un plugin responde cuando alguien le pregunta.
- Uso por clientes finales.

## Aceptación

El plugin se acepta cuando pasa [06-pruebas-de-aceptacion.md](06-pruebas-de-aceptacion.md) en
un sandbox de Salesforce o una cuenta de prueba de monday.com (regla T5), con la firma del
responsable del plugin: PENDIENTE.
