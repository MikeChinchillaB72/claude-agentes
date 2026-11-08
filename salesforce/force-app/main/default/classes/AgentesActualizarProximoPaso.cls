/**
 * Acción para agentes: reemplaza el próximo paso (`NextStep`) de oportunidades abiertas.
 *
 * Se expone como herramienta del servidor MCP personalizado `AgentesCRM` para el plugin
 * `ventas-seguimiento`. Corre con los permisos del usuario conectado: `with sharing` y
 * DML en `AccessLevel.USER_MODE`. Cada solicitud se resuelve por separado: un fallo no
 * deshace las demás y el resultado dice cuál falló y por qué.
 */
global with sharing class AgentesActualizarProximoPaso {

    /** Lo que recibe la acción por cada oportunidad. */
    global class Solicitud {
        @InvocableVariable(
            label='Id de la oportunidad'
            description='Id de 18 caracteres de la oportunidad abierta que se actualiza.'
            required=true
        )
        global Id oportunidadId;

        @InvocableVariable(
            label='Próximo paso'
            description='Texto nuevo del próximo paso. Reemplaza el valor actual. Máximo 255 caracteres.'
            required=true
        )
        global String proximoPaso;
    }

    /** Lo que devuelve la acción por cada solicitud, en el mismo orden. */
    global class Resultado {
        @InvocableVariable(label='Éxito' description='true si el cambio quedó guardado.')
        global Boolean exito;

        @InvocableVariable(label='Mensaje' description='Qué pasó, en una frase. Si falló, el motivo.')
        global String mensaje;

        @InvocableVariable(label='Id de la oportunidad' description='La oportunidad de la solicitud.')
        global Id oportunidadId;

        @InvocableVariable(label='Valor anterior' description='Próximo paso antes del cambio.')
        global String valorAnterior;

        @InvocableVariable(label='Valor nuevo' description='Próximo paso guardado.')
        global String valorNuevo;
    }

    /**
     * Actualiza el próximo paso de cada oportunidad pedida.
     *
     * @param solicitudes Una por oportunidad.
     * @return Un resultado por solicitud, en el mismo orden.
     */
    @InvocableMethod(
        label='Actualizar próximo paso de una oportunidad'
        description='Reemplaza el campo Next Step de una o varias oportunidades abiertas del usuario. No cambia ningún otro campo. Úsala solo después de que el usuario confirme el texto exacto.'
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
                ids, new List<String>{ AgentesCrmAcciones.CAMPO_PROXIMO_PASO }
            );
        } catch (QueryException e) {
            return marcarTodos(resultados, 'No se pudo leer la oportunidad con los permisos del usuario: ' + e.getMessage());
        }

        Integer largoMaximo = Opportunity.NextStep.getDescribe().getLength();
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
                error = AgentesCrmAcciones.validarTexto(solicitud.proximoPaso, 'El próximo paso', largoMaximo);
            }
            if (error == null) {
                error = AgentesCrmAcciones.reservarUnaVez(solicitud.oportunidadId, yaUsadas);
            }
            if (error != null) {
                resultado.mensaje = error;
                continue;
            }
            String texto = solicitud.proximoPaso.trim();
            resultado.valorAnterior = oportunidades.get(solicitud.oportunidadId).NextStep;
            resultado.valorNuevo = texto;
            cambios.add(new Opportunity(Id = solicitud.oportunidadId, NextStep = texto));
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
                    resultado.mensaje = 'Próximo paso actualizado.';
                } else {
                    resultado.valorNuevo = null;
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
            resultado.valorNuevo = null;
            resultado.mensaje = mensaje;
        }
        return resultados;
    }
}
