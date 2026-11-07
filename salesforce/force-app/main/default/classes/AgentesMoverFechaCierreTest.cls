/**
 * Pruebas de `AgentesMoverFechaCierre`.
 *
 * Cubre el caso válido, cada regla rota a propósito (regla T2), un lote de
 * `AgentesTestDataFactory.CANTIDAD_MASIVA` oportunidades y dos usuarios con permisos
 * mínimos (`System.runAs`): uno que no lee oportunidades y otro que solo las lee. En los
 * casos que deben fallar se comprueba también que la fecha no cambió.
 */
@IsTest
private class AgentesMoverFechaCierreTest {

    @TestSetup
    static void crearDatos() {
        AgentesTestDataFactory.crearEscenario(AgentesTestDataFactory.CANTIDAD_MASIVA);
    }

    private static AgentesMoverFechaCierre.Solicitud solicitud(Id oportunidadId, Date fecha) {
        AgentesMoverFechaCierre.Solicitud solicitud = new AgentesMoverFechaCierre.Solicitud();
        solicitud.oportunidadId = oportunidadId;
        solicitud.nuevaFechaCierre = fecha;
        return solicitud;
    }

    private static Date fechaCierre(Id oportunidadId) {
        return [SELECT CloseDate FROM Opportunity WHERE Id = :oportunidadId].CloseDate;
    }

    private static Date fechaInicial() {
        return Date.today().addDays(-AgentesTestDataFactory.DIAS_VENCIDA);
    }

    @IsTest
    static void mueveLaFechaYDevuelveLaAnterior() {
        Id abiertaId = AgentesTestDataFactory.primeraAbierta().Id;
        Date nueva = Date.today().addDays(14);
        Test.startTest();
        List<AgentesMoverFechaCierre.Resultado> resultados = AgentesMoverFechaCierre.ejecutar(
            new List<AgentesMoverFechaCierre.Solicitud>{ solicitud(abiertaId, nueva) }
        );
        Test.stopTest();
        Assert.isTrue(resultados[0].exito, resultados[0].mensaje);
        Assert.areEqual(fechaInicial(), resultados[0].fechaAnterior);
        Assert.areEqual(nueva, resultados[0].fechaNueva);
        Assert.areEqual(nueva, fechaCierre(abiertaId));
    }

    @IsTest
    static void aceptaLaFechaDeHoy() {
        Id abiertaId = AgentesTestDataFactory.primeraAbierta().Id;
        Test.startTest();
        List<AgentesMoverFechaCierre.Resultado> resultados = AgentesMoverFechaCierre.ejecutar(
            new List<AgentesMoverFechaCierre.Solicitud>{ solicitud(abiertaId, Date.today()) }
        );
        Test.stopTest();
        Assert.isTrue(resultados[0].exito, resultados[0].mensaje);
        Assert.areEqual(Date.today(), fechaCierre(abiertaId));
    }

    @IsTest
    static void rechazaFechaPasadaYFechaNula() {
        Id abiertaId = AgentesTestDataFactory.primeraAbierta().Id;
        Test.startTest();
        List<AgentesMoverFechaCierre.Resultado> resultados = AgentesMoverFechaCierre.ejecutar(
            new List<AgentesMoverFechaCierre.Solicitud>{
                solicitud(abiertaId, Date.today().addDays(-1)),
                solicitud(abiertaId, null)
            }
        );
        Test.stopTest();
        Assert.isFalse(resultados[0].exito, 'Fecha pasada');
        Assert.isTrue(resultados[0].mensaje.contains('ya pasó'), resultados[0].mensaje);
        Assert.isFalse(resultados[1].exito, 'Sin fecha');
        Assert.isTrue(resultados[1].mensaje.contains('Falta'), resultados[1].mensaje);
        Assert.areEqual(fechaInicial(), fechaCierre(abiertaId));
    }

    @IsTest
    static void noTocaUnaOportunidadCerrada() {
        Opportunity cerrada = AgentesTestDataFactory.cerrada();
        Test.startTest();
        List<AgentesMoverFechaCierre.Resultado> resultados = AgentesMoverFechaCierre.ejecutar(
            new List<AgentesMoverFechaCierre.Solicitud>{ solicitud(cerrada.Id, Date.today().addDays(5)) }
        );
        Test.stopTest();
        Assert.isFalse(resultados[0].exito);
        Assert.isTrue(resultados[0].mensaje.contains('cerrada'), resultados[0].mensaje);
        Assert.isNull(resultados[0].fechaNueva);
        Assert.areEqual(cerrada.CloseDate, fechaCierre(cerrada.Id));
    }

