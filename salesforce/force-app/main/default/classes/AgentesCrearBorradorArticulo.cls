/**
 * Acción para agentes: crea un artículo de Knowledge en borrador a partir de un caso cerrado.
 *
 * La usa el agente de Agentforce de servicio («Borradores de artículo», fase 4 de
 * `salesforce/agentforce/servicio-conocimiento.md`) cuando un caso resuelto no tiene artículo,
 * como propone Knowledge-Centered Service: lo que se resolvió en un caso pasa a ser conocimiento.
 * El agente redacta el título y el resumen; esta clase solo los guarda.
 *
 * Qué hace y qué no:
 * - Crea la versión en borrador (`PublishStatus` = Draft, el valor por defecto) con `Title`,
 *   `Summary`, `Language`, `UrlName` y `SourceId` = el caso, el campo estándar que liga el artículo
 *   con el caso del que salió. **Nunca publica**: publicar lo hace una persona después de revisarlo.
 * - Solo acepta casos cerrados, y no crea un segundo artículo para un caso que ya tiene uno en
 *   borrador o publicado (`SourceId`).
 * - El idioma llega en cada solicitud y sale de las instrucciones del agente (regla M7); se valida
 *   contra los idiomas de Knowledge de la org.
 *
 * Corre con los permisos del usuario conectado: `with sharing`, consultas y DML en
 * `AccessLevel.USER_MODE`. El usuario necesita la casilla Knowledge User y permiso de crear
 * artículos; si no los tiene, la acción falla y lo dice.
 *
 * Todas las solicitudes se resuelven con cuatro consultas como mucho (casos, borradores y
 * publicados de esos casos, y los artículos creados para devolver su número) y un insert.
 *
 * Necesita Lightning Knowledge activado: sin él, `Knowledge__kav` no existe y la clase no compila.
 */
