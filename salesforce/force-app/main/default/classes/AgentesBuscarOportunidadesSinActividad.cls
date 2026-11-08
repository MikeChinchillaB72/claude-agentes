/**
 * Acción para agentes: busca las oportunidades abiertas del usuario conectado que llevan
 * días sin actividad. Es de solo lectura.
 *
 * La usa el agente de Agentforce del plugin `ventas-seguimiento`, que no tiene las
 * herramientas de lectura del servidor `sobject-reads` y necesita una acción para el
 * primer paso del seguimiento. Equivale a la consulta del paso 2 de la skill
 * `seguimiento-oportunidades`.
 *
 * Los valores de negocio (días, cuántas, monto mínimo) no viven aquí: llegan en la
 * solicitud y salen de las instrucciones del agente, que los copian de
 * `references/criterios.md` (regla M7).
 *
 * Corre con los permisos del usuario conectado: `with sharing` y consulta en
 * `AccessLevel.USER_MODE`. Si el usuario no puede leer un campo, la acción falla y lo dice;
 * no lo sustituye por otro.
 *
 * Cada solicitud tiene sus propios filtros y su propio límite, así que se resuelve con su
 * propia consulta. Agentforce y el servidor MCP mandan una solicitud por llamada; si un
 * flujo manda más de `Limits.getLimitQueries()` solicitudes, las que no caben se
 * devuelven con error en vez de romper la transacción.
 */
global with sharing class AgentesBuscarOportunidadesSinActividad {

    /** Campos que devuelve la acción por cada oportunidad. */
    private static final String CAMPOS =
        'Id, Name, AccountId, Account.Name, Amount, StageName, CloseDate, LastActivityDate, NextStep';

    /** Lo que recibe la acción. */
    global class Solicitud {
        @InvocableVariable(
            label='Días sin actividad'
            description='Una oportunidad entra si su última actividad fue hace este número de días o más, o si nunca tuvo actividad. Número entero de 1 en adelante.'
            required=true
        )
        global Integer diasSinActividad;

        @InvocableVariable(
            label='Máximo de oportunidades'
            description='Cuántas oportunidades devolver como mucho, empezando por las de mayor monto. Número entero de 1 en adelante.'
            required=true
        )
        global Integer maximoOportunidades;

        @InvocableVariable(
            label='Monto mínimo'
            description='Opcional. Solo incluye oportunidades con un monto igual o mayor. Vacío: sin mínimo.'
        )
        global Decimal montoMinimo;
    }

    /** Lo que devuelve la acción por cada solicitud, en el mismo orden. */
    global class Resultado {
        @InvocableVariable(label='Éxito' description='true si la búsqueda se hizo, aunque no encuentre nada.')
        global Boolean exito;

        @InvocableVariable(label='Mensaje' description='Qué pasó, en una frase. Si falló, el motivo.')
        global String mensaje;

        @InvocableVariable(label='Cantidad' description='Cuántas oportunidades se devuelven.')
        global Integer cantidad;

        @InvocableVariable(
            label='Oportunidades'
            description='Oportunidades encontradas, de mayor a menor monto: Id, nombre, cuenta, monto, etapa, fecha de cierre, fecha de última actividad y próximo paso.'
        )
        global List<Opportunity> oportunidades;
    }

    /**
     * Busca las oportunidades de cada solicitud.
     *
     * @param solicitudes Normalmente una.
     * @return Un resultado por solicitud, en el mismo orden.
     */
    @InvocableMethod(
        label='Buscar oportunidades sin actividad reciente'
        description='Devuelve las oportunidades abiertas del usuario conectado que llevan el número de días indicado sin actividad (o que nunca tuvieron), de mayor a menor monto. Solo lee; no cambia nada. Úsala cuando el usuario pregunte qué oportunidades necesitan seguimiento.'
        category='Agentes CRM'
    )
    global static List<Resultado> ejecutar(List<Solicitud> solicitudes) {
        List<Resultado> resultados = new List<Resultado>();
        for (Solicitud solicitud : solicitudes) {
            resultados.add(buscar(solicitud));
        }
        return resultados;
    }

    private static Resultado buscar(Solicitud solicitud) {
        Resultado resultado = new Resultado();
        resultado.exito = false;
        resultado.cantidad = 0;
        resultado.oportunidades = new List<Opportunity>();

        String error = validar(solicitud);
        if (error != null) {
            resultado.mensaje = error;
            return resultado;
        }
        if (Limits.getQueries() >= Limits.getLimitQueries()) {
            resultado.mensaje = 'No quedan consultas en esta transacción; repite la búsqueda en otra llamada.';
            return resultado;
        }

        Map<String, Object> valores = new Map<String, Object>{
            'usuarioId' => UserInfo.getUserId(),
            'limite' => Date.today().addDays(-solicitud.diasSinActividad),
            'maximo' => solicitud.maximoOportunidades
        };
        String soql = 'SELECT ' + CAMPOS + ' FROM Opportunity' +
            ' WHERE IsClosed = false AND OwnerId = :usuarioId' +
            ' AND (LastActivityDate = null OR LastActivityDate <= :limite)';
        if (solicitud.montoMinimo != null) {
            soql += ' AND Amount >= :montoMinimo';
            valores.put('montoMinimo', solicitud.montoMinimo);
        }
        soql += ' ORDER BY Amount DESC NULLS LAST, CloseDate ASC, Id LIMIT :maximo';

        try {
            resultado.oportunidades = Database.queryWithBinds(soql, valores, AccessLevel.USER_MODE);
        } catch (QueryException e) {
            resultado.mensaje = 'No se pudo leer las oportunidades con los permisos del usuario: ' + e.getMessage();
            return resultado;
        }
        resultado.exito = true;
        resultado.cantidad = resultado.oportunidades.size();
        resultado.mensaje = resultado.cantidad == 0
            ? 'No hay oportunidades abiertas con ' + solicitud.diasSinActividad + ' días o más sin actividad.'
            : resultado.cantidad + ' oportunidades con ' + solicitud.diasSinActividad + ' días o más sin actividad.';
        return resultado;
    }

    /** @return `null` si la solicitud es válida; si no, el motivo en una frase. */
    private static String validar(Solicitud solicitud) {
        if (solicitud == null) {
            return 'Solicitud vacía.';
        }
        if (solicitud.diasSinActividad == null || solicitud.diasSinActividad < 1) {
            return 'Los días sin actividad deben ser un número entero de 1 en adelante.';
        }
        if (solicitud.maximoOportunidades == null || solicitud.maximoOportunidades < 1) {
            return 'El máximo de oportunidades debe ser un número entero de 1 en adelante.';
        }
        if (solicitud.montoMinimo != null && solicitud.montoMinimo < 0) {
            return 'El monto mínimo no puede ser negativo.';
        }
        return null;
    }
}
