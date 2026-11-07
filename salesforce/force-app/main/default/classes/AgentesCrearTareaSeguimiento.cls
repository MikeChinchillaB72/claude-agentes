/**
 * Acción para agentes: crea una tarea de seguimiento ligada a una oportunidad abierta.
 *
 * Se expone como herramienta del servidor MCP personalizado `AgentesCRM` para el plugin
 * `ventas-seguimiento`. La tarea queda asignada al usuario conectado, con el estado y la
 * prioridad por defecto de la org. Corre con los permisos del usuario: `with sharing` y
 * DML en `AccessLevel.USER_MODE`. Cada solicitud se resuelve por separado.
 */
global with sharing class AgentesCrearTareaSeguimiento {

    /** Lo que recibe la acción por cada tarea. */
    global class Solicitud {
        @InvocableVariable(
            label='Id de la oportunidad'
            description='Id de 18 caracteres de la oportunidad abierta a la que se liga la tarea.'
            required=true
        )
        global Id oportunidadId;

        @InvocableVariable(
            label='Asunto'
            description='Asunto de la tarea, por ejemplo «Enviar propuesta a 3 años». Máximo 255 caracteres.'
            required=true
        )
        global String asunto;

        @InvocableVariable(
            label='Fecha de vencimiento'
            description='Fecha en formato AAAA-MM-DD. Debe ser hoy o posterior.'
            required=true
        )
        global Date fechaVencimiento;

        @InvocableVariable(
            label='Descripción'
            description='Opcional. Detalle de lo que hay que hacer.'
        )
        global String descripcion;

        @InvocableVariable(
            label='Id del contacto'
            description='Opcional. Id de 18 caracteres del contacto relacionado, por ejemplo el contacto principal de la oportunidad.'
        )
        global Id contactoId;
    }

    /** Lo que devuelve la acción por cada solicitud, en el mismo orden. */
    global class Resultado {
        @InvocableVariable(label='Éxito' description='true si la tarea quedó creada.')
        global Boolean exito;

        @InvocableVariable(label='Mensaje' description='Qué pasó, en una frase. Si falló, el motivo.')
        global String mensaje;

        @InvocableVariable(label='Id de la oportunidad' description='La oportunidad de la solicitud.')
        global Id oportunidadId;

        @InvocableVariable(label='Id de la tarea' description='La tarea creada.')
        global Id tareaId;
    }

    /**
     * Crea una tarea por cada solicitud.
     *
     * @param solicitudes Una por tarea; puede haber varias para la misma oportunidad.
     * @return Un resultado por solicitud, en el mismo orden.
     */
    @InvocableMethod(
        label='Crear tarea de seguimiento en una oportunidad'
        description='Crea una tarea asignada al usuario conectado y ligada a una oportunidad abierta, con asunto y fecha de vencimiento. No cambia la oportunidad. Úsala solo después de que el usuario confirme el asunto y la fecha.'
        category='Agentes CRM'
    )
    global static List<Resultado> ejecutar(List<Solicitud> solicitudes) {
        List<Resultado> resultados = new List<Resultado>();
        Set<Id> ids = new Set<Id>();
        for (Solicitud solicitud : solicitudes) {
            resultados.add(nuevoResultado(solicitud));
            if (solicitud != null) {
                ids.add(solicitud.oportunidadId);
            }
        }

        Map<Id, Opportunity> oportunidades;
        try {
            oportunidades = AgentesCrmAcciones.leerOportunidades(ids, new List<String>());
        } catch (QueryException e) {
            return marcarTodos(resultados, 'No se pudo leer la oportunidad con los permisos del usuario: ' + e.getMessage());
        }

        Integer largoAsunto = Task.Subject.getDescribe().getLength();
        Integer largoDescripcion = Task.Description.getDescribe().getLength();
        List<Task> nuevas = new List<Task>();
        List<Resultado> enEspera = new List<Resultado>();

        for (Integer i = 0; i < solicitudes.size(); i++) {
            Solicitud solicitud = solicitudes[i];
            Resultado resultado = resultados[i];
            if (solicitud == null) {
                resultado.mensaje = 'Solicitud vacía.';
                continue;
            }
            String error = AgentesCrmAcciones.validarOportunidadAbierta(solicitud.oportunidadId, oportunidades);
            if (error == null) {
                error = AgentesCrmAcciones.validarTexto(solicitud.asunto, 'El asunto', largoAsunto);
            }
            if (error == null) {
                error = AgentesCrmAcciones.validarFechaNoPasada(solicitud.fechaVencimiento, 'La fecha de vencimiento');
            }
            if (error == null && String.isNotBlank(solicitud.descripcion) && solicitud.descripcion.length() > largoDescripcion) {
                error = 'La descripción supera el máximo de ' + largoDescripcion + ' caracteres.';
            }
            if (error == null && solicitud.contactoId != null && solicitud.contactoId.getSObjectType() != Contact.SObjectType) {
                error = 'El Id ' + solicitud.contactoId + ' no es de un contacto.';
            }
            if (error != null) {
                resultado.mensaje = error;
                continue;
            }
            nuevas.add(new Task(
                WhatId = solicitud.oportunidadId,
                WhoId = solicitud.contactoId,
                Subject = solicitud.asunto.trim(),
                ActivityDate = solicitud.fechaVencimiento,
                Description = String.isBlank(solicitud.descripcion) ? null : solicitud.descripcion.trim(),
                OwnerId = UserInfo.getUserId()
            ));
            enEspera.add(resultado);
        }

        if (nuevas.isEmpty()) {
            return resultados;
        }
        try {
            List<Database.SaveResult> guardados = Database.insert(nuevas, false, AccessLevel.USER_MODE);
            for (Integer i = 0; i < guardados.size(); i++) {
                Resultado resultado = enEspera[i];
                if (guardados[i].isSuccess()) {
                    resultado.exito = true;
                    resultado.tareaId = guardados[i].getId();
                    resultado.mensaje = 'Tarea creada.';
                } else {
                    resultado.mensaje = AgentesCrmAcciones.resumirErrores(guardados[i].getErrors());
                }
            }
        } catch (Exception e) {
            marcarTodos(enEspera, 'No se creó ninguna tarea: ' + e.getMessage());
        }
        return resultados;
    }

    private static Resultado nuevoResultado(Solicitud solicitud) {
        Resultado resultado = new Resultado();
        resultado.exito = false;
        resultado.oportunidadId = solicitud == null ? null : solicitud.oportunidadId;
        return resultado;
    }

    private static List<Resultado> marcarTodos(List<Resultado> resultados, String mensaje) {
        for (Resultado resultado : resultados) {
            resultado.exito = false;
            resultado.tareaId = null;
            resultado.mensaje = mensaje;
        }
        return resultados;
    }
}
