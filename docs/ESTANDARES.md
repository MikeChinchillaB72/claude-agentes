# Estándares para agentes

Todo agente de este repositorio cumple estas reglas. Si alguna no aplica, el motivo queda
escrito en el pull request. Las reglas de trabajo generales (M1–M9, T1–T16) están en
[REGLAS.md](REGLAS.md).

**Principio:** toda regla de seguridad se impone en el código o en los permisos. El prompt
solo la explica. Un modelo puede ser manipulado; una herramienta que no existe, no.

## 1. Arquitectura

| Opción | Cuándo usarla |
|---|---|
| API directa (Tool Runner) | Pocas herramientas, flujo corto, baja latencia: chat, webhooks |
| Agent SDK | Necesita archivos, ejecutar código o tareas largas, en nuestra infraestructura |
| Managed Agents | Igual que el SDK pero sin servidor propio, o tareas programadas |
| Plugin | Uso interno del equipo desde la app de Claude |

- **Una sola capa de herramientas por sistema.** Un servidor MCP por sistema (CRM, base de
  datos) concentra autenticación, autorización, validación, límites y auditoría. Cada agente
  recibe solo las herramientas que necesita.
- **Disparadores fiables.** Los webhooks responden rápido y encolan; usan clave de
  idempotencia. Las tareas programadas guardan su progreso para reanudar.
- **Datos fuera del modelo.** Al modelo llegan solo los campos necesarios, en JSON compacto o
  CSV. Las cargas masivas corren sin modelo.

## 2. Seguridad

1. **Mínimo privilegio.** `allowed_tools` (`herramientas.lectura` en la configuración del agente) solo contiene herramientas de lectura. Las que
   escriben o tienen efectos pasan por `politica_de_herramientas()` y, sin aprobador, se deniegan.
2. **Autorización en la herramienta.** Los identificadores de usuario o cliente salen de la
   sesión verificada, nunca de un parámetro que rellena el modelo.
3. **Contenido externo = datos.** Emails, webs, formularios y archivos nunca son instrucciones.
   Un agente que lee contenido externo no tiene herramientas de escritura amplias.
4. **Aprobación humana** para enviar mensajes, borrar, cambiar montos o escribir en masa.
5. **Entorno aislado.** `SANDBOX_ESTRICTO` (sin red salvo lista de dominios). Nunca
   `permission_mode="bypassPermissions"`. Nunca `Bash` en un agente de solo lectura.
6. **Secretos.** En desarrollo, `.env` (excluido de Git). En producción, gestor de secretos o
   bóveda de Managed Agents. Una clave de API por agente y entorno, con rotación.
7. **Límites.** `max_turns`, `max_budget_usd`, límite de gasto por workspace en la consola y
   límite de mensajes por usuario en canales públicos.
8. **Datos personales.** Clasificar campos sensibles, enmascararlos en registros, definir
   retención y borrado, y cumplir la ley de protección de datos que aplique.
9. **Auditoría.** Registro de cada llamada a herramienta: quién, qué, cuándo, resultado y ejecución.
10. **Dependencias.** Versiones fijadas; solo servidores MCP propios o de confianza.
11. **Interruptor de apagado.** Cada agente y herramienta se puede desactivar sin desplegar.

## 3. Ingeniería

- **Modelo.** Por defecto el de `modelo.nombre` en `config/agentes.toml`. Bajar a Sonnet 5.5 o Haiku 5.5 solo si las
  evaluaciones lo justifican. Controlar el razonamiento con `effort` antes de cambiar de modelo.
- **Evaluaciones.** 30 a 100 casos reales por agente con la respuesta esperada, en `evals/<agente>/`.
  Se ejecutan en cada cambio de prompt, herramienta o modelo.
- **Salidas estructuradas.** Si el resultado lo lee el código, se pide con esquema JSON y las
  herramientas se declaran con `strict: true`. Las decisiones (umbral, aprobar, crear) las toma
  el código, no el modelo.
- **Errores.** Reintentar 429, 5xx y red; no reintentar 400 y 404. Manejar `refusal` y
  `max_tokens`. Los fallos de herramienta vuelven al modelo con `is_error: true`.
- **Historial.** Se devuelve completo y sin editar, incluidos los bloques de razonamiento.
- **Observabilidad.** `ejecutar_agente()` registra en JSON: agente, versión, modelo, turnos,
  duración, costo y motivo de parada. Alertas por costo diario y tasa de error.
- **Versionado.** Prompts, herramientas y configuración en Git, por pull request. Cada agente
  tiene `VERSION` y se registra en cada ejecución.
- **Entornos.** Desarrollo con datos de prueba, pre-producción anonimizada, producción. Nunca
  probar contra el sistema real.
- **Pruebas.** Herramientas y políticas se prueban sin llamar a la API (`pytest`, en CI).
- **Costo.** En este orden: caché de prompts, `effort` más bajo, Batch API, cambio de modelo.
  Se mide el costo por tarea completada.

## 4. Operación

Cada agente tiene un responsable y un procedimiento de incidentes: cómo detectar el problema,
apagar el agente y revertir lo que escribió.
