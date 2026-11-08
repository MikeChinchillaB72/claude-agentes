/**
 * Acción para agentes: lee el estado de una oportunidad (etapa, monto, fecha de cierre y próximo
 * paso), su historial reciente (últimas tareas y eventos) y su contacto principal. Es de solo
 * lectura. El estado sirve para mostrar el valor actual antes de proponer un cambio, también
 * cuando el agente llega a la oportunidad sin pasar por la búsqueda.
 *
 * La usa el agente de Agentforce del plugin `ventas-seguimiento` para redactar correos y
 * próximos pasos con contexto. Equivale al paso 3 de la skill `seguimiento-oportunidades`, que
 * en claude.ai se hace con `sobject-reads`.
 *
 * Cuántas actividades leer llega en la solicitud y sale de las instrucciones del agente, que lo
 * copian de `interacciones_a_leer` en `references/criterios.md` (regla M7).
 *
 * Corre con los permisos del usuario conectado: `with sharing` y consulta en
 * `AccessLevel.USER_MODE`. Si el usuario no puede leer la oportunidad o un campo, la acción
 * falla y lo dice.
 *
 * Todas las solicitudes se resuelven con una sola consulta: la oportunidad (con sus campos de
 * estado) y tres subconsultas
 * (tareas, eventos y contacto principal). El `LIMIT` de una subconsulta se aplica a cada
 * oportunidad, así que se pide el máximo de todas las solicitudes y luego se recorta cada una.
 */