    @IsTest
    static void aceptaSoloLaPrimeraSolicitudDeLaMismaOportunidad() {
        Id abiertaId = AgentesTestDataFactory.primeraAbierta().Id;
        Date primera = Date.today().addDays(7);
        Test.startTest();
        List<AgentesMoverFechaCierre.Resultado> resultados = AgentesMoverFechaCierre.ejecutar(
            new List<AgentesMoverFechaCierre.Solicitud>{
                solicitud(abiertaId, primera),
                solicitud(abiertaId, Date.today().addDays(30))
            }
        );
        Test.stopTest();
        Assert.isTrue(resultados[0].exito, resultados[0].mensaje);
        Assert.isFalse(resultados[1].exito, 'Id repetido');
        Assert.isTrue(resultados[1].mensaje.contains('más de una vez'), resultados[1].mensaje);
        Assert.areEqual(primera, fechaCierre(abiertaId));
    }

    @IsTest
    static void rechazaIdDeOtroObjetoIdNuloYSolicitudVacia() {
        Id cuentaId = AgentesTestDataFactory.cuenta().Id;
        Date nueva = Date.today().addDays(5);
        Test.startTest();
        List<AgentesMoverFechaCierre.Resultado> resultados = AgentesMoverFechaCierre.ejecutar(
            new List<AgentesMoverFechaCierre.Solicitud>{ solicitud(cuentaId, nueva), solicitud(null, nueva), null }
        );
        Test.stopTest();
        Assert.areEqual(3, resultados.size());
        Assert.isTrue(resultados[0].mensaje.contains('no es de una oportunidad'), resultados[0].mensaje);
        Assert.isTrue(resultados[1].mensaje.contains('Falta'), resultados[1].mensaje);
        Assert.areEqual('Solicitud vacía.', resultados[2].mensaje);
        for (AgentesMoverFechaCierre.Resultado resultado : resultados) {
            Assert.isFalse(resultado.exito, resultado.mensaje);
        }
    }

    @IsTest
    static void mueveUnLoteCompleto() {
        List<Opportunity> abiertas = AgentesTestDataFactory.abiertas();
        List<AgentesMoverFechaCierre.Solicitud> solicitudes = new List<AgentesMoverFechaCierre.Solicitud>();
        for (Integer i = 0; i < abiertas.size(); i++) {
            solicitudes.add(solicitud(abiertas[i].Id, Date.today().addDays(i)));
        }
        Test.startTest();
        List<AgentesMoverFechaCierre.Resultado> resultados = AgentesMoverFechaCierre.ejecutar(solicitudes);
        Test.stopTest();
        Assert.areEqual(AgentesTestDataFactory.CANTIDAD_MASIVA, resultados.size());
        for (Integer i = 0; i < resultados.size(); i++) {
            Assert.isTrue(resultados[i].exito, resultados[i].mensaje);
            Assert.areEqual(abiertas[i].Id, resultados[i].oportunidadId, 'El orden de los resultados es el de las solicitudes.');
        }
        List<Opportunity> guardadas = AgentesTestDataFactory.abiertas();
        for (Integer i = 0; i < guardadas.size(); i++) {
            Assert.areEqual(Date.today().addDays(i), guardadas[i].CloseDate);
        }
    }

    @IsTest
    static void usuarioQueNoLeeOportunidadesNoCambiaNada() {
        Id abiertaId = AgentesTestDataFactory.primeraAbierta().Id;
        User sinAcceso = AgentesTestDataFactory.usuario(AgentesTestDataFactory.APELLIDO_SIN_ACCESO);
        List<AgentesMoverFechaCierre.Resultado> resultados;
        Test.startTest();
        System.runAs(sinAcceso) {
            resultados = AgentesMoverFechaCierre.ejecutar(
                new List<AgentesMoverFechaCierre.Solicitud>{ solicitud(abiertaId, Date.today().addDays(5)) }
            );
        }
        Test.stopTest();
        Assert.isFalse(resultados[0].exito);
        Assert.isTrue(resultados[0].mensaje.contains('permisos del usuario'), resultados[0].mensaje);
        Assert.isNull(resultados[0].fechaNueva);
        Assert.areEqual(fechaInicial(), fechaCierre(abiertaId));
    }

    @IsTest
    static void usuarioDeSoloLecturaNoCambiaNada() {
        Id abiertaId = AgentesTestDataFactory.primeraAbierta().Id;
        User soloLectura = AgentesTestDataFactory.usuario(AgentesTestDataFactory.APELLIDO_SOLO_LECTURA);
        List<AgentesMoverFechaCierre.Resultado> resultados;
        Test.startTest();
        System.runAs(soloLectura) {
            resultados = AgentesMoverFechaCierre.ejecutar(
                new List<AgentesMoverFechaCierre.Solicitud>{ solicitud(abiertaId, Date.today().addDays(5)) }
            );
        }
        Test.stopTest();
        // Según la compartición de la org, no ve la oportunidad o no la puede editar: falla igual.
        Assert.isFalse(resultados[0].exito, resultados[0].mensaje);
        Assert.isTrue(String.isNotBlank(resultados[0].mensaje));
        Assert.isNull(resultados[0].fechaNueva);
        Assert.areEqual(fechaInicial(), fechaCierre(abiertaId));
    }
}
