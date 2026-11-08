# Guía de uso: Seguimiento de oportunidades

> Plugin `ventas-seguimiento` 0.2.0. Actualizado: 2026-11-07.

**Para:** vendedores y ejecutivos de cuenta que gestionan oportunidades abiertas.

## Qué hace

Encuentra las oportunidades abiertas que llevan días sin actividad, lee el historial reciente de cada una y redacta un correo de seguimiento y un próximo paso. Si tú lo confirmas, actualiza el próximo paso, crea la tarea de seguimiento o mueve la fecha de cierre vencida. El correo lo revisas y lo envías tú.

## Antes de la primera vez

1. Tener el plugin instalado (**Customize > Plugins**).
2. Conectar tu cuenta en la pestaña **Connectors** del plugin: `salesforce` o `monday`, según
   lo que use tu empresa. Solo verás lo que ya ves en el CRM.

## Cómo pedirlo

Habla con normalidad. Claude usa el plugin cuando la petición encaja. Ejemplos:

- «¿Qué oportunidades mías llevan más de una semana sin actividad?»
- «Prepárame los seguimientos de hoy.»
- «Redacta el seguimiento para la oportunidad de Acme y propón el próximo paso.»
- «Aplica los próximos pasos de la 1 y la 3, y crea la tarea de Globex para el viernes.»

Si quieres asegurarte de que use el plugin, nómbralo: «usa seguimiento-oportunidades para…». En Claude Code
y Cowork también se puede escribir `/ventas-seguimiento:seguimiento-oportunidades`.

## Qué recibes

Una tabla resumen (oportunidad, cuenta, monto, etapa, días sin actividad, Id) y debajo, por cada una, el borrador del correo y el próximo paso propuesto. Después, una tabla de **acciones propuestas** con el valor actual y el nuevo de cada una.

## Aplicar las acciones

1. Revisa la tabla de acciones y responde «sí», o di cuáles aceptas y qué cambias.
2. Claude te muestra la tabla final si cambiaste algo, y luego ejecuta solo lo confirmado.
3. Claude te pide además aprobar cada herramienta (*Needs approval*). Es la segunda llave: si algo no
   cuadra, recházala.
4. Recibes el resultado de cada acción: hecha, con su Id, o fallida, con el motivo.

Las acciones posibles son tres: **actualizar el próximo paso**, **crear una tarea de seguimiento** y
**mover la fecha de cierre** a hoy o después. Tu empresa puede haber habilitado solo algunas.

## Buenas prácticas

- **Acota la petición** (un periodo, un cliente, una cola): la respuesta es más rápida y precisa.
- **Revisa antes de confirmar.** Nada se aplica sin tu sí, y lo que confirmas queda en el CRM con tu usuario.
- **Comprueba los Id** que cita si algo te sorprende: abre el registro en el CRM.
- Si dice que un criterio está **PENDIENTE**, avisa al responsable del plugin.

## Lo que no hace

- No envía correos ni mensajes.
- No cambia la etapa, el monto ni el responsable, no toca oportunidades cerradas y no borra nada.
- No trabaja solo: responde cuando le preguntas.
- No ve lo que tu usuario no puede ver.
