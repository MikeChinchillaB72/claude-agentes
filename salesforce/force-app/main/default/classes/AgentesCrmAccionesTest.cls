/**
 * Pruebas de `AgentesCrmAcciones`, las reglas comunes de las acciones.
 *
 * Cada regla se prueba en su caso válido y rota a propósito (regla T2). Los datos vienen
 * de `AgentesTestDataFactory`. Las acciones tienen cada una su propia clase de prueba.
 */
@IsTest
private class AgentesCrmAccionesTest {

    @TestSetup
    static void crearDatos() {
        AgentesTestDataFactory.crearEscenario(AgentesTestDataFactory.CANTIDAD_MASIVA);
    }

    // ── leerOportunidades ───────────────────────────────────────────────────

    @IsTest
    static void leerOportunidadesDevuelveLaPedidaConSusCampos() {
        Opportunity abierta = AgentesTestDataFactory.primeraAbierta();
        Test.startTest();
        Map<Id, Opportunity> encontradas = AgentesCrmAcciones.leerOportunidades(
            new Set<Id>{ abierta.Id },
            new List<String>{ AgentesCrmAcciones.CAMPO_PROXIMO_PASO, AgentesCrmAcciones.CAMPO_FECHA_CIERRE }
        );
        Test.stopTest();
        Assert.areEqual(1, encontradas.size());
        Assert.areEqual(AgentesTestDataFactory.PASO_INICIAL, encontradas.get(abierta.Id).NextStep);
        Assert.areEqual(Date.today().addDays(-AgentesTestDataFactory.DIAS_VENCIDA), encontradas.get(abierta.Id).CloseDate);
        Assert.isFalse(encontradas.get(abierta.Id).IsClosed);
    }

    @IsTest
    static void leerOportunidadesIgnoraNulosEIdsDeOtroObjeto() {
        Id cuentaId = AgentesTestDataFactory.cuenta().Id;
        Test.startTest();
        Map<Id, Opportunity> encontradas = AgentesCrmAcciones.leerOportunidades(
            new Set<Id>{ null, cuentaId }, new List<String>()
        );
        Integer consultas = Limits.getQueries();
        Test.stopTest();
        Assert.isTrue(encontradas.isEmpty());
        Assert.areEqual(0, consultas, 'Sin Ids de oportunidad válidos no se consulta.');
    }

