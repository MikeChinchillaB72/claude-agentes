# Guía de uso: Atención con contexto del cliente

> Plugin `servicio-atencion-contexto` 0.1.0. Actualizado: 2026-11-07.

**Para:** agentes y supervisores de soporte. No es un chat para los clientes finales.

## Qué hace

Cuando un agente de soporte atiende a un cliente, reúne su cuenta, contactos, casos abiertos y recientes, resume la situación y propone una respuesta. Señala si conviene escalar a otra persona.

## Antes de la primera vez

1. Tener el plugin instalado (**Customize > Plugins**).
2. Conectar tu cuenta en la pestaña **Connectors** del plugin: `salesforce` o `monday`, según
   lo que use tu empresa. Solo verás lo que ya ves en el CRM.

## Cómo pedirlo

Habla con normalidad. Claude usa el plugin cuando la petición encaja. Ejemplos:

- «¿Cómo está el cliente Acme? Tiene un caso abierto por facturación.»
- «Prepárame la respuesta al caso 00012345 con todo el contexto del cliente.»
- «¿Este cliente tiene otros casos por el mismo problema?»

Si quieres asegurarte de que use el plugin, nómbralo: «usa atender-con-contexto para…». En Claude Code
y Cowork también se puede escribir `/servicio-atencion-contexto:atender-con-contexto`.

## Qué recibes

Un resumen del cliente en cinco líneas como máximo, la lista de casos (número, asunto, estado, prioridad, antigüedad), la respuesta propuesta y, si aplica, la recomendación de escalar con su motivo y el resumen para quien lo reciba.

## Buenas prácticas

- **Acota la petición** (un periodo, un cliente, una cola): la respuesta es más rápida y precisa.
- **Revisa antes de aplicar.** Todo lo que propone lo aplicas tú en el CRM.
- **Comprueba los Id** que cita si algo te sorprende: abre el registro en el CRM.
- Si dice que un criterio está **PENDIENTE**, avisa al responsable del plugin.

## Lo que no hace

- No escribe en el CRM ni envía mensajes.
- No trabaja solo: responde cuando le preguntas.
- No ve lo que tu usuario no puede ver.
