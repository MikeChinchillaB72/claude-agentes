# Levantamiento de requisitos: Clasificación y priorización de casos

> Plugin `servicio-clasificacion-casos` 0.1.1. Actualizado: 2026-11-07.
> **Estado: pendiente de la información del cliente.** Lo marcado `PENDIENTE` no se ha
> inventado: lo tiene que aportar la empresa (P1 en [pendientes](../../../docs/pendientes.md)).

## Objetivo

Revisa los casos nuevos o sin clasificar y propone para cada uno su categoría, su prioridad y un resumen de una línea, con el motivo. El supervisor o el agente revisa la propuesta y la aplica en el CRM.

- **Usuarios:** Supervisores de soporte y agentes que reparten o atienden la cola de casos.
- **Plataformas:** Salesforce Service Cloud o monday service.
- **Origen:** documento «Agentes de IA con Claude: casos de uso», versión 2 (5 de noviembre de 2026), caso 5 (crear_caso con categoría, prioridad y resumen).

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
| R1 | ¿Cuáles son las categorías de caso y qué significa cada una? | Si la lista de selección no basta para distinguirlas, se añade su definición en `categorias` | PENDIENTE |
| R2 | ¿Qué hace que un caso sea de prioridad alta, media o baja? | Se pone en `reglas_de_prioridad` | PENDIENTE |
| R3 | ¿Hay SLA por prioridad o por tipo de cliente? | Puede cambiar el orden de la cola | PENDIENTE |
| R4 | ¿Qué es un caso «sin clasificar» en la empresa? | Se pone en `que_es_sin_clasificar` | PENDIENTE |
| R5 | monday service: ¿cómo se llaman el tablero de tickets y sus columnas de categoría y prioridad? | Mapeo de columnas | PENDIENTE |

## Criterios de negocio

Viven en [`skills/clasificar-casos/references/criterios.md`](../skills/clasificar-casos/references/criterios.md).
Ahí se cambian, sin tocar las instrucciones. Valores iniciales, **sin confirmar**:

| Clave | Valor inicial | Qué significa |
|---|---|---|
| `categorias` | los valores de la lista de selección del tipo de caso en Salesforce, o de la columna de categoría en monday service | Categorías posibles; no se inventan otras |
| `prioridades` | los valores de la lista de selección de prioridad, o de la columna de prioridad | Prioridades posibles |
| `reglas_de_prioridad` | PENDIENTE | Qué hace que un caso sea de prioridad alta (por ejemplo, servicio caído, cliente de cierto plan, plazo de SLA) |
| `que_es_sin_clasificar` | estado nuevo y sin tipo, o sin prioridad | Qué casos entran en la revisión |
| `max_casos` | 20 | Cuántos casos revisar por petición, empezando por los más antiguos |

## Datos que usa

| Salesforce (Service Cloud) | Campos | Para qué |
|---|---|---|
| `Case` | Id, CaseNumber, Subject, Description, Origin, Type, Reason, Priority, Status, CreatedDate, IsClosed, AccountId | Leer y clasificar los casos |
| `Account` | Id, Name y el campo de plan, si existe | Reglas de prioridad que dependen del cliente |

Son campos estándar. Si la empresa usa campos personalizados para lo mismo, hay que anotarlos aquí.

| monday service | Datos | Para qué |
|---|---|---|
| Tickets (monday service) | Asunto, descripción, categoría, prioridad, estado, fecha de creación, cliente | Leer y clasificar los tickets |

Los nombres reales del tablero y sus columnas: PENDIENTE (mapeo en `references/criterios.md`).

## Fuera del alcance de esta versión

- Escribir, crear o borrar registros, y enviar correos o mensajes.
- Ejecutarse sola (programada o por un evento): un plugin responde cuando alguien le pregunta.
- Uso por clientes finales.

## Aceptación

El plugin se acepta cuando pasa [06-pruebas-de-aceptacion.md](06-pruebas-de-aceptacion.md) en
un sandbox de Salesforce o una cuenta de prueba de monday.com (regla T5), con la firma del
responsable del plugin: PENDIENTE.
