# Guía de uso: Análisis del pipeline

> Plugin `ventas-analisis-pipeline` 0.1.0. Actualizado: 2026-11-07.

**Para:** gerentes de ventas, dirección comercial y vendedores que revisan su propio pipeline.

## Qué hace

Responde preguntas sobre el pipeline en lenguaje natural («¿qué oportunidades de más de 10 000 están en riesgo este trimestre?») y entrega un resumen con la tabla de riesgo por cuenta y acciones sugeridas.

## Antes de la primera vez

1. Tener el plugin instalado (**Customize > Plugins**).
2. Conectar tu cuenta en la pestaña **Connectors** del plugin: `salesforce` o `monday`, según
   lo que use tu empresa. Solo verás lo que ya ves en el CRM.

## Cómo pedirlo

Habla con normalidad. Claude usa el plugin cuando la petición encaja. Ejemplos:

- «¿Qué oportunidades de más de 10 000 están en riesgo este trimestre y por qué?»
- «Dame el pipeline por etapa y por vendedor.»
- «¿Qué negocios llevan más de dos semanas sin moverse?»

Si quieres asegurarte de que use el plugin, nómbralo: «usa analizar-pipeline para…». En Claude Code
y Cowork también se puede escribir `/ventas-analisis-pipeline:analizar-pipeline`.

## Qué recibes

Primero la respuesta a la pregunta en dos o tres frases. Después la tabla de riesgo por cuenta (oportunidad, cuenta, responsable, monto, etapa, cierre, motivo del riesgo, acción sugerida, Id) y los totales que se pidieron. Si generas un gráfico, que muestre lo mismo que la tabla.

## Buenas prácticas

- **Acota la petición** (un periodo, un cliente, una cola): la respuesta es más rápida y precisa.
- **Revisa antes de aplicar.** Todo lo que propone lo aplicas tú en el CRM.
- **Comprueba los Id** que cita si algo te sorprende: abre el registro en el CRM.
- Si dice que un criterio está **PENDIENTE**, avisa al responsable del plugin.

## Lo que no hace

- No escribe en el CRM ni envía mensajes.
- No trabaja solo: responde cuando le preguntas.
- No ve lo que tu usuario no puede ver.
