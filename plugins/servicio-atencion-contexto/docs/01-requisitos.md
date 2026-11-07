# Levantamiento de requisitos: Atención con contexto del cliente

> Plugin `servicio-atencion-contexto` 0.1.1. Actualizado: 2026-11-07.
> **Estado: pendiente de la información del cliente.** Lo marcado `PENDIENTE` no se ha
> inventado: lo tiene que aportar la empresa (P1 en [pendientes](../../../docs/pendientes.md)).

## Objetivo

Cuando un agente de soporte atiende a un cliente, reúne su cuenta, contactos, casos abiertos y recientes, resume la situación y propone una respuesta. Señala si conviene escalar a otra persona.

- **Usuarios:** Agentes y supervisores de soporte. No es un chat para los clientes finales.
- **Plataformas:** Salesforce Service Cloud o monday service.
- **Origen:** documento «Agentes de IA con Claude: casos de uso», versión 2 (5 de noviembre de 2026), caso 5 (asistente de atención al cliente con contexto de cuenta), adaptado a agentes internos.

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
| R1 | ¿Qué campos dicen el plan, el estado o el nivel de servicio de un cliente? | Se ponen en `campos_de_cuenta` | PENDIENTE |
| R2 | ¿Cuándo se escala un caso y a quién? | Se ponen en `senales_de_escalado` y `a_quien_escalar` | PENDIENTE |
| R3 | ¿Hay acuerdos de nivel de servicio (SLA) que deban mostrarse? | Se añadirían a los campos que se leen | PENDIENTE |
| R4 | ¿Qué datos del cliente no deben aparecer en la respuesta propuesta? | Se anotan en 02-seguridad-y-datos.md | PENDIENTE |
| R5 | monday service: ¿cómo se llaman los tableros de tickets y clientes y sus columnas? | Mapeo de columnas | PENDIENTE |

## Criterios de negocio

Viven en [`skills/atender-con-contexto/references/criterios.md`](../skills/atender-con-contexto/references/criterios.md).
Ahí se cambian, sin tocar las instrucciones. Valores iniciales, **sin confirmar**:

| Clave | Valor inicial | Qué significa |
|---|---|---|
| `casos_recientes` | 5 | Cuántos casos cerrados recientes leer además de los abiertos |
| `campos_de_cuenta` | PENDIENTE | Qué campos de la cuenta describen su plan, estado o nivel de servicio (suelen ser personalizados) |
| `senales_de_escalado` | frustración del cliente, tema que el agente no puede resolver, o más de un caso abierto por el mismo problema | Cuándo proponer escalar (las dos primeras vienen del documento de casos de uso) |
| `a_quien_escalar` | PENDIENTE | Cola, equipo o persona a la que se propone escalar |

## Datos que usa

| Salesforce (Service Cloud) | Campos | Para qué |
|---|---|---|
| `Account` | Id, Name y los campos de plan o estado que la empresa defina | Contexto de la cuenta |
| `Contact` | Id, Name, Title, Email, AccountId | Contactos del cliente |
| `Case` | Id, CaseNumber, Subject, Description, Status, Priority, Origin, CreatedDate, ClosedDate, AccountId, ContactId, IsEscalated | Casos abiertos y recientes |
| `CaseComment` | ParentId, CommentBody, CreatedDate, IsPublished | Historial del caso |

Son campos estándar. Si la empresa usa campos personalizados para lo mismo, hay que anotarlos aquí.

| monday service | Datos | Para qué |
|---|---|---|
| Tickets (monday service) | Cliente, asunto, estado, prioridad, fecha de creación y de cierre, responsable | Casos abiertos y recientes |
| Clientes o contactos | Nombre, email, empresa, plan | Contexto del cliente |

Los nombres reales del tablero y sus columnas: PENDIENTE (mapeo en `references/criterios.md`).

## Fuera del alcance de esta versión

- Escribir, crear o borrar registros, y enviar correos o mensajes.
- Ejecutarse sola (programada o por un evento): un plugin responde cuando alguien le pregunta.
- Uso por clientes finales.

## Aceptación

El plugin se acepta cuando pasa [06-pruebas-de-aceptacion.md](06-pruebas-de-aceptacion.md) en
un sandbox de Salesforce o una cuenta de prueba de monday.com (regla T5), con la firma del
responsable del plugin: PENDIENTE.
