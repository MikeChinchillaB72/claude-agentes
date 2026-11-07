# Seguridad y datos: Respuestas con la base de conocimiento

> Plugin `servicio-respuestas-conocimiento` 0.1.0. Actualizado: 2026-11-07.

El modelo común está en [seguridad.md](../../../docs/cliente/seguridad.md). Aquí va lo propio de este plugin.

## Qué puede hacer

| Puede | No puede |
|---|---|
| Leer los registros que el usuario conectado puede ver | Crear, cambiar o borrar registros |
| Redactar textos y propuestas en el chat | Enviar correos o mensajes |
| | Ver lo que el usuario no puede ver en el CRM |

**Lo garantizan los permisos, no las instrucciones:** en Salesforce, el servidor
`sobject-reads` no tiene herramientas de escritura; en monday.com, la app OAuth propia no tiene
ningún *scope* `:write` ([instalacion-monday.md](../../../docs/cliente/instalacion-monday.md#elegir-cómo-conectar)).

## Datos que lee

| Salesforce | Campos |
|---|---|
| `Knowledge__kav (Salesforce Knowledge)` | Id, Title, Summary, UrlName, ArticleNumber, PublishStatus, Language y el campo de contenido |
| `Case` | Id, CaseNumber, Subject, Description |

| monday.com | Datos |
|---|---|
| Tickets (monday service) | Asunto, descripción, actualizaciones |
| Base de conocimiento (tablero de artículos o docs de monday.com) | Título, contenido, estado de publicación |

Estos registros pasan a la conversación con Claude. Para que Claude no vea un campo, se le quita
la lectura en el Permission Set (Salesforce) o se deja la columna fuera de los tableros del usuario
(monday.com).

## Datos personales

Puede tratar nombres, correos, cargos e historial de interacciones de contactos y clientes.
Campos que la empresa decide excluir: PENDIENTE (pregunta G5 de [01-requisitos.md](01-requisitos.md)).

## Riesgos y cómo se cubren

| Riesgo | Cobertura |
|---|---|
| Un texto del CRM intenta dar órdenes a Claude | La skill lo trata como dato; y aunque lo obedeciera, no tiene herramientas para escribir |
| Claude afirma algo que no está en el CRM | La skill exige citar el Id de cada registro; las pruebas de aceptación lo comprueban |
| Un usuario ve datos de otro equipo | Cada llamada usa los permisos del usuario conectado |
| Se usa el conector alojado genérico de monday.com, que sí puede escribir | Se recomienda la app propia de solo lectura y desactivar el conector genérico |
