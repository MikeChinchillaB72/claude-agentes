# Seguimiento de oportunidades

Encuentra las oportunidades abiertas que llevan días sin actividad, lee el historial reciente de cada una y redacta un correo de seguimiento y un próximo paso. El vendedor revisa el borrador y lo envía él mismo.

Funciona con **Salesforce Sales Cloud** o con **monday CRM**: trae los dos conectores y la empresa
conecta el que usa. Esta versión (0.1.0) **solo lee** el CRM.

## Usarlo

Instala el plugin, conecta tu cuenta del CRM en la pestaña **Connectors** y pregunta en el chat,
por ejemplo:

- «¿Qué oportunidades mías llevan más de una semana sin actividad?»
- «Prepárame los seguimientos de hoy.»
- «Redacta el seguimiento para la oportunidad de Acme y propón el próximo paso.»

En Claude Code se instala con:

```bash
/plugin install ventas-seguimiento --marketplace MikeChinchillaB72/claude-agentes
```

En claude.ai y Cowork, lo añade el Owner de la organización o cada usuario: ver
[instalar-en-claude.md](../../docs/cliente/instalar-en-claude.md).

## Datos

El plugin lee del CRM, con la cuenta de cada usuario, los registros que necesita la tarea
(ver [docs/02-seguridad-y-datos.md](docs/02-seguridad-y-datos.md)). Esos registros pasan a la
conversación con Claude. El plugin no guarda nada ni tiene servidor propio, y no escribe en el CRM.

## Documentos

1. [Levantamiento de requisitos](docs/01-requisitos.md)
2. [Seguridad y datos](docs/02-seguridad-y-datos.md)
3. [Instalación en Salesforce](docs/03-instalacion-salesforce.md)
4. [Instalación en monday.com](docs/04-instalacion-monday.md)
5. [Guía de uso](docs/05-guia-de-uso.md)
6. [Pruebas de aceptación](docs/06-pruebas-de-aceptacion.md)
7. [Preguntas frecuentes, límites, costos y soporte](docs/07-preguntas-frecuentes.md)

Guía general para el cliente: [docs/cliente](../../docs/cliente/README.md).

## Contenido

| Ruta | Qué es |
|---|---|
| `.claude-plugin/plugin.json` | Manifiesto: nombre, versión y descripción |
| `.mcp.json` | Conectores `salesforce` (servidor SObject Reads) y `monday` |
| `skills/seguimiento-oportunidades/SKILL.md` | Instrucciones de la tarea |
| `skills/seguimiento-oportunidades/references/criterios.md` | Criterios de negocio de la empresa: **se ajustan aquí** |
| `docs/` | Documentación para el cliente |
