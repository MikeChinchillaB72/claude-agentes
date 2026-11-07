# Atención con contexto del cliente

Cuando un agente de soporte atiende a un cliente, reúne su cuenta, contactos, casos abiertos y recientes, resume la situación y propone una respuesta. Señala si conviene escalar a otra persona.

Funciona con **Salesforce Service Cloud** o con **monday service**: trae los dos conectores y la empresa
conecta el que usa. Esta versión (0.1.0) **solo lee** el CRM.

## Usarlo

Instala el plugin, conecta tu cuenta del CRM en la pestaña **Connectors** y pregunta en el chat,
por ejemplo:

- «¿Cómo está el cliente Acme? Tiene un caso abierto por facturación.»
- «Prepárame la respuesta al caso 00012345 con todo el contexto del cliente.»
- «¿Este cliente tiene otros casos por el mismo problema?»

En Claude Code se instala con:

```bash
/plugin install servicio-atencion-contexto --marketplace MikeChinchillaB72/claude-agentes
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
| `skills/atender-con-contexto/SKILL.md` | Instrucciones de la tarea |
| `skills/atender-con-contexto/references/criterios.md` | Criterios de negocio de la empresa: **se ajustan aquí** |
| `docs/` | Documentación para el cliente |
