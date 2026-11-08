/**
 * Acción para agentes: cambia la fecha de cierre (`CloseDate`) de oportunidades abiertas.
 *
 * Se expone como herramienta del servidor MCP personalizado `AgentesCRM` para el plugin
 * `ventas-seguimiento`, sobre todo para oportunidades con la fecha de cierre vencida.
 * Solo acepta fechas de hoy en adelante. Corre con los permisos del usuario conectado:
 * `with sharing` y DML en `AccessLevel.USER_MODE`. Cada solicitud se resuelve por separado.
 */
global with sharing class AgentesMoverFechaCierre {

    /** Lo que recibe la acción por cada oportunidad. */
    global class Solicitud {
        @InvocableVariable(
            label='Id de la oportunidad'
            description='Id de 18 caracteres de la oportunidad abierta.'
            required=true
        )
        global Id oportunidadId;

        @InvocableVariable(
            label='Nueva fecha de cierre'
            description='Fecha nueva, en formato AAAA-MM-DD. Debe ser hoy o posterior.'
            required=true
        )
        global Date nuevaFechaCierre;
    }

    /** Lo que devuelve la acción por cada solicitud, en el mismo orden. */
    global class Resultado {
        @InvocableVariable(label='Éxito' description='true si el cambio quedó guardado.')
        global Boolean exito;

        @InvocableVariable(label='Mensaje' description='Qué pasó, en una frase. Si falló, el motivo.')
        global String mensaje;

        @InvocableVariable(label='Id de la oportunidad' description='La oportunidad de la solicitud.')
        global Id oportunidadId;

        @InvocableVariable(label='Fecha anterior' description='Fecha de cierre antes del cambio.')
        global Date fechaAnterior;

        @InvocableVariable(label='Fecha nueva' description='Fecha de cierre guardada.')
        global Date fechaNueva;
    }

    /**
     * Cambia la fecha de cierre de cada oportunidad pedida.
     *
     * @param solicitudes Una por oportunidad.
     * @return Un resultado por solicitud, en el mismo orden.
     */
    @InvocableMethod(
        label='Mover fecha de cierre de una oportunidad'
        description='Cambia el campo Close Date de una o varias oportunidades abiertas a una fecha de hoy en adelante. No cambia la etapa ni ningún otro campo. Úsala solo después de que el usuario confirme la fecha exacta.'
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
            oportunidades = AgentesCrmAcciones.leerOportunidades(
                ids, new List<String>{ AgentesCrmAcciones.CAMPO_FECHA_CIERRE }
            );
        } catch (QueryException e) {
            return marcarTodos(resultados, 'No se pudo leer la oportunidad con los permisos del usuario: ' + e.getMessage());
        }

        Set<Id> yaUsadas = new Set<Id>();
        List<Opportunity> cambios = new List<Opportunity>();
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
                error = AgentesCrmAcciones.validarFechaNoPasada(solicitud.nuevaFechaCierre, 'La nueva fecha de cierre');
            }
            if (error == null) {
                error = AgentesCrmAcciones.reservarUnaVez(solicitud.oportunidadId, yaUsadas);
            }
            if (error != null) {
                resultado.mensaje = error;
                continue;
            }
            resultado.fechaAnterior = oportunidades.get(solicitud.oportunidadId).CloseDate;
            resultado.fechaNueva = solicitud.nuevaFechaCierre;
            cambios.add(new Opportunity(Id = solicitud.oportunidadId, CloseDate = solicitud.nuevaFechaCierre));
            enEspera.add(resultado);
        }

        if (cambios.isEmpty()) {
            return resultados;
        }
        try {
            List<Database.SaveResult> guardados = Database.update(cambios, false, AccessLevel.USER_MODE);
            for (Integer i = 0; i < guardados.size(); i++) {
                Resultado resultado = enEspera[i];
                if (guardados[i].isSuccess()) {
                    resultado.exito = true;
                    resultado.mensaje = 'Fecha de cierre actualizada.';
                } else {
                    resultado.fechaNueva = null;
                    resultado.mensaje = AgentesCrmAcciones.resumirErrores(guardados[i].getErrors());
                }
            }
        } catch (Exception e) {
            marcarTodos(enEspera, 'No se guardó ningún cambio: ' + e.getMessage());
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
            resultado.fechaNueva = null;
            resultado.mensaje = mensaje;
        }
        return resultados;
    }
}