    @IsTest
    static void leerOportunidadesRechazaCampoFueraDeLaLista() {
        Opportunity abierta = AgentesTestDataFactory.primeraAbierta();
        Test.startTest();
        try {
            AgentesCrmAcciones.leerOportunidades(new Set<Id>{ abierta.Id }, new List<String>{ 'Amount' });
            Assert.fail('Debió rechazar un campo fuera de la lista.');
        } catch (IllegalArgumentException e) {
            Assert.isTrue(e.getMessage().contains('Amount'), e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void leerOportunidadesMasivoUsaUnaSolaConsulta() {
        Set<Id> ids = AgentesTestDataFactory.ids(AgentesTestDataFactory.abiertas());
        Test.startTest();
        Map<Id, Opportunity> encontradas = AgentesCrmAcciones.leerOportunidades(
            ids, new List<String>{ AgentesCrmAcciones.CAMPO_PROXIMO_PASO }
        );
        Integer consultas = Limits.getQueries();
        Test.stopTest();
        Assert.areEqual(AgentesTestDataFactory.CANTIDAD_MASIVA, encontradas.size());
        Assert.areEqual(ids, encontradas.keySet());
        Assert.areEqual(1, consultas);
    }

    @IsTest
    static void leerOportunidadesSinPermisoDelUsuarioLanzaQueryException() {
        Id abiertaId = AgentesTestDataFactory.primeraAbierta().Id;
        User sinAcceso = AgentesTestDataFactory.usuario(AgentesTestDataFactory.APELLIDO_SIN_ACCESO);
        Test.startTest();
        System.runAs(sinAcceso) {
            try {
                AgentesCrmAcciones.leerOportunidades(new Set<Id>{ abiertaId }, new List<String>());
                Assert.fail('Un usuario sin permiso de lectura no debe leer oportunidades.');
            } catch (QueryException e) {
                Assert.isNotNull(e.getMessage());
            }
        }
        Test.stopTest();
    }

    // ── validarOportunidadAbierta ───────────────────────────────────────────

    @IsTest
    static void validarOportunidadAbiertaAceptaUnaAbierta() {
        Opportunity abierta = AgentesTestDataFactory.primeraAbierta();
        Test.startTest();
        Map<Id, Opportunity> encontradas = AgentesCrmAcciones.leerOportunidades(new Set<Id>{ abierta.Id }, new List<String>());
        String error = AgentesCrmAcciones.validarOportunidadAbierta(abierta.Id, encontradas);
        Test.stopTest();
        Assert.isNull(error);
    }

    @IsTest
    static void validarOportunidadAbiertaRechazaNuloOtroObjetoNoEncontradaYCerrada() {
        Id cerradaId = AgentesTestDataFactory.cerrada().Id;
        Id abiertaId = AgentesTestDataFactory.primeraAbierta().Id;
        Id cuentaId = AgentesTestDataFactory.cuenta().Id;
        Test.startTest();
        Map<Id, Opportunity> soloCerrada = AgentesCrmAcciones.leerOportunidades(new Set<Id>{ cerradaId }, new List<String>());
        String sinId = AgentesCrmAcciones.validarOportunidadAbierta(null, soloCerrada);
        String otroObjeto = AgentesCrmAcciones.validarOportunidadAbierta(cuentaId, soloCerrada);
        String noEncontrada = AgentesCrmAcciones.validarOportunidadAbierta(abiertaId, soloCerrada);
        String cerrada = AgentesCrmAcciones.validarOportunidadAbierta(cerradaId, soloCerrada);
        Test.stopTest();
        Assert.isTrue(sinId.contains('Falta'), sinId);
        Assert.isTrue(otroObjeto.contains('no es de una oportunidad'), otroObjeto);
        Assert.isTrue(noEncontrada.contains('no existe o el usuario no tiene acceso'), noEncontrada);
        Assert.isTrue(cerrada.contains('cerrada'), cerrada);
    }

    // ── reservarUnaVez ──────────────────────────────────────────────────────

    @IsTest
    static void reservarUnaVezSoloAceptaLaPrimera() {
        Id abiertaId = AgentesTestDataFactory.primeraAbierta().Id;
        Set<Id> yaUsadas = new Set<Id>();
        Test.startTest();
        String primera = AgentesCrmAcciones.reservarUnaVez(abiertaId, yaUsadas);
        String segunda = AgentesCrmAcciones.reservarUnaVez(abiertaId, yaUsadas);
        Test.stopTest();
        Assert.isNull(primera);
        Assert.isTrue(segunda.contains('más de una vez'), segunda);
        Assert.areEqual(new Set<Id>{ abiertaId }, yaUsadas);
    }

    // ── validarFechaNoPasada ────────────────────────────────────────────────

    @IsTest
    static void validarFechaNoPasadaAceptaHoyYPosterior() {
        Test.startTest();
        String hoy = AgentesCrmAcciones.validarFechaNoPasada(Date.today(), 'La fecha');
        String manana = AgentesCrmAcciones.validarFechaNoPasada(Date.today().addDays(1), 'La fecha');
        Test.stopTest();
        Assert.isNull(hoy);
        Assert.isNull(manana);
    }

    @IsTest
    static void validarFechaNoPasadaRechazaNulaYPasada() {
        Date ayer = Date.today().addDays(-1);
        Test.startTest();
        String nula = AgentesCrmAcciones.validarFechaNoPasada(null, 'La fecha');
        String pasada = AgentesCrmAcciones.validarFechaNoPasada(ayer, 'La fecha');
        Test.stopTest();
        Assert.areEqual('Falta la fecha.', nula);
        Assert.isTrue(pasada.contains(String.valueOf(ayer)) && pasada.contains('ya pasó'), pasada);
    }

    // ── validarTexto ────────────────────────────────────────────────────────

    @IsTest
    static void validarTextoAceptaElMaximoSinContarEspacios() {
        Test.startTest();
        String error = AgentesCrmAcciones.validarTexto('  ' + 'x'.repeat(10) + '  ', 'El texto', 10);
        Test.stopTest();
        Assert.isNull(error);
    }

    @IsTest
    static void validarTextoRechazaVacioYLargo() {
        Test.startTest();
        String nulo = AgentesCrmAcciones.validarTexto(null, 'El texto', 10);
        String blanco = AgentesCrmAcciones.validarTexto('   ', 'El texto', 10);
        String largo = AgentesCrmAcciones.validarTexto('x'.repeat(11), 'El texto', 10);
        Test.stopTest();
        Assert.areEqual('El texto no puede estar vacío.', nulo);
        Assert.areEqual('El texto no puede estar vacío.', blanco);
        Assert.areEqual('El texto tiene 11 caracteres; el máximo es 10.', largo);
    }

    // ── resumirErrores ──────────────────────────────────────────────────────

    @IsTest
    static void resumirErroresJuntaLosMensajesDelDml() {
        Test.startTest();
        // Una cuenta sin nombre falla con un error real de Salesforce.
        Database.SaveResult fallido = Database.insert(new Account(), false);
        String resumen = AgentesCrmAcciones.resumirErrores(fallido.getErrors());
        String vacio = AgentesCrmAcciones.resumirErrores(new List<Database.Error>());
        Test.stopTest();
        Assert.isFalse(fallido.isSuccess());
        Assert.areEqual(fallido.getErrors()[0].getMessage(), resumen.split(' \\| ')[0]);
        Assert.areEqual(fallido.getErrors().size(), resumen.split(' \\| ').size());
        Assert.areEqual('', vacio);
    }
}
