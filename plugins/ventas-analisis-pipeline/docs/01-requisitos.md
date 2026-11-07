# Levantamiento de requisitos: Análisis del pipeline

> Plugin `ventas-analisis-pipeline` 0.1.1. Actualizado: 2026-11-07.
> **Estado: pendiente de la información del cliente.** Lo marcado `PENDIENTE` no se ha
> inventado: lo tiene que aportar la empresa (P1 en [pendientes](../../../docs/pendientes.md)).

## Objetivo

Responde preguntas sobre el pipeline en lenguaje natural («¿qué oportunidades de más de 10 000 están en riesgo este trimestre?») y entrega un resumen con la tabla de riesgo por cuenta y acciones sugeridas.

- **Usuarios:** Gerentes de ventas, dirección comercial y vendedores que revisan su propio pipeline.
- **Plataformas:** Salesforce Sales Cloud o monday CRM.
- **Origen:** documento «Agentes de IA con Claude: casos de uso», versión 2 (5 de noviembre de 2026), caso 3 (analista de pipeline bajo demanda).

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
| R1 | ¿Qué hace que una oportunidad esté en riesgo para la empresa? | El documento de casos de uso propone: sin actividad en más de 14 días o fecha de cierre vencida | PENDIENTE |
| R2 | ¿Desde qué monto importa una oportunidad? ¿En qué moneda? | El documento propone 10 000 | PENDIENTE |
| R3 | ¿Cuál es el año fiscal de la empresa? | Define «este trimestre» | PENDIENTE |
| R4 | ¿Los gerentes deben ver el pipeline de todo su equipo? | En Salesforce lo da la jerarquía de roles y la compartición; en monday.com, el acceso a los tableros | PENDIENTE |
| R5 | monday CRM: ¿cómo se llaman el tablero de negocios y sus columnas? | Mapeo de columnas | PENDIENTE |

## Criterios de negocio

Viven en [`skills/analizar-pipeline/references/criterios.md`](../skills/analizar-pipeline/references/criterios.md).
Ahí se cambian, sin tocar las instrucciones. Valores iniciales, **sin confirmar**:

| Clave | Valor inicial | Qué significa |
|---|---|---|
| `dias_sin_actividad_riesgo` | 14 | Días sin actividad para marcar una oportunidad en riesgo |
| `cierre_vencido_es_riesgo` | sí | Si una fecha de cierre ya pasada marca riesgo |
| `monto_relevante` | 10000 | Monto desde el que una oportunidad se considera relevante (en la moneda de la org) |
| `periodo_por_defecto` | trimestre fiscal actual | Periodo si el usuario no dice otro |
| `max_registros` | 2000 | Máximo de oportunidades que se traen para un análisis; si hay más, se pide acotar |

## Datos que usa

| Salesforce (Sales Cloud) | Campos | Para qué |
|---|---|---|
| `Opportunity` | Id, Name, AccountId, OwnerId, Amount, StageName, Probability, CloseDate, LastActivityDate, ForecastCategoryName, IsClosed | Pipeline y riesgo |
| `Account` | Id, Name | Agrupar por cuenta |
| `User` | Id, Name | Agrupar por responsable |
| `OpportunityHistory` | OpportunityId, StageName, Amount, CloseDate, CreatedDate | Cambios de etapa y monto |

Son campos estándar. Si la empresa usa campos personalizados para lo mismo, hay que anotarlos aquí.

| monday CRM | Datos | Para qué |
|---|---|---|
| Negocios (*Deals*) | Responsable, monto, etapa, probabilidad, fecha de cierre, fecha de última actividad, cuenta | Pipeline y riesgo |

Los nombres reales del tablero y sus columnas: PENDIENTE (mapeo en `references/criterios.md`).

## Fuera del alcance de esta versión

- Escribir, crear o borrar registros, y enviar correos o mensajes.
- Ejecutarse sola (programada o por un evento): un plugin responde cuando alguien le pregunta.
- Uso por clientes finales.

## Aceptación

El plugin se acepta cuando pasa [06-pruebas-de-aceptacion.md](06-pruebas-de-aceptacion.md) en
un sandbox de Salesforce o una cuenta de prueba de monday.com (regla T5), con la firma del
responsable del plugin: PENDIENTE.
