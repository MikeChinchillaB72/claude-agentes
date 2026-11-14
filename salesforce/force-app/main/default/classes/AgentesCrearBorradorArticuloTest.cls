/**
 * Pruebas de `AgentesCrearBorradorArticulo`.
 *
 * Cubre el borrador creado desde un caso cerrado (sin publicar y ligado al caso), el caso abierto,
 * el caso que ya tiene artículo, el mismo caso dos veces en una llamada, cada valor inválido
 * (regla T2), el `UrlName`, un lote de `AgentesTestDataFactory.CANTIDAD_MASIVA` solicitudes con
 * cuatro consultas y un usuario sin acceso (`System.runAs`).
 *
 * Necesitan Lightning Knowledge activado y que el usuario que corre las pruebas sea Knowledge User.
 */
@IsTest
private class AgentesCrearBorradorArticuloTest {

    private static final String TITULO = 'PRUEBA Cambiar la dirección de envío';
    private static final String RESUMEN = 'Para cambiar la dirección de envío, entra en Mi cuenta > Direcciones.';

    @TestSetup
    static void crearDatos() {
        AgentesTestDataFactory.crearEscenarioServicio(AgentesTestDataFactory.CANTIDAD_MASIVA);
    }

    /** @return El primer idioma activo de Knowledge en la org, para no suponer ninguno. */
    private static String idioma() {
        return Knowledge__kav.Language.getDescribe().getPicklistValues()[0].getValue();
    }

    private static AgentesCrearBorradorArticulo.Solicitud solicitud(Id casoId, String titulo, String resumen, String idioma) {
        AgentesCrearBorradorArticulo.Solicitud solicitud = new AgentesCrearBorradorArticulo.Solicitud();
        solicitud.casoId = casoId;
        solicitud.titulo = titulo;
        solicitud.resumen = resumen;
        solicitud.idioma = idioma;
        return solicitud;
    }

    private static AgentesCrearBorradorArticulo.Solicitud valida(Id casoId) {
        return solicitud(casoId, TITULO, RESUMEN, idioma());
    }

    private static List<AgentesCrearBorradorArticulo.Resultado> crear(List<AgentesCrearBorradorArticulo.Solicitud> solicitudes) {
        return AgentesCrearBorradorArticulo.ejecutar(solicitudes);
    }

    /** Cierra los casos de prueba indicados y los devuelve. */
    private static List<Case> cerrar(List<Case> casos) {
        String cerrado = AgentesTestDataFactory.estadoCasoCerrado();
        List<Case> cambios = new List<Case>();
        for (Case caso : casos) {
            cambios.add(new Case(Id = caso.Id, Status = cerrado));
        }
        update cambios;
        return casos;
    }

    @IsTest
    static void creaUnBorradorLigadoAlCasoSinPublicarlo() {
        Case caso = cerrar(new List<Case>{ AgentesTestDataFactory.casos()[0] })[0];
        Test.startTest();
        List<AgentesCrearBorradorArticulo.Resultado> resultados = crear(
            new List<AgentesCrearBorradorArticulo.Solicitud>{ valida(caso.Id) }
        );
        Test.stopTest();
        AgentesCrearBorradorArticulo.Resultado resultado = resultados[0];
        Assert.isTrue(resultado.exito, resultado.mensaje);
        Assert.isNotNull(resultado.articuloId);
        Assert.isNotNull(resultado.numeroArticulo);
        Knowledge__kav articulo = [
            SELECT Title, Summary, Language, UrlName, SourceId, PublishStatus
            FROM Knowledge__kav WHERE Id = :resultado.articuloId
        ];
        Assert.areEqual('Draft', articulo.PublishStatus, 'Nunca publica.');
        Assert.areEqual(caso.Id, articulo.SourceId, 'Queda ligado al caso del que salió.');
        Assert.areEqual(TITULO, articulo.Title);
        Assert.areEqual(RESUMEN, articulo.Summary);
        Assert.areEqual(idioma(), articulo.Language);
        Assert.areEqual(resultado.nombreUrl, articulo.UrlName);
        Assert.isTrue(articulo.UrlName.endsWith('caso-' + caso.CaseNumber), articulo.UrlName);
    }

    @IsTest
    static void rechazaUnCasoAbierto() {
        Case caso = AgentesTestDataFactory.casos()[0];
        Test.startTest();
        List<AgentesCrearBorradorArticulo.Resultado> resultados = crear(
            new List<AgentesCrearBorradorArticulo.Solicitud>{ valida(caso.Id) }
        );
        Test.stopTest();
        Assert.isFalse(resultados[0].exito);
        Assert.isTrue(resultados[0].mensaje.contains('sigue abierto'), resultados[0].mensaje);
        Assert.areEqual(0, [SELECT COUNT() FROM Knowledge__kav WHERE PublishStatus = 'Draft' AND SourceId = :caso.Id]);
    }

    @IsTest
    static void noCreaUnSegundoArticuloParaElMismoCaso() {
        Case caso = cerrar(new List<Case>{ AgentesTestDataFactory.casos()[0] })[0];
        crear(new List<AgentesCrearBorradorArticulo.Solicitud>{ valida(caso.Id) });
        Test.startTest();
        List<AgentesCrearBorradorArticulo.Resultado> resultados = crear(
            new List<AgentesCrearBorradorArticulo.Solicitud>{ valida(caso.Id) }
        );
        Test.stopTest();
        Assert.isFalse(resultados[0].exito);
        Assert.isTrue(resultados[0].mensaje.contains('ya tiene el artículo'), resultados[0].mensaje);
        Assert.areEqual(1, [SELECT COUNT() FROM Knowledge__kav WHERE PublishStatus = 'Draft' AND SourceId = :caso.Id]);
    }