global with sharing class AgentesCrearBorradorArticulo {

    /** Lo que recibe la acción por cada artículo. */
    global class Solicitud {
        @InvocableVariable(
            label='Id del caso'
            description='Id de 18 caracteres del caso cerrado del que sale el artículo.'
            required=true
        )
        global Id casoId;

        @InvocableVariable(
            label='Título'
            description='Título del artículo: el problema, en las palabras del cliente. Máximo 255 caracteres.'
            required=true
        )
        global String titulo;

        @InvocableVariable(
            label='Resumen'
            description='Cuerpo del artículo: el problema, la causa si se conoce y los pasos de la solución. Sin nombres, correos ni teléfonos de clientes. Máximo 1000 caracteres.'
            required=true
        )
        global String resumen;

        @InvocableVariable(
            label='Idioma'
            description='Código del idioma del artículo en Knowledge, por ejemplo en_US. Debe ser un idioma activo de Knowledge en la org.'
            required=true
        )
        global String idioma;
    }

    /** Lo que devuelve la acción por cada solicitud, en el mismo orden. */
    global class Resultado {
        @InvocableVariable(label='Éxito' description='true si el borrador quedó creado.')
        global Boolean exito;

        @InvocableVariable(label='Mensaje' description='Qué pasó, en una frase. Si falló, el motivo.')
        global String mensaje;

        @InvocableVariable(label='Id del caso' description='El caso de la solicitud.')
        global Id casoId;

        @InvocableVariable(label='Id del artículo' description='La versión en borrador creada (Knowledge__kav).')
        global Id articuloId;

        @InvocableVariable(label='Número del artículo' description='Número del artículo (ArticleNumber).')
        global String numeroArticulo;

        @InvocableVariable(label='Nombre de URL' description='UrlName del borrador.')
        global String nombreUrl;
    }

    /** Estados de publicación que cuentan como «el caso ya tiene artículo». */
    private static final List<String> ESTADOS_EXISTENTES = new List<String>{ 'Draft', 'Online' };

    /**
     * Crea un borrador por cada solicitud.
     *
     * @param solicitudes Una por artículo.
     * @return Un resultado por solicitud, en el mismo orden.
     */
    @InvocableMethod(
        label='Crear borrador de artículo desde un caso'
        description='Crea un artículo de Knowledge en borrador (no lo publica) con el título y el resumen dados, ligado a un caso cerrado. No crea nada si el caso está abierto o ya tiene un artículo. Úsala solo después de que el usuario confirme el título y el resumen.'
        category='Agentes CRM'
    )
    global static List<Resultado> ejecutar(List<Solicitud> solicitudes) {
        List<Resultado> resultados = new List<Resultado>();
        Set<Id> ids = new Set<Id>();
        Set<String> idiomas = idiomasDeKnowledge();
        Integer largoTitulo = Knowledge__kav.Title.getDescribe().getLength();
        Integer largoResumen = Knowledge__kav.Summary.getDescribe().getLength();
        for (Solicitud solicitud : solicitudes) {
            Resultado resultado = nuevoResultado(solicitud);
            resultado.mensaje = validar(solicitud, idiomas, largoTitulo, largoResumen);
            resultados.add(resultado);
            if (resultado.mensaje == null) {
                ids.add(solicitud.casoId);
            }
        }
        if (ids.isEmpty()) {
            return resultados;
        }

        Map<Id, Case> casos;
        Map<Id, Knowledge__kav> existentes;
        try {
            casos = new Map<Id, Case>([
                SELECT Id, CaseNumber, IsClosed FROM Case WHERE Id IN :ids WITH USER_MODE
            ]);
            existentes = articulosDeCasos(casos.keySet());
        } catch (QueryException e) {
            return marcarPendientes(resultados, 'No se pudo leer el caso o sus artículos con los permisos del usuario: ' + e.getMessage());
        }

        List<Knowledge__kav> nuevos = new List<Knowledge__kav>();
        List<Resultado> enEspera = new List<Resultado>();
        Set<Id> yaUsados = new Set<Id>();
        for (Integer i = 0; i < solicitudes.size(); i++) {
            Resultado resultado = resultados[i];
            if (resultado.mensaje != null) {
                continue;
            }
            Solicitud solicitud = solicitudes[i];
            Case caso = casos.get(solicitud.casoId);
            resultado.mensaje = validarCaso(solicitud.casoId, caso, existentes, yaUsados);
            if (resultado.mensaje != null) {
                continue;
            }
            yaUsados.add(caso.Id);
            String nombreUrl = nombreUrl(solicitud.titulo, caso.CaseNumber);
            nuevos.add(new Knowledge__kav(
                Title = solicitud.titulo.trim(),
                Summary = solicitud.resumen.trim(),
                Language = solicitud.idioma,
                UrlName = nombreUrl,
                SourceId = caso.Id
            ));
            resultado.nombreUrl = nombreUrl;
            enEspera.add(resultado);
        }
        if (nuevos.isEmpty()) {
            return resultados;
        }

        try {
            guardar(nuevos, enEspera);
        } catch (Exception e) {
            for (Resultado resultado : enEspera) {
                resultado.exito = false;
                resultado.articuloId = null;
                resultado.numeroArticulo = null;
                resultado.mensaje = 'No se creó ningún borrador: ' + e.getMessage();
            }
        }
        return resultados;
    }

    /** Inserta los borradores y completa sus resultados con el Id y el número de artículo. */
    private static void guardar(List<Knowledge__kav> nuevos, List<Resultado> enEspera) {
        List<Database.SaveResult> guardados = Database.insert(nuevos, false, AccessLevel.USER_MODE);
        Set<Id> creados = new Set<Id>();
        for (Integer i = 0; i < guardados.size(); i++) {
            if (guardados[i].isSuccess()) {
                creados.add(guardados[i].getId());
                enEspera[i].articuloId = guardados[i].getId();
            } else {
                enEspera[i].mensaje = AgentesCrmAcciones.resumirErrores(guardados[i].getErrors());
            }
        }
        if (creados.isEmpty()) {
            return;
        }
        Map<Id, Knowledge__kav> leidos = new Map<Id, Knowledge__kav>([
            SELECT Id, ArticleNumber FROM Knowledge__kav WHERE Id IN :creados WITH USER_MODE
        ]);
        for (Resultado resultado : enEspera) {
            if (resultado.articuloId == null) {
                continue;
            }
            resultado.exito = true;
            resultado.numeroArticulo = leidos.get(resultado.articuloId)?.ArticleNumber;
            resultado.mensaje = 'Borrador creado; falta que una persona lo revise y lo publique.';
        }
    }

    /**
     * Lee los artículos en borrador o publicados que salieron de los casos dados. Knowledge exige
     * filtrar por `PublishStatus` con igualdad, así que va una consulta por estado.
     *
     * @return Mapa de caso a uno de sus artículos.
     */
    private static Map<Id, Knowledge__kav> articulosDeCasos(Set<Id> casoIds) {
        Map<Id, Knowledge__kav> porCaso = new Map<Id, Knowledge__kav>();
        if (casoIds.isEmpty()) {
            return porCaso;
        }
        for (String estado : ESTADOS_EXISTENTES) {
            for (Knowledge__kav articulo : [
                SELECT Id, ArticleNumber, PublishStatus, SourceId FROM Knowledge__kav
                WHERE PublishStatus = :estado AND SourceId IN :casoIds
                WITH USER_MODE
            ]) {
                porCaso.put(articulo.SourceId, articulo);
            }
        }
        return porCaso;
    }

    /** @return Los códigos de idioma activos del campo `Language` de Knowledge en la org. */
    private static Set<String> idiomasDeKnowledge() {
        Set<String> idiomas = new Set<String>();
        for (Schema.PicklistEntry entrada : Knowledge__kav.Language.getDescribe().getPicklistValues()) {
            if (entrada.isActive()) {
                idiomas.add(entrada.getValue());
            }
        }
        return idiomas;
    }

    /**
     * Arma el `UrlName`: el título en minúsculas, sin acentos, con guiones, y el número del caso al
     * final para que no se repita. Se recorta para caber en el campo.
     */
    @TestVisible
    private static String nombreUrl(String titulo, String numeroCaso) {
        String base = titulo.trim().toLowerCase();
        Map<String, String> sinAcento = new Map<String, String>{
            'á' => 'a', 'à' => 'a', 'ä' => 'a', 'â' => 'a', 'é' => 'e', 'è' => 'e', 'ë' => 'e', 'ê' => 'e',
            'í' => 'i', 'ì' => 'i', 'ï' => 'i', 'î' => 'i', 'ó' => 'o', 'ò' => 'o', 'ö' => 'o', 'ô' => 'o',
            'ú' => 'u', 'ù' => 'u', 'ü' => 'u', 'û' => 'u', 'ñ' => 'n', 'ç' => 'c'
        };
        for (String letra : sinAcento.keySet()) {
            base = base.replace(letra, sinAcento.get(letra));
        }
        base = base.replaceAll('[^a-z0-9]+', '-').removeStart('-').removeEnd('-');
        String sufijo = 'caso-' + numeroCaso;
        Integer largoMaximo = Knowledge__kav.UrlName.getDescribe().getLength() - sufijo.length() - 1;
        if (base.length() > largoMaximo) {
            base = base.left(largoMaximo).removeEnd('-');
        }
        return String.isBlank(base) ? sufijo : base + '-' + sufijo;
    }

    private static Resultado nuevoResultado(Solicitud solicitud) {
        Resultado resultado = new Resultado();
        resultado.exito = false;
        resultado.casoId = solicitud == null ? null : solicitud.casoId;
        return resultado;
    }

    /** @return `null` si la solicitud es válida sin consultar nada; si no, el motivo. */
    private static String validar(Solicitud solicitud, Set<String> idiomas, Integer largoTitulo, Integer largoResumen) {
        if (solicitud == null) {
            return 'Solicitud vacía.';
        }
        if (solicitud.casoId == null) {
            return 'Falta el Id del caso.';
        }
        if (solicitud.casoId.getSObjectType() != Case.SObjectType) {
            return 'El Id ' + solicitud.casoId + ' no es de un caso.';
        }
        String error = AgentesCrmAcciones.validarTexto(solicitud.titulo, 'El título', largoTitulo);
        if (error == null) {
            error = AgentesCrmAcciones.validarTexto(solicitud.resumen, 'El resumen', largoResumen);
        }
        if (error == null && (String.isBlank(solicitud.idioma) || !idiomas.contains(solicitud.idioma))) {
            error = 'El idioma «' + solicitud.idioma + '» no es un idioma activo de Knowledge en la org (' +
                String.join(new List<String>(idiomas), ', ') + ').';
        }
        return error;
    }

    /** @return `null` si del caso se puede sacar un borrador; si no, el motivo. */
    private static String validarCaso(Id casoId, Case caso, Map<Id, Knowledge__kav> existentes, Set<Id> yaUsados) {
        if (caso == null) {
            return 'El caso ' + casoId + ' no existe o el usuario no tiene acceso a él.';
        }
        if (!caso.IsClosed) {
            return 'El caso ' + caso.CaseNumber + ' sigue abierto; los artículos salen de casos resueltos.';
        }
        Knowledge__kav existente = existentes.get(caso.Id);
        if (existente != null) {
            return 'El caso ' + caso.CaseNumber + ' ya tiene el artículo ' + existente.ArticleNumber +
                ' (' + existente.PublishStatus + '); no se crea otro.';
        }
        if (yaUsados.contains(caso.Id)) {
            return 'El caso ' + caso.CaseNumber + ' viene dos veces en la misma llamada; solo se crea un borrador.';
        }
        return null;
    }

    private static List<Resultado> marcarPendientes(List<Resultado> resultados, String mensaje) {
        for (Resultado resultado : resultados) {
            if (resultado.mensaje == null) {
                resultado.mensaje = mensaje;
            }
        }
        return resultados;
    }
}
