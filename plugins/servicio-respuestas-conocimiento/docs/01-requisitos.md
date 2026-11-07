# Levantamiento de requisitos: Respuestas con la base de conocimiento

> Plugin `servicio-respuestas-conocimiento` 0.1.1. Actualizado: 2026-11-07.
> **Estado: pendiente de la información del cliente.** Lo marcado `PENDIENTE` no se ha
> inventado: lo tiene que aportar la empresa (P1 en [pendientes](../../../docs/pendientes.md)).

## Objetivo

Busca en la base de conocimiento los artículos que responden a la pregunta de un caso y redacta la respuesta citándolos. Si ningún artículo la cubre, lo dice y no inventa la respuesta.

- **Usuarios:** Agentes de soporte que responden casos.
- **Plataformas:** Salesforce Service Cloud o monday service.
- **Origen:** documento «Agentes de IA con Claude: casos de uso», versión 2 (5 de noviembre de 2026), caso 5 (responder con la base de conocimiento).

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
| R1 | Salesforce: ¿está activado Lightning Knowledge y qué campo guarda el cuerpo del artículo? | Se pone en `campo_de_contenido` | PENDIENTE |
| R2 | monday service: ¿dónde está la base de conocimiento (tablero, docs u otra herramienta)? | **Sin comprobar** si la base de conocimiento propia de monday service se puede leer por el servidor MCP | PENDIENTE |
| R3 | ¿En qué idiomas están los artículos? | Se pone en `idioma_de_articulos` | PENDIENTE |
| R4 | ¿Hay temas que nunca se responden sin un humano (legales, reembolsos)? | Se añaden como regla de la skill | PENDIENTE |
| R5 | ¿Hay plantilla, saludo o firma para las respuestas? | Se pone en `tono_de_respuesta` | PENDIENTE |

## Criterios de negocio

Viven en [`skills/responder-con-conocimiento/references/criterios.md`](../skills/responder-con-conocimiento/references/criterios.md).
Ahí se cambian, sin tocar las instrucciones. Valores iniciales, **sin confirmar**:

| Clave | Valor inicial | Qué significa |
|---|---|---|
| `idioma_de_articulos` | es | Idioma de los artículos que se buscan (código de idioma de Salesforce Knowledge) |
| `campo_de_contenido` | PENDIENTE | Campo que guarda el cuerpo del artículo en Salesforce (es personalizado en cada org) o dónde está la base de conocimiento en monday.com |
| `max_articulos` | 3 | Cuántos artículos citar como máximo |
| `solo_publicados` | sí | Usar solo artículos publicados |
| `tono_de_respuesta` | cordial y claro | Tono de la respuesta al cliente |

## Datos que usa

| Salesforce (Service Cloud) | Campos | Para qué |
|---|---|---|
| `Knowledge__kav (Salesforce Knowledge)` | Id, Title, Summary, UrlName, ArticleNumber, PublishStatus, Language y el campo de contenido | Buscar y leer artículos |
| `Case` | Id, CaseNumber, Subject, Description | Pregunta del caso |

Son campos estándar. Si la empresa usa campos personalizados para lo mismo, hay que anotarlos aquí.

| monday service | Datos | Para qué |
|---|---|---|
| Tickets (monday service) | Asunto, descripción, actualizaciones | Pregunta del ticket |
| Base de conocimiento (tablero de artículos o docs de monday.com) | Título, contenido, estado de publicación | Buscar y leer artículos |

Los nombres reales del tablero y sus columnas: PENDIENTE (mapeo en `references/criterios.md`).

## Fuera del alcance de esta versión

- Escribir, crear o borrar registros, y enviar correos o mensajes.
- Ejecutarse sola (programada o por un evento): un plugin responde cuando alguien le pregunta.
- Uso por clientes finales.

## Aceptación

El plugin se acepta cuando pasa [06-pruebas-de-aceptacion.md](06-pruebas-de-aceptacion.md) en
un sandbox de Salesforce o una cuenta de prueba de monday.com (regla T5), con la firma del
responsable del plugin: PENDIENTE.
