# Guía del cliente: plugins de ventas y servicio

> Para quien va a instalar y usar los plugins en su empresa. Actualizado: 2026-11-07.
> Versión de los plugins: 0.1.1 (primera versión, **sin probar todavía en una
> plataforma real**; ver [Estado](#estado-de-esta-versión)).

## Qué son

Seis plugins que añaden a Claude conocimientos y conexiones para trabajar con el CRM
de la empresa desde el chat. Cada plugin funciona con **Salesforce** o con **monday.com**:
trae los dos conectores y la empresa conecta el que usa.

| Área | Plugin | Qué hace | Salesforce | monday.com |
|---|---|---|---|---|
| Ventas | [ventas-seguimiento](../../plugins/ventas-seguimiento/README.md) | Encuentra oportunidades sin actividad reciente, redacta el seguimiento y, con confirmación, actualiza el próximo paso, crea la tarea o mueve la fecha de cierre | Sales Cloud | monday CRM |
| Ventas | [ventas-calificacion-leads](../../plugins/ventas-calificacion-leads/README.md) | Puntúa un lead con la rúbrica de la empresa y busca duplicados | Sales Cloud | monday CRM |
| Ventas | [ventas-analisis-pipeline](../../plugins/ventas-analisis-pipeline/README.md) | Responde preguntas sobre el pipeline y señala oportunidades en riesgo | Sales Cloud | monday CRM |
| Servicio | [servicio-atencion-contexto](../../plugins/servicio-atencion-contexto/README.md) | Reúne la cuenta, los contactos y los casos del cliente antes de responder | Service Cloud | monday service |
| Servicio | [servicio-clasificacion-casos](../../plugins/servicio-clasificacion-casos/README.md) | Propone categoría y prioridad para los casos sin clasificar | Service Cloud | monday service |
| Servicio | [servicio-respuestas-conocimiento](../../plugins/servicio-respuestas-conocimiento/README.md) | Redacta respuestas apoyadas en los artículos de la base de conocimiento | Service Cloud | monday service |

**Los usuarios son empleados de la empresa** (vendedores, gerentes, agentes de soporte)
que ya usan Claude. Los plugins no son un chat para los clientes finales.

## Qué hace y qué no hace esta versión

- **Lee, y escribe solo donde se decidió.** Cinco plugins solo leen. `ventas-seguimiento` 0.2.0
  puede actualizar el próximo paso, crear una tarea de seguimiento y mover la fecha de cierre,
  siempre con la confirmación del usuario. Ningún plugin borra registros ni envía correos. Los
  límites los ponen los permisos de la conexión, no solo las instrucciones (ver [seguridad.md](seguridad.md)).
- **Respeta los permisos de cada usuario.** Cada persona se conecta con su propia cuenta
  de Salesforce o de monday.com, y ve solo lo que esa cuenta ya puede ver.
- **No guarda datos.** Los datos se quedan en el CRM. Claude los consulta cuando hacen falta.

## Instalación, en orden

| Paso | Quién | Documento |
|---|---|---|
| 1. Preparar la plataforma (activar el servidor MCP y crear la app de conexión) | Administrador de Salesforce **o** de monday.com | [instalacion-salesforce.md](instalacion-salesforce.md) · [instalacion-monday.md](instalacion-monday.md) |
| 2. Añadir los plugins a Claude y elegir quién los recibe | Owner de la organización en Claude | [instalar-en-claude.md](instalar-en-claude.md) |
| 3. Conectar el conector del plugin con su cuenta | Cada usuario | [instalar-en-claude.md](instalar-en-claude.md#3-cada-usuario-conecta-su-cuenta) |
| 4. Probar con la lista de aceptación | Responsable del plugin en la empresa | `docs/06-pruebas-de-aceptacion.md` de cada plugin |

Cada plugin trae además lo suyo en su carpeta `docs/`: los requisitos, qué objetos o tableros
necesita, cómo se usa y sus preguntas frecuentes.

## Lo que la empresa debe saber antes de empezar

- **Plan de Claude.** Para repartir los plugins a toda la organización hace falta un plan
  Team o Enterprise. Un usuario individual puede añadirlos a su propia cuenta.
- **Costos.** El uso de Claude va con el plan de cada usuario. Salesforce y monday.com
  pueden cobrar aparte el uso de sus servidores MCP. Detalle en [costos-y-soporte.md](costos-y-soporte.md).
- **Datos.** Lo que Claude lee del CRM viaja a Anthropic como parte de la conversación.
  Qué viaja, qué no y cómo reducirlo: [seguridad.md](seguridad.md).
- **Criterios de la empresa.** Las reglas de negocio (días sin actividad, rúbrica de leads,
  categorías de casos) vienen con valores iniciales tomados del documento de casos de uso.
  La empresa debe confirmarlos o cambiarlos. Cada plugin dice dónde, en su `docs/01-requisitos.md`.

## Estado de esta versión

| Qué | Estado |
|---|---|
| Estructura de los plugins y su validación | ✅ Pasa `claude plugin validate` (2026-11-07) |
| Pasos de instalación | 📄 Según la documentación oficial consultada el 2026-11-06 y el 2026-11-07 |
| Conexión con Salesforce | ✅ Comprobada el 2026-11-07 en una Developer Edition con claude.ai (pasos 1 a 4 de [instalacion-salesforce.md](instalacion-salesforce.md)) |
| Funcionamiento de cada plugin | ⚠️ Sin probar todavía. Las pruebas empiezan por `ventas-seguimiento` en la Developer Edition |
| Conexión con monday.com | ⚠️ Sin probar. Hace falta una cuenta de prueba de monday.com |
| Requisitos del cliente | ⚠️ Pendientes. Cada `01-requisitos.md` marca lo que falta |

## Documentos de esta carpeta

- [instalar-en-claude.md](instalar-en-claude.md): añadir los plugins a Claude (organización, usuario individual y Claude Code).
- [instalacion-salesforce.md](instalacion-salesforce.md): preparar Salesforce.
- [instalacion-monday.md](instalacion-monday.md): preparar monday.com.
- [seguridad.md](seguridad.md): qué datos se usan, quién ve qué y cómo apagar un plugin.
- [costos-y-soporte.md](costos-y-soporte.md): costos, versiones, soporte y desinstalación.
