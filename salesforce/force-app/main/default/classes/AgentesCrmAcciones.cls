/**
 * Reglas comunes de las acciones que los plugins de Claude ejecutan en Salesforce.
 *
 * Es el único sitio donde viven estas reglas (regla T10): qué oportunidad se puede
 * modificar, qué fecha es válida y cómo se resumen los errores. Cada acción
 * (`AgentesActualizarProximoPaso`, `AgentesCrearTareaSeguimiento`,
 * `AgentesMoverFechaCierre`) le pregunta a esta clase en vez de repetir la regla.
 *
 * Todo corre con los permisos del usuario conectado: la clase es `with sharing`
 * (reglas de compartición) y las consultas usan `AccessLevel.USER_MODE`
 * (permisos de objeto y de campo).
 */
public with sharing class AgentesCrmAcciones {

    /** Campo de la oportunidad que lee la acción de próximo paso. */
    public static final String CAMPO_PROXIMO_PASO = 'NextStep';

    /** Campo de la oportunidad que lee la acción de fecha de cierre. */
    public static final String CAMPO_FECHA_CIERRE = 'CloseDate';

    /** Campos permitidos en la consulta; nada que llegue de fuera entra en el SOQL. */
    private static final Set<String> CAMPOS_PERMITIDOS = new Set<String>{
        CAMPO_PROXIMO_PASO,
        CAMPO_FECHA_CIERRE
    };

    /**
     * Lee las oportunidades pedidas con los permisos del usuario.
     *
     * @param ids Ids de oportunidad; los nulos se ignoran.
     * @param camposExtra Campos además de `Id`, `Name` e `IsClosed`; solo los de `CAMPOS_PERMITIDOS`.
     * @return Mapa por Id. Falta un Id si la oportunidad no existe o el usuario no la puede ver.
     * @throws QueryException si el usuario no puede leer el objeto o alguno de los campos.
     */
    public static Map<Id, Opportunity> leerOportunidades(Set<Id> ids, List<String> camposExtra) {
        Set<Id> idsValidos = new Set<Id>();
        for (Id recordId : ids) {
            if (recordId != null && recordId.getSObjectType() == Opportunity.SObjectType) {
                idsValidos.add(recordId);
            }
        }
        if (idsValidos.isEmpty()) {
            return new Map<Id, Opportunity>();
        }
        List<String> campos = new List<String>{ 'Id', 'Name', 'IsClosed' };
        for (String campo : camposExtra) {
            if (!CAMPOS_PERMITIDOS.contains(campo)) {
                throw new IllegalArgumentException('Campo no permitido en la consulta: ' + campo);
            }
            campos.add(campo);
        }
        String soql = 'SELECT ' + String.join(campos, ', ') + ' FROM Opportunity WHERE Id IN :ids';
        List<Opportunity> filas = Database.queryWithBinds(
            soql,
            new Map<String, Object>{ 'ids' => idsValidos },
            AccessLevel.USER_MODE
        );
        return new Map<Id, Opportunity>(filas);
    }

    /**
     * Comprueba que una oportunidad se pueda modificar.
     *
     * @param recordId Id recibido en la solicitud.
     * @param encontradas Resultado de `leerOportunidades`.
     * @return `null` si se puede modificar; si no, el motivo en una frase.
     */
    public static String validarOportunidadAbierta(Id recordId, Map<Id, Opportunity> encontradas) {
        if (recordId == null) {
            return 'Falta el Id de la oportunidad.';
        }
        if (recordId.getSObjectType() != Opportunity.SObjectType) {
            return 'El Id ' + recordId + ' no es de una oportunidad.';
        }
        if (!encontradas.containsKey(recordId)) {
            return 'La oportunidad ' + recordId + ' no existe o el usuario no tiene acceso a ella.';
        }
        if (encontradas.get(recordId).IsClosed) {
            return 'La oportunidad ' + recordId + ' está cerrada; no se modifica.';
        }
        return null;
    }

    /**
     * Reserva una oportunidad para un solo cambio por llamada. Se llama al final, cuando la
     * solicitud ya pasó todas las demás validaciones, para que una solicitud rechazada no
     * bloquee a otra válida de la misma oportunidad.
     *
     * @param recordId Id de la oportunidad.
     * @param yaUsadas Ids ya aceptados en la misma llamada; se le añade `recordId`.
     * @return `null` si es la primera vez; si no, el motivo.
     */
    public static String reservarUnaVez(Id recordId, Set<Id> yaUsadas) {
        if (!yaUsadas.add(recordId)) {
            return 'La oportunidad ' + recordId + ' aparece más de una vez en la misma llamada.';
        }
        return null;
    }

    /**
     * Comprueba que una fecha sea hoy o posterior, en la zona horaria del usuario.
     *
     * @param fecha Fecha recibida.
     * @param nombre Cómo se llama la fecha en el mensaje («La fecha de vencimiento»).
     * @return `null` si es válida; si no, el motivo.
     */
    public static String validarFechaNoPasada(Date fecha, String nombre) {
        if (fecha == null) {
            return 'Falta ' + nombre.toLowerCase() + '.';
        }
        if (fecha < Date.today()) {
            return nombre + ' (' + String.valueOf(fecha) + ') ya pasó; debe ser hoy o posterior.';
        }
        return null;
    }

    /**
     * Comprueba un texto obligatorio y su largo máximo.
     *
     * @param texto Texto recibido.
     * @param nombre Cómo se llama en el mensaje.
     * @param largoMaximo Largo del campo en Salesforce.
     * @return `null` si es válido; si no, el motivo.
     */
    public static String validarTexto(String texto, String nombre, Integer largoMaximo) {
        if (String.isBlank(texto)) {
            return nombre + ' no puede estar vacío.';
        }
        if (texto.trim().length() > largoMaximo) {
            return nombre + ' tiene ' + texto.trim().length() + ' caracteres; el máximo es ' + largoMaximo + '.';
        }
        return null;
    }

    /**
     * Junta los errores de un registro de DML en una sola frase.
     *
     * @param errores Errores de un `Database.SaveResult`.
     * @return Los mensajes separados por « | ».
     */
    public static String resumirErrores(List<Database.Error> errores) {
        List<String> mensajes = new List<String>();
        for (Database.Error error : errores) {
            mensajes.add(error.getMessage());
        }
        return String.join(mensajes, ' | ');
    }
}
