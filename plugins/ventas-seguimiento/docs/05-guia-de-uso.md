# Guía de uso: Seguimiento de oportunidades

> Plugin `ventas-seguimiento` 0.1.0. Actualizado: 2026-11-07.

**Para:** vendedores y ejecutivos de cuenta que gestionan oportunidades abiertas.

## Qué hace

Encuentra las oportunidades abiertas que llevan días sin actividad, lee el historial reciente de cada una y redacta un correo de seguimiento y un próximo paso. El vendedor revisa el borrador y lo envía él mismo.

## Antes de la primera vez

1. Tener el plugin instalado (**Customize > Plugins**).
2. Conectar tu cuenta en la pestaña **Connectors** del plugin: `salesforce` o `monday`, según
   lo que use tu empresa. Solo verás lo que ya ves en el CRM.

## Cómo pedirlo

Habla con normalidad. Claude usa el plugin cuando la petición encaja. Ejemplos:

- «¿Qué oportunidades mías llevan más de una semana sin actividad?»
- «Prepárame los seguimientos de hoy.»
- «Redacta el seguimiento para la oportunidad de Acme y propón el próximo paso.»

Si quieres asegurarte de que use el plugin, nómbralo: «usa seguimiento-oportunidades para…». En Claude Code
y Cowork también se puede escribir `/ventas-seguimiento:seguimiento-oportunidades`.

## Qué recibes

Una tabla resumen (oportunidad, cuenta, monto, etapa, días sin actividad, Id) y debajo, por cada una, el borrador del correo y el próximo paso propuesto. Termina recordando que el usuario debe revisar y enviar el correo él mismo, y actualizar el próximo paso en el CRM si está de acuerdo.

## Buenas prácticas

- **Acota la petición** (un periodo, un cliente, una cola): la respuesta es más rápida y precisa.
- **Revisa antes de aplicar.** Todo lo que propone lo aplicas tú en el CRM.
- **Comprueba los Id** que cita si algo te sorprende: abre el registro en el CRM.
- Si dice que un criterio está **PENDIENTE**, avisa al responsable del plugin.

## Lo que no hace

- No escribe en el CRM ni envía mensajes.
- No trabaja solo: responde cuando le preguntas.
- No ve lo que tu usuario no puede ver.
