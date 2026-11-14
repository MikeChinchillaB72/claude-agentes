/**
 * Pruebas de `AgentesLeerContextoCaso`.
 *
 * Cubre los datos del caso, el orden y el recorte de comentarios y de otros casos de la cuenta
 * (sin el caso pedido), un caso sin cuenta ni comentarios, un caso cerrado, cada valor inválido
 * (regla T2), un lote de `AgentesTestDataFactory.CANTIDAD_MASIVA` solicitudes en dos consultas y
 * dos usuarios con permisos mínimos (`System.runAs`).
 */
@IsTest
private class AgentesLeerContextoCasoTest {

    /** Valor inicial de `casos_recientes` en los criterios de `atender-con-contexto`. */
    private static final Integer MAXIMO = 5;

    @TestSetup
    static void crearDatos() {
        AgentesTestDataFactory.crearEscenarioServicio(AgentesTestDataFactory.CANTIDAD_MASIVA);
    }

    private static AgentesLeerContextoCaso.Solicitud solicitud(Id casoId, Integer maximoComentarios, Integer maximoOtros) {
        AgentesLeerContextoCaso.Solicitud solicitud = new AgentesLeerContextoCaso.Solicitud();
        solicitud.casoId = casoId;
        solicitud.maximoComentarios = maximoComentarios;
        solicitud.maximoOtrosCasos = maximoOtros;
        return solicitud;
    }

    private static List<AgentesLeerContextoCaso.Resultado> leer(List<AgentesLeerContextoCaso.Solicitud> solicitudes) {
        return AgentesLeerContextoCaso.ejecutar(solicitudes);
    }

    /** Crea tres comentarios en el caso: hace 1, 5 y 10 días. */
    private static void crearComentarios(Id casoId) {
        List<CaseComment> comentarios = new List<CaseComment>{
            new CaseComment(ParentId = casoId, CommentBody = 'PRUEBA-Comentario-1'),
            new CaseComment(ParentId = casoId, CommentBody = 'PRUEBA-Comentario-5', IsPublished = true),
            new CaseComment(ParentId = casoId, CommentBody = 'PRUEBA-Comentario-10')
        };
        insert comentarios;
        Test.setCreatedDate(comentarios[0].Id, Datetime.now().addDays(-1));
        Test.setCreatedDate(comentarios[1].Id, Datetime.now().addDays(-5));
        Test.setCreatedDate(comentarios[2].Id, Datetime.now().addDays(-10));
    }

    /**
     * Ordena las fechas de creación: el caso 0 es el más reciente (hace una hora), luego los
     * casos 1, 2 y 3 (hace 1, 2 y 3 días) y el resto, hace 30 días.
     */
    private static List<Case> ordenarFechas() {
        List<Case> casos = AgentesTestDataFactory.casos();
        for (Integer i = 4; i < casos.size(); i++) {
            Test.setCreatedDate(casos[i].Id, Datetime.now().addDays(-30));
        }
        Test.setCreatedDate(casos[0].Id, Datetime.now().addHours(-1));
        Test.setCreatedDate(casos[1].Id, Datetime.now().addDays(-1));
        Test.setCreatedDate(casos[2].Id, Datetime.now().addDays(-2));
        Test.setCreatedDate(casos[3].Id, Datetime.now().addDays(-3));
        return casos;
    }

    @IsTest
    static void devuelveElCasoConSuContextoRecortado() {
        List<Case> casos = ordenarFechas();
        crearComentarios(casos[0].Id);
        Test.startTest();
        List<AgentesLeerContextoCaso.Resultado> resultados = leer(
            new List<AgentesLeerContextoCaso.Solicitud>{ solicitud(casos[0].Id, 2, 2) }
        );
        Test.stopTest();
        AgentesLeerContextoCaso.Resultado resultado = resultados[0];
        Assert.isTrue(resultado.exito, resultado.mensaje);
        Assert.areEqual(casos[0].Subject, resultado.asunto);
        Assert.areEqual(casos[0].CaseNumber, resultado.numeroCaso);
        Assert.areEqual(AgentesTestDataFactory.NOMBRE_CUENTA, resultado.nombreCuenta);
        Assert.areEqual(AgentesTestDataFactory.APELLIDO_CONTACTO, resultado.nombreContacto);
        Assert.isFalse(resultado.cerrado);
        Assert.areEqual(2, resultado.comentarios.size(), 'Se recorta al máximo pedido.');
        Assert.areEqual('PRUEBA-Comentario-1', resultado.comentarios[0].CommentBody, 'Primero el más reciente.');
        Assert.areEqual('PRUEBA-Comentario-5', resultado.comentarios[1].CommentBody);
        Assert.isTrue(resultado.comentarios[1].IsPublished, 'Dice si el comentario es público.');
        Assert.areEqual(2, resultado.otrosCasos.size(), 'Se recorta al máximo pedido.');
        Assert.areEqual(casos[1].Id, resultado.otrosCasos[0].Id, 'Sin el caso pedido, aunque sea el más reciente.');
        Assert.areEqual(casos[2].Id, resultado.otrosCasos[1].Id);
    }

