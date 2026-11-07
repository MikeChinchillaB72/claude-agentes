# Levantamiento de requisitos: Calificación de leads

> Plugin `ventas-calificacion-leads` 0.1.1. Actualizado: 2026-11-07.
> **Estado: pendiente de la información del cliente.** Lo marcado `PENDIENTE` no se ha
> inventado: lo tiene que aportar la empresa (P1 en [pendientes](../../../docs/pendientes.md)).

## Objetivo

Puntúa un lead de 0 a 100 con la rúbrica de la empresa, justifica la puntuación, busca duplicados y propone si conviene convertirlo y a quién asignarlo. La decisión y la conversión las hace el vendedor o el responsable de leads.

- **Usuarios:** Responsables de leads, SDR y vendedores que revisan los leads nuevos.
- **Plataformas:** Salesforce Sales Cloud o monday CRM.
- **Origen:** documento «Agentes de IA con Claude: casos de uso», versión 2 (5 de noviembre de 2026), caso 2 (calificación automática de leads).

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
| R1 | ¿Cuál es la rúbrica de calificación: criterios, pesos y puntos? | Sin rúbrica, la puntuación no refleja a la empresa | PENDIENTE |
| R2 | ¿Cuáles son las industrias y el tamaño de empresa objetivo? | Se ponen en `industrias_objetivo` y `tamano_objetivo` | PENDIENTE |
| R3 | ¿Desde qué puntuación se convierte un lead? ¿Es 70? | El documento de casos de uso propone 70 | PENDIENTE |
| R4 | ¿Cómo se asignan los leads a los vendedores (territorio, industria, rotación)? | Se pone en `reglas_de_asignacion` | PENDIENTE |
| R5 | ¿Se permite investigar la empresa en la web? | Algunas empresas lo prohíben o lo limitan | PENDIENTE |
| R6 | monday CRM: ¿cómo se llaman los tableros de leads, cuentas y contactos y sus columnas? | Mapeo de columnas | PENDIENTE |

## Criterios de negocio

Viven en [`skills/calificar-lead/references/criterios.md`](../skills/calificar-lead/references/criterios.md).
Ahí se cambian, sin tocar las instrucciones. Valores iniciales, **sin confirmar**:

| Clave | Valor inicial | Qué significa |
|---|---|---|
| `rubrica` | tamaño de la empresa, industria y señales de compra, con el mismo peso | Qué se valora y cuánto pesa cada criterio (sin confirmar: el documento de casos de uso nombra los criterios pero no sus pesos) |
| `umbral_califica` | 70 | Puntuación desde la que se propone convertir el lead |
| `industrias_objetivo` | PENDIENTE | Industrias que suman puntos |
| `tamano_objetivo` | PENDIENTE | Rango de empleados o de facturación que suma puntos |
| `reglas_de_asignacion` | PENDIENTE | A qué vendedor se propone asignar según territorio, industria o tamaño |
| `investigar_en_la_web` | sí, si la búsqueda web está disponible | Si se completa la información de la empresa con búsqueda web |

## Datos que usa

| Salesforce (Sales Cloud) | Campos | Para qué |
|---|---|---|
| `Lead` | Id, Name, Company, Title, Email, Industry, NumberOfEmployees, AnnualRevenue, LeadSource, Status, Website, Description, CreatedDate, IsConverted | Leer y puntuar el lead |
| `Account` | Id, Name, Industry, OwnerId | Buscar duplicados de la empresa |
| `Contact` | Id, Name, Email, AccountId | Buscar duplicados del contacto |
| `User` | Id, Name | Proponer el vendedor |

Son campos estándar. Si la empresa usa campos personalizados para lo mismo, hay que anotarlos aquí.

| monday CRM | Datos | Para qué |
|---|---|---|
| Leads | Nombre, empresa, email, cargo, industria, tamaño, origen, estado | Leer y puntuar el lead |
| Cuentas (*Accounts*) y Contactos (*Contacts*) | Nombre de la empresa, email | Buscar duplicados |

Los nombres reales del tablero y sus columnas: PENDIENTE (mapeo en `references/criterios.md`).

## Fuera del alcance de esta versión

- Escribir, crear o borrar registros, y enviar correos o mensajes.
- Ejecutarse sola (programada o por un evento): un plugin responde cuando alguien le pregunta.
- Uso por clientes finales.

## Aceptación

El plugin se acepta cuando pasa [06-pruebas-de-aceptacion.md](06-pruebas-de-aceptacion.md) en
un sandbox de Salesforce o una cuenta de prueba de monday.com (regla T5), con la firma del
responsable del plugin: PENDIENTE.
