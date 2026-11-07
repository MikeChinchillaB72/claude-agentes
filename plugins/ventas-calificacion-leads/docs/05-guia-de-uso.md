# Guía de uso: Calificación de leads

> Plugin `ventas-calificacion-leads` 0.1.0. Actualizado: 2026-11-07.

**Para:** responsables de leads, SDR y vendedores que revisan los leads nuevos.

## Qué hace

Puntúa un lead de 0 a 100 con la rúbrica de la empresa, justifica la puntuación, busca duplicados y propone si conviene convertirlo y a quién asignarlo. La decisión y la conversión las hace el vendedor o el responsable de leads.

## Antes de la primera vez

1. Tener el plugin instalado (**Customize > Plugins**).
2. Conectar tu cuenta en la pestaña **Connectors** del plugin: `salesforce` o `monday`, según
   lo que use tu empresa. Solo verás lo que ya ves en el CRM.

## Cómo pedirlo

Habla con normalidad. Claude usa el plugin cuando la petición encaja. Ejemplos:

- «Califica los leads que entraron esta semana.»
- «¿El lead de María en Acme ya existe como contacto?»
- «Puntúa este lead y dime si lo convierto.»

Si quieres asegurarte de que use el plugin, nómbralo: «usa calificar-lead para…». En Claude Code
y Cowork también se puede escribir `/ventas-calificacion-leads:calificar-lead`.

## Qué recibes

Por cada lead: puntuación total, una tabla con cada criterio (dato, fuente, puntos), duplicados encontrados (con su Id) y la propuesta (convertir, unir, descartar o pedir más información). Si algún criterio está PENDIENTE, dilo y no inventes su valor.

## Buenas prácticas

- **Acota la petición** (un periodo, un cliente, una cola): la respuesta es más rápida y precisa.
- **Revisa antes de aplicar.** Todo lo que propone lo aplicas tú en el CRM.
- **Comprueba los Id** que cita si algo te sorprende: abre el registro en el CRM.
- Si dice que un criterio está **PENDIENTE**, avisa al responsable del plugin.

## Lo que no hace

- No escribe en el CRM ni envía mensajes.
- No trabaja solo: responde cuando le preguntas.
- No ve lo que tu usuario no puede ver.