    @IsTest
    static void cadaSolicitudRespetaSusPropiosMaximos() {
        List<Case> casos = ordenarFechas();
        crearComentarios(casos[0].Id);
        Test.startTest();
        List<AgentesLeerContextoCaso.Resultado> resultados = leer(
            new List<AgentesLeerContextoCaso.Solicitud>{
                solicitud(casos[0].Id, 1, 1),
                solicitud(casos[0].Id, MAXIMO, 3)
            }
        );
        Test.stopTest();
        Assert.areEqual(1, resultados[0].comentarios.size());
        Assert.areEqual(1, resultados[0].otrosCasos.size());
        Assert.areEqual(3, resultados[1].comentarios.size(), 'Hay 3 comentarios y el máximo es mayor.');
        Assert.areEqual(3, resultados[1].otrosCasos.size());
        Assert.areEqual(casos[3].Id, resultados[1].otrosCasos[2].Id);
    }

    @IsTest
    static void casoSinCuentaNiComentariosEsExitoVacio() {
        Case suelto = AgentesTestDataFactory.crearCasos(null, null, 1)[0];
        Test.startTest();
        List<AgentesLeerContextoCaso.Resultado> resultados = leer(
            new List<AgentesLeerContextoCaso.Solicitud>{ solicitud(suelto.Id, MAXIMO, MAXIMO) }
        );
        Integer consultas = Limits.getQueries();
        Test.stopTest();
        Assert.isTrue(resultados[0].exito, resultados[0].mensaje);
        Assert.isTrue(resultados[0].comentarios.isEmpty());
        Assert.isTrue(resultados[0].otrosCasos.isEmpty());
        Assert.isNull(resultados[0].nombreCuenta);
        Assert.isNull(resultados[0].nombreContacto);
        Assert.isTrue(resultados[0].mensaje.contains('no tiene cuenta'), resultados[0].mensaje);
        Assert.areEqual(1, consultas, 'Sin cuenta no hace la segunda consulta.');
    }

    @IsTest
    static void leeTambienUnCasoCerrado() {
        Case caso = AgentesTestDataFactory.casos()[0];
        update new Case(Id = caso.Id, Status = AgentesTestDataFactory.estadoCasoCerrado());
        Test.startTest();
        List<AgentesLeerContextoCaso.Resultado> resultados = leer(
            new List<AgentesLeerContextoCaso.Solicitud>{ solicitud(caso.Id, MAXIMO, MAXIMO) }
        );
        Test.stopTest();
        Assert.isTrue(resultados[0].exito, 'Leer no modifica, así que un caso cerrado se puede leer.');
        Assert.isTrue(resultados[0].cerrado, 'Avisa de que está cerrado.');
    }

    @IsTest
    static void rechazaValoresInvalidosSinConsultar() {
        Id cuentaId = AgentesTestDataFactory.cuenta().Id;
        Id casoId = AgentesTestDataFactory.casos()[0].Id;
        Test.startTest();
        List<AgentesLeerContextoCaso.Resultado> resultados = leer(
            new List<AgentesLeerContextoCaso.Solicitud>{
                solicitud(null, MAXIMO, MAXIMO),
                solicitud(cuentaId, MAXIMO, MAXIMO),
                solicitud(casoId, 0, MAXIMO),
                solicitud(casoId, null, MAXIMO),
                solicitud(casoId, MAXIMO, 0),
                solicitud(casoId, MAXIMO, null),
                null
            }
        );
        Integer consultas = Limits.getQueries();
        Test.stopTest();
        Assert.areEqual(0, consultas, 'Una solicitud inválida no consulta.');
        Assert.isTrue(resultados[0].mensaje.contains('Falta'), resultados[0].mensaje);
        Assert.isTrue(resultados[1].mensaje.contains('no es de un caso'), resultados[1].mensaje);
        Assert.isTrue(resultados[2].mensaje.contains('comentarios'), resultados[2].mensaje);
        Assert.isTrue(resultados[3].mensaje.contains('comentarios'), resultados[3].mensaje);
        Assert.isTrue(resultados[4].mensaje.contains('otros casos'), resultados[4].mensaje);
        Assert.isTrue(resultados[5].mensaje.contains('otros casos'), resultados[5].mensaje);
        Assert.areEqual('Solicitud vacía.', resultados[6].mensaje);
        for (AgentesLeerContextoCaso.Resultado resultado : resultados) {
            Assert.isFalse(resultado.exito, resultado.mensaje);
            Assert.isTrue(resultado.comentarios.isEmpty());
            Assert.isTrue(resultado.otrosCasos.isEmpty());
        }
    }

