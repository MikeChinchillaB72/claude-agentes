# Guía de uso: Respuestas con la base de conocimiento

> Plugin `servicio-respuestas-conocimiento` 0.1.0. Actualizado: 2026-11-07.

**Para:** agentes de soporte que responden casos.

## Qué hace

Busca en la base de conocimiento los artículos que responden a la pregunta de un caso y redacta la respuesta citándolos. Si ningún artículo la cubre, lo dice y no inventa la respuesta.

## Antes de la primera vez

1. Tener el plugin instalado (**Customize > Plugins**).
2. Conectar tu cuenta en la pestaña **Connectors** del plugin: `salesforce` o `monday`, según
   lo que use tu empresa. Solo verás lo que ya ves en el CRM.

## Cómo pedirlo

Habla con normalidad. Claude usa el plugin cuando la petición encaja. Ejemplos:

- «¿Qué le respondo al caso 00012345?»
- «¿Tenemos un artículo sobre cómo restablecer la contraseña?»
- «Redacta la respuesta para un cliente que no puede descargar su factura.»

Si quieres asegurarte de que use el plugin, nómbralo: «usa responder-con-conocimiento para…». En Claude Code
y Cowork también se puede escribir `/servicio-respuestas-conocimiento:responder-con-conocimiento`.

## Qué recibes

La respuesta propuesta al cliente, lista para copiar, y debajo la lista de artículos usados (título, número, enlace o Id). Si no hay artículo que la cubra, una frase que lo diga y el tema del artículo que falta.

## Buenas prácticas

- **Acota la petición** (un periodo, un cliente, una cola): la respuesta es más rápida y precisa.
- **Revisa antes de aplicar.** Todo lo que propone lo aplicas tú en el CRM.
- **Comprueba los Id** que cita si algo te sorprende: abre el registro en el CRM.
- Si dice que un criterio está **PENDIENTE**, avisa al responsable del plugin.

## Lo que no hace

- No escribe en el CRM ni envía mensajes.
- No trabaja solo: responde cuando le preguntas.
- No ve lo que tu usuario no puede ver.
