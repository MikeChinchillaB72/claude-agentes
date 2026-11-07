# Preguntas frecuentes, límites, costos y soporte: Seguimiento de oportunidades

> Plugin `ventas-seguimiento` 0.2.0. Actualizado: 2026-11-07.

## De este plugin

**¿Envía los correos?**
No. Redacta el borrador en el chat y el vendedor lo copia, lo revisa y lo envía desde su correo o desde el CRM.

**¿Actualiza el próximo paso en el CRM?**
Sí, desde la versión 0.2.0, si el vendedor lo confirma. También puede crear una tarea de seguimiento y mover una fecha de cierre vencida. Cada acción pide dos confirmaciones: el sí en el chat y la aprobación de la herramienta en Claude.

**¿Puede cambiar la etapa o el monto?**
No. Solo existen las tres acciones. En Salesforce el servidor `AgentesCRM` no tiene ninguna otra herramienta de escritura.

**¿Puede ejecutarse solo cada mañana?**
Un plugin responde cuando alguien le pregunta. El caso de uso original lo planteaba como tarea programada a las 7:00; eso necesita otra arquitectura (API directa o Managed Agents) o una tarea programada en Cowork, si la empresa la usa.

## Generales

**¿Necesito las dos plataformas?**
No. El plugin trae los dos conectores y se conecta solo el de la plataforma de la empresa.

**¿Cuánto cuesta?**
El uso de Claude va en el plan de cada usuario. Salesforce y monday.com pueden cobrar sus servidores MCP; ver [costos-y-soporte.md](../../../docs/cliente/costos-y-soporte.md).

**¿Puede escribir en el CRM?**
Solo las tres acciones de este plugin, siempre con confirmación y con los permisos del usuario. Ver [02-seguridad-y-datos.md](02-seguridad-y-datos.md).

**¿Dónde se cambian los criterios?**
En [`skills/seguimiento-oportunidades/references/criterios.md`](../skills/seguimiento-oportunidades/references/criterios.md). Al publicar el cambio en el repositorio, la organización recibe la nueva versión.

**¿Funciona en el móvil o en la web?**
Funciona donde funcionen los plugins y conectores de Claude: claude.ai, Cowork y Claude Code. En claude.ai las skills y los conectores funcionan; otras piezas de plugin solo cargan en Cowork y Claude Code, y este plugin no las usa.

**¿Y si se equivoca?**
Todo lo que propone lo revisa y aplica una persona. Si un error se repite, avisar al responsable con el ejemplo para ajustar los criterios o las instrucciones.

## Límites

- **Escritura acotada:** solo próximo paso, tarea de seguimiento y fecha de cierre, confirmados; no borra ni envía mensajes.
- **Bajo demanda:** responde cuando alguien le pregunta; no se ejecuta solo.
- **Los permisos del usuario mandan:** no ve más que lo que el usuario ve en el CRM.
- **Volumen:** cada petición trae un número acotado de registros (ver `references/criterios.md`).
  Para análisis masivos hace falta otra arquitectura (Agent SDK).
- **Sin probar en plataforma real** en la versión 0.2.0: el Apex aún no se ha desplegado en una org (P10 en [pendientes](../../../docs/pendientes.md)).

## Costos

Resumen en [costos-y-soporte.md](../../../docs/cliente/costos-y-soporte.md#costos). Este plugin no añade
servidores propios. En Salesforce usa un servidor MCP personalizado y clases Apex dentro de la org; si
Salesforce cobra esas llamadas, se confirma con su ejecutivo (P9).

## Soporte

Tabla de a quién acudir en [costos-y-soporte.md](../../../docs/cliente/costos-y-soporte.md#soporte).
Responsable de este plugin en la empresa: PENDIENTE.