    @IsTest
    static void unLoteCompletoUsaDosConsultas() {
        List<Case> casos = AgentesTestDataFactory.casos();
        crearComentarios(casos[0].Id);
        List<AgentesLeerContextoCaso.Solicitud> solicitudes = new List<AgentesLeerContextoCaso.Solicitud>();
        for (Case caso : casos) {
            solicitudes.add(solicitud(caso.Id, MAXIMO, MAXIMO));
        }
        Test.startTest();
        List<AgentesLeerContextoCaso.Resultado> resultados = leer(solicitudes);
        Integer consultas = Limits.getQueries();
        Test.stopTest();
        Assert.areEqual(2, consultas, 'Una consulta de casos y una de cuentas.');
        Assert.areEqual(AgentesTestDataFactory.CANTIDAD_MASIVA, resultados.size());
        for (Integer i = 0; i < resultados.size(); i++) {
            Assert.isTrue(resultados[i].exito, resultados[i].mensaje);
            Assert.areEqual(casos[i].Id, resultados[i].casoId, 'El orden de los resultados es el de las solicitudes.');
            Assert.areEqual(MAXIMO, resultados[i].otrosCasos.size());
            for (Case otro : resultados[i].otrosCasos) {
                Assert.areNotEqual(casos[i].Id, otro.Id, 'Nunca devuelve el caso pedido como otro caso.');
            }
        }
        Assert.areEqual(3, resultados[0].comentarios.size());
    }

    @IsTest
    static void usuarioQueNoLeeCasosRecibeElMotivo() {
        Id casoId = AgentesTestDataFactory.casos()[0].Id;
        User sinAcceso = AgentesTestDataFactory.usuario(AgentesTestDataFactory.APELLIDO_SIN_ACCESO);
        List<AgentesLeerContextoCaso.Resultado> resultados;
        Test.startTest();
        System.runAs(sinAcceso) {
            resultados = leer(new List<AgentesLeerContextoCaso.Solicitud>{ solicitud(casoId, MAXIMO, MAXIMO) });
        }
        Test.stopTest();
        Assert.isFalse(resultados[0].exito);
        Assert.isTrue(resultados[0].mensaje.contains('permisos del usuario'), resultados[0].mensaje);
        Assert.isNull(resultados[0].asunto, 'No devuelve nada del caso.');
    }

    @IsTest
    static void usuarioDeSoloLecturaNoRompeNiDevuelveDeMas() {
        Id casoId = AgentesTestDataFactory.casos()[0].Id;
        User soloLectura = AgentesTestDataFactory.usuario(AgentesTestDataFactory.APELLIDO_SOLO_LECTURA);
        List<AgentesLeerContextoCaso.Resultado> resultados;
        Test.startTest();
        System.runAs(soloLectura) {
            resultados = leer(new List<AgentesLeerContextoCaso.Solicitud>{ solicitud(casoId, MAXIMO, MAXIMO) });
        }
        Test.stopTest();
        // Según la compartición y los permisos de campo de la org, lee lo que puede ver o falla
        // con el motivo; nunca devuelve más casos de los pedidos ni lanza una excepción.
        Assert.isTrue(String.isNotBlank(resultados[0].mensaje));
        Assert.isTrue(resultados[0].otrosCasos.size() <= MAXIMO);
        if (!resultados[0].exito) {
            Assert.isTrue(resultados[0].otrosCasos.isEmpty());
            Assert.isNull(resultados[0].asunto);
        }
    }
}