    @IsTest
    static void elMismoCasoDosVecesCreaUnSoloBorrador() {
        Case caso = cerrar(new List<Case>{ AgentesTestDataFactory.casos()[0] })[0];
        Test.startTest();
        List<AgentesCrearBorradorArticulo.Resultado> resultados = crear(
            new List<AgentesCrearBorradorArticulo.Solicitud>{ valida(caso.Id), valida(caso.Id) }
        );
        Test.stopTest();
        Assert.isTrue(resultados[0].exito, resultados[0].mensaje);
        Assert.isFalse(resultados[1].exito);
        Assert.isTrue(resultados[1].mensaje.contains('dos veces'), resultados[1].mensaje);
    }

    @IsTest
    static void rechazaValoresInvalidosSinConsultar() {
        Id cuentaId = AgentesTestDataFactory.cuenta().Id;
        Id casoId = AgentesTestDataFactory.casos()[0].Id;
        String largo = 'x'.repeat(Knowledge__kav.Summary.getDescribe().getLength() + 1);
        Test.startTest();
        List<AgentesCrearBorradorArticulo.Resultado> resultados = crear(
            new List<AgentesCrearBorradorArticulo.Solicitud>{
                solicitud(null, TITULO, RESUMEN, idioma()),
                solicitud(cuentaId, TITULO, RESUMEN, idioma()),
                solicitud(casoId, ' ', RESUMEN, idioma()),
                solicitud(casoId, TITULO, largo, idioma()),
                solicitud(casoId, TITULO, RESUMEN, 'xx_XX'),
                solicitud(casoId, TITULO, RESUMEN, null),
                null
            }
        );
        Integer consultas = Limits.getQueries();
        Test.stopTest();
        Assert.areEqual(0, consultas, 'Una solicitud inválida no consulta.');
        Assert.isTrue(resultados[0].mensaje.contains('Falta'), resultados[0].mensaje);
        Assert.isTrue(resultados[1].mensaje.contains('no es de un caso'), resultados[1].mensaje);
        Assert.isTrue(resultados[2].mensaje.contains('título'), resultados[2].mensaje);
        Assert.isTrue(resultados[3].mensaje.contains('resumen'), resultados[3].mensaje);
        Assert.isTrue(resultados[4].mensaje.contains('idioma'), resultados[4].mensaje);
        Assert.isTrue(resultados[5].mensaje.contains('idioma'), resultados[5].mensaje);
        Assert.areEqual('Solicitud vacía.', resultados[6].mensaje);
        for (AgentesCrearBorradorArticulo.Resultado resultado : resultados) {
            Assert.isFalse(resultado.exito, resultado.mensaje);
            Assert.isNull(resultado.articuloId);
        }
    }

    @IsTest
    static void elNombreDeUrlQuitaAcentosYSimbolosYCabeEnElCampo() {
        Assert.areEqual(
            'cambiar-la-direccion-de-envio-caso-00001032',
            AgentesCrearBorradorArticulo.nombreUrl('  ¿Cambiar la DIRECCIÓN de envío?  ', '00001032')
        );
        Assert.areEqual('caso-00001032', AgentesCrearBorradorArticulo.nombreUrl('¿¡!?', '00001032'));
        String largo = AgentesCrearBorradorArticulo.nombreUrl('a'.repeat(400), '00001032');
        Assert.isTrue(largo.length() <= Knowledge__kav.UrlName.getDescribe().getLength(), String.valueOf(largo.length()));
        Assert.isTrue(largo.endsWith('-caso-00001032'), largo);
    }

    @IsTest
    static void unLoteCompletoUsaCuatroConsultas() {
        List<Case> casos = cerrar(AgentesTestDataFactory.casos());
        List<AgentesCrearBorradorArticulo.Solicitud> solicitudes = new List<AgentesCrearBorradorArticulo.Solicitud>();
        for (Case caso : casos) {
            solicitudes.add(valida(caso.Id));
        }
        Test.startTest();
        List<AgentesCrearBorradorArticulo.Resultado> resultados = crear(solicitudes);
        Integer consultas = Limits.getQueries();
        Test.stopTest();
        Assert.areEqual(4, consultas, 'Casos, borradores, publicados y los artículos creados.');
        Assert.areEqual(AgentesTestDataFactory.CANTIDAD_MASIVA, resultados.size());
        for (Integer i = 0; i < resultados.size(); i++) {
            Assert.isTrue(resultados[i].exito, resultados[i].mensaje);
            Assert.areEqual(casos[i].Id, resultados[i].casoId, 'El orden de los resultados es el de las solicitudes.');
        }
    }

    @IsTest
    static void usuarioSinAccesoRecibeElMotivoYNoCreaNada() {
        Case caso = cerrar(new List<Case>{ AgentesTestDataFactory.casos()[0] })[0];
        User sinAcceso = AgentesTestDataFactory.usuario(AgentesTestDataFactory.APELLIDO_SIN_ACCESO);
        List<AgentesCrearBorradorArticulo.Resultado> resultados;
        Test.startTest();
        System.runAs(sinAcceso) {
            resultados = crear(new List<AgentesCrearBorradorArticulo.Solicitud>{ valida(caso.Id) });
        }
        Test.stopTest();
        Assert.isFalse(resultados[0].exito);
        Assert.isTrue(String.isNotBlank(resultados[0].mensaje));
        Assert.isNull(resultados[0].articuloId);
        Assert.areEqual(0, [SELECT COUNT() FROM Knowledge__kav WHERE PublishStatus = 'Draft' AND SourceId = :caso.Id]);
    }
}
