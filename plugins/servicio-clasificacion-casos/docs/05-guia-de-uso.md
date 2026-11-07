# Guía de uso: Clasificación y priorización de casos

> Plugin `servicio-clasificacion-casos` 0.1.1. Actualizado: 2026-11-07.

**Para:** supervisores de soporte y agentes que reparten o atienden la cola de casos.

## Qué hace

Revisa los casos nuevos o sin clasificar y propone para cada uno su categoría, su prioridad y un resumen de una línea, con el motivo. El supervisor o el agente revisa la propuesta y la aplica en el CRM.

## Antes de la primera vez

1. Tener el plugin instalado (**Customize > Plugins**).
2. Conectar tu cuenta en la pestaña **Connectors** del plugin: `salesforce` o `monday`, según
   lo que use tu empresa. Solo verás lo que ya ves en el CRM.

## Cómo pedirlo

Habla con normalidad. Claude usa el plugin cuando la petición encaja. Ejemplos:

- «Clasifica los casos nuevos de hoy.»
- «¿Qué casos de la cola debería atender primero?»
- «Propón categoría y prioridad para el caso 00012345.»

Si quieres asegurarte de que use el plugin, nómbralo: «usa clasificar-casos para…». En Claude Code
y Cowork también se puede escribir `/servicio-clasificacion-casos:clasificar-casos`.

## Qué recibes

Una tabla (número de caso, asunto, categoría propuesta, prioridad propuesta, motivo en una frase, Id), ordenada de mayor a menor prioridad propuesta, y debajo los casos que necesitan revisión humana. Termina recordando que el usuario debe aplicar los cambios en el CRM.

## Buenas prácticas

- **Acota la petición** (un periodo, un cliente, una cola): la respuesta es más rápida y precisa.
- **Revisa antes de aplicar.** Todo lo que propone lo aplicas tú en el CRM.
- **Comprueba los Id** que cita si algo te sorprende: abre el registro en el CRM.
- Si dice que un criterio está **PENDIENTE**, avisa al responsable del plugin.

## Lo que no hace

- No escribe en el CRM ni envía mensajes.
- No trabaja solo: responde cuando le preguntas.
- No ve lo que tu usuario no puede ver.