global with sharing class AgentesLeerHistorialOportunidad {

    /** Lo que recibe la acción por cada oportunidad. */
    global class Solicitud {
        @InvocableVariable(
            label='Id de la oportunidad'
            description='Id de 18 caracteres de la oportunidad cuyo historial se lee.'
            required=true
        )
        global Id oportunidadId;

        @InvocableVariable(
            label='Máximo de actividades'
            description='Cuántas tareas y cuántos eventos leer como mucho, de los más recientes a los más antiguos. Número entero de 1 en adelante.'
            required=true
        )
        global Integer maximoActividades;
    }

    /** Lo que devuelve la acción por cada solicitud, en el mismo orden. */
    global class Resultado {
        @InvocableVariable(label='Éxito' description='true si se leyó el historial, aunque esté vacío.')
        global Boolean exito;

        @InvocableVariable(label='Mensaje' description='Qué pasó, en una frase. Si falló, el motivo.')
        global String mensaje;

        @InvocableVariable(label='Id de la oportunidad' description='La oportunidad de la solicitud.')
        global Id oportunidadId;

        @InvocableVariable(label='Nombre de la oportunidad' description='Nombre de la oportunidad.')
        global String nombreOportunidad;

        @InvocableVariable(label='Etapa' description='Etapa actual de la oportunidad.')
        global String etapa;

        @InvocableVariable(label='Monto' description='Monto actual de la oportunidad.')
        global Decimal monto;

        @InvocableVariable(label='Fecha de cierre' description='Fecha de cierre actual de la oportunidad.')
        global Date fechaCierre;

        @InvocableVariable(label='Próximo paso' description='Próximo paso actual de la oportunidad (campo Next Step). Vacío si no tiene.')
        global String proximoPaso;

        @InvocableVariable(label='Cerrada' description='true si la oportunidad está cerrada; entonces las acciones que escriben no la modifican.')
        global Boolean cerrada;

        @InvocableVariable(
            label='Tareas'
            description='Últimas tareas de la oportunidad, de la más reciente a la más antigua: asunto, fecha, estado y descripción.'
        )
        global List<Task> tareas;

        @InvocableVariable(
            label='Eventos'
            description='Últimos eventos de la oportunidad, del más reciente al más antiguo: asunto, fecha y descripción.'
        )
        global List<Event> eventos;

        @InvocableVariable(
            label='Contacto principal'
            description='Contacto marcado como principal en la oportunidad: nombre, cargo y correo. Vacío si no hay.'
        )
        global Contact contactoPrincipal;

        @InvocableVariable(label='Rol del contacto' description='Rol del contacto principal en la oportunidad, si tiene.')
        global String rolContacto;
    }

    /**
     * Lee el historial de cada oportunidad pedida.
     *
     * @param solicitudes Una por oportunidad.
     * @return Un resultado por solicitud, en el mismo orden.
     */
    @InvocableMethod(
        label='Leer historial de una oportunidad'
        description='Devuelve el estado actual de una oportunidad (etapa, monto, fecha de cierre y próximo paso), sus últimas tareas y eventos y su contacto principal (nombre, cargo y correo). Solo lee; no cambia nada. Úsala antes de redactar un correo de seguimiento o de proponer un cambio.'
        category='Agentes CRM'
    )
    global static List<Resultado> ejecutar(List<Solicitud> solicitudes) {
        List<Resultado> resultados = new List<Resultado>();
        Set<Id> ids = new Set<Id>();
        Integer maximo = 0;
        for (Solicitud solicitud : solicitudes) {
            Resultado resultado = nuevoResultado(solicitud);
            resultado.mensaje = validar(solicitud);
            resultados.add(resultado);
            if (resultado.mensaje == null) {
                ids.add(solicitud.oportunidadId);
                maximo = Math.max(maximo, solicitud.maximoActividades);
            }
        }
        if (ids.isEmpty()) {
            return resultados;
        }

        Map<Id, Opportunity> oportunidades;
        try {
            oportunidades = leer(ids, maximo);
        } catch (QueryException e) {
            String motivo = 'No se pudo leer el historial con los permisos del usuario: ' + e.getMessage();
            for (Resultado resultado : resultados) {
                if (resultado.mensaje == null) {
                    resultado.mensaje = motivo;
                }
            }
            return resultados;
        }

        for (Integer i = 0; i < solicitudes.size(); i++) {
            Resultado resultado = resultados[i];
            if (resultado.mensaje != null) {
                continue;
            }
            Opportunity oportunidad = oportunidades.get(solicitudes[i].oportunidadId);
            if (oportunidad == null) {
                resultado.mensaje = 'La oportunidad ' + solicitudes[i].oportunidadId + ' no existe o el usuario no tiene acceso a ella.';
                continue;
            }
            completar(resultado, oportunidad, solicitudes[i].maximoActividades);
        }
        return resultados;
    }

    private static Map<Id, Opportunity> leer(Set<Id> ids, Integer maximo) {
        // El límite de las subconsultas va como número en el texto: es un Integer ya validado,
        // no texto de fuera, así que no abre la puerta a inyección.
        String limite = String.valueOf(maximo);
        String soql = 'SELECT Id, Name, StageName, Amount, CloseDate, NextStep, IsClosed,' +
            ' (SELECT Id, Subject, ActivityDate, Status, Description FROM Tasks' +
            '  ORDER BY ActivityDate DESC NULLS LAST, CreatedDate DESC LIMIT ' + limite + '),' +
            ' (SELECT Id, Subject, ActivityDate, ActivityDateTime, Description FROM Events' +
            '  ORDER BY ActivityDate DESC NULLS LAST, CreatedDate DESC LIMIT ' + limite + '),' +
            ' (SELECT ContactId, Contact.Name, Contact.Title, Contact.Email, Role FROM OpportunityContactRoles' +
            '  WHERE IsPrimary = true LIMIT 1)' +
            ' FROM Opportunity WHERE Id IN :ids';
        List<Opportunity> filas = Database.queryWithBinds(
            soql,
            new Map<String, Object>{ 'ids' => ids },
            AccessLevel.USER_MODE
        );
        return new Map<Id, Opportunity>(filas);
    }

    private static void completar(Resultado resultado, Opportunity oportunidad, Integer maximo) {
        resultado.nombreOportunidad = oportunidad.Name;
        resultado.etapa = oportunidad.StageName;
        resultado.monto = oportunidad.Amount;
        resultado.fechaCierre = oportunidad.CloseDate;
        resultado.proximoPaso = oportunidad.NextStep;
        resultado.cerrada = oportunidad.IsClosed;
        resultado.tareas = (List<Task>) recortar(oportunidad.Tasks, maximo);
        resultado.eventos = (List<Event>) recortar(oportunidad.Events, maximo);
        if (!oportunidad.OpportunityContactRoles.isEmpty()) {
            OpportunityContactRole rol = oportunidad.OpportunityContactRoles[0];
            resultado.contactoPrincipal = rol.Contact;
            resultado.rolContacto = rol.Role;
        }
        resultado.exito = true;
        resultado.mensaje = resultado.tareas.size() + ' tareas y ' + resultado.eventos.size() + ' eventos' +
            (resultado.contactoPrincipal == null ? '; sin contacto principal.' : '; con contacto principal.');
    }

    /** Devuelve los primeros `maximo` registros de la lista, que ya viene ordenada. */
    private static List<SObject> recortar(List<SObject> registros, Integer maximo) {
        List<SObject> primeros = registros.clone();
        primeros.clear();
        for (Integer i = 0; i < registros.size() && i < maximo; i++) {
            primeros.add(registros[i]);
        }
        return primeros;
    }

    private static Resultado nuevoResultado(Solicitud solicitud) {
        Resultado resultado = new Resultado();
        resultado.exito = false;
        resultado.oportunidadId = solicitud == null ? null : solicitud.oportunidadId;
        resultado.tareas = new List<Task>();
        resultado.eventos = new List<Event>();
        return resultado;
    }

    /** @return `null` si la solicitud es válida; si no, el motivo en una frase. */
    private static String validar(Solicitud solicitud) {
        if (solicitud == null) {
            return 'Solicitud vacía.';
        }
        if (solicitud.oportunidadId == null) {
            return 'Falta el Id de la oportunidad.';
        }
        if (solicitud.oportunidadId.getSObjectType() != Opportunity.SObjectType) {
            return 'El Id ' + solicitud.oportunidadId + ' no es de una oportunidad.';
        }
        if (solicitud.maximoActividades == null || solicitud.maximoActividades < 1) {
            return 'El máximo de actividades debe ser un número entero de 1 en adelante.';
        }
        return null;
    }
}
