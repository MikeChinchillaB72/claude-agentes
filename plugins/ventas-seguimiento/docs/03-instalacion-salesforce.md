# Instalación en Salesforce: Seguimiento de oportunidades

> Plugin `ventas-seguimiento` 0.2.0. Actualizado: 2026-11-07.

Los pasos completos están en [instalacion-salesforce.md](../../../docs/cliente/instalacion-salesforce.md).
Aquí va lo que necesita este plugin.

## Resumen

1. Desplegar las acciones de [salesforce/](../../../salesforce/README.md) y crear el servidor MCP
   personalizado **`AgentesCRM`** con las seis herramientas de `sobject-reads` y las acciones habilitadas
   ([instalacion-salesforce.md](../../../docs/cliente/instalacion-salesforce.md#acciones-servidor-personalizado-agentescrm)).
2. Crear la External Client App (callback `https://claude.ai/api/mcp/auth_callback`, solo `https`;
   *scopes* `mcp_api` y `refresh_token`; JWT) y copiar su Consumer Key.
3. Dar a los usuarios del plugin un Permission Set con los permisos de abajo y el Permission Set
   **Agentes CRM - Acciones**.
4. Añadir el conector `salesforce` en Claude con la URL y el Consumer Key, y poner las tres acciones en
   **Needs approval** en *Tool permissions*
   ([instalar-en-claude.md](../../../docs/cliente/instalar-en-claude.md)).

## Conector

| Org | URL |
|---|---|
| Producción y Developer Edition (la que trae el plugin) | `https://api.salesforce.com/platform/mcp/v1/custom/AgentesCRM` |
| Sandbox | Copiarla de **Setup > MCP Servers** al activar el servidor (sin comprobar: sería `.../v1/sandbox/custom/AgentesCRM`) |

## Permisos que necesita

Permission Set sugerido: `Claude Seguimiento de oportunidades`, con la lectura de la tabla de abajo
y la escritura de la segunda tabla. Sin permiso de borrar.

| Objeto | Campos | Para qué |
|---|---|---|
| `Opportunity` | Id, Name, AccountId, Amount, StageName, CloseDate, LastActivityDate, NextStep, OwnerId, IsClosed | Buscar las oportunidades sin actividad |
| `Account` | Id, Name | Nombre de la cuenta |
| `Contact` | Id, Name, Email, Title | Destinatario del correo |
| `OpportunityContactRole` | OpportunityId, ContactId, IsPrimary, Role | Contacto principal de la oportunidad |
| `Task y Event` | WhatId, Subject, ActivityDate, Description | Historial reciente |
| `User` | Id, Name | Usuario conectado |

| Escritura | Permiso | Acción |
|---|---|---|
| `Opportunity` | Editar el objeto y el campo NextStep | `actualizar_proximo_paso` |
| `Opportunity` | Editar el objeto y el campo CloseDate | `mover_fecha_cierre` |
| `Task` | Crear | `crear_tarea` |

Además, el Permission Set **Agentes CRM - Acciones** (`Agentes_CRM_Acciones`), que da acceso a las
clases Apex. Si una acción no está habilitada, no se añade al servidor ni se da su permiso.

Si la empresa guarda estos datos en campos personalizados, se añaden al Permission Set y a
[01-requisitos.md](01-requisitos.md).

## Comprobar

En un chat nuevo, con un usuario del grupo piloto: «¿Qué oportunidades mías llevan más de una semana sin actividad?». Debe responder con
registros reales que ese usuario puede ver, citando su Id, y proponer las acciones sin ejecutarlas.
Después, seguir [06-pruebas-de-aceptacion.md](06-pruebas-de-aceptacion.md).
