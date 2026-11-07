/**
 * Pruebas de `AgentesActualizarProximoPaso`.
 *
 * Cubre el caso válido, cada regla rota a propósito (regla T2), un lote de
 * `AgentesTestDataFactory.CANTIDAD_MASIVA` oportunidades y dos usuarios con permisos
 * mínimos (`System.runAs`): uno que no lee oportunidades y otro que solo las lee. En los
 * casos que deben fallar se comprueba también que la oportunidad no cambió.
 */
@IsTest
private class AgentesActualizarProximoPasoTest {

    @TestSetup
    static void crearDatos() {
        AgentesTestDataFactory.crearEscenario(AgentesTestDataFactory.CANTIDAD_MASIVA);
    }

    private static AgentesActualizarProximoPaso.Solicitud solicitud(Id oportunidadId, String texto) {
        AgentesActualizarProximoPaso.Solicitud solicitud = new AgentesActualizarProximoPaso.Solicitud();
        solicitud.oportunidadId = oportunidadId;
        solicitud.proximoPaso = texto;
        return solicitud;
    }

    private static String proximoPaso(Id oportunidadId) {
        return [SELECT NextStep FROM Opportunity WHERE Id = :oportunidadId].NextStep;
    }

    @IsTest
    static void guardaElTextoSinEspaciosYDevuelveElAnterior() {
        Id abiertaId = AgentesTestDataFactory.primeraAbierta().Id;
        Test.startTest();
        List<AgentesActualizarProximoPaso.Resultado> resultados = AgentesActualizarProximoPaso.ejecutar(
            new List<AgentesActualizarProximoPaso.Solicitud>{ solicitud(abiertaId, '  Enviar propuesta  ') }
        );
        Test.stopTest();
        Assert.isTrue(resultados[0].exito, resultados[0].mensaje);
        Assert.areEqual(abiertaId, resultados[0].oportunidadId);
        Assert.areEqual(AgentesTestDataFactory.PASO_INICIAL, resultados[0].valorAnterior);
        Assert.areEqual('Enviar propuesta', resultados[0].valorNuevo);
        Assert.areEqual('Enviar propuesta', proximoPaso(abiertaId));
    }

    @IsTest
    static void noTocaUnaOportunidadCerrada() {
        Id cerradaId = AgentesTestDataFactory.cerrada().Id;
        Test.startTest();
        List<AgentesActualizarProximoPaso.Resultado> resultados = AgentesActualizarProximoPaso.ejecutar(
            new List<AgentesActualizarProximoPaso.Solicitud>{ solicitud(cerradaId, 'Algo') }
        );
        Test.stopTest();
        Assert.isFalse(resultados[0].exito);
        Assert.isTrue(resultados[0].mensaje.contains('cerrada'), resultados[0].mensaje);
        Assert.isNull(resultados[0].valorNuevo);
        Assert.isNull(proximoPaso(cerradaId));
    }

    @IsTest
    static void rechazaTextoVacioYLargoSinBloquearLaValida() {
        Id abiertaId = AgentesTestDataFactory.primeraAbierta().Id;
        Integer largoMaximo = Opportunity.NextStep.getDescribe().getLength();
        Test.startTest();
        List<AgentesActualizarProximoPaso.Resultado> resultados = AgentesActualizarProximoPaso.ejecutar(
            new List<AgentesActualizarProximoPaso.Solicitud>{
                solicitud(abiertaId, '   '),
                solicitud(abiertaId, 'x'.repeat(largoMaximo + 1)),
                solicitud(abiertaId, 'Válido')
            }
        );
        Test.stopTest();
        Assert.isFalse(resultados[0].exito, 'Texto vacío');
        Assert.isTrue(resultados[0].mensaje.contains('vacío'), resultados[0].mensaje);
        Assert.isFalse(resultados[1].exito, 'Texto largo');
        Assert.isTrue(resultados[1].mensaje.contains(String.valueOf(largoMaximo)), resultados[1].mensaje);
        Assert.isTrue(resultados[2].exito, resultados[2].mensaje);
        Assert.areEqual('Válido', proximoPaso(abiertaId));
    }

    @IsTest
    static void aceptaSoloLaPrimeraSolicitudDeLaMismaOportunidad() {
        Id abiertaId = AgentesTestDataFactory.primeraAbierta().Id;
        Test.startTest();
        List<AgentesActualizarProximoPaso.Resultado> resultados = AgentesActualizarProximoPaso.ejecutar(
            new List<AgentesActualizarProximoPaso.Solicitud>{
                solicitud(abiertaId, 'Primero'),
                solicitud(abiertaId, 'Repetido')
            }
        );
        Test.stopTest();
        Assert.isTrue(resultados[0].exito, resultados[0].mensaje);
        Assert.isFalse(resultados[1].exito, 'Id repetido');
        Assert.isTrue(resultados[1].mensaje.contains('más de una vez'), resultados[1].mensaje);
        Assert.areEqual('Primero', proximoPaso(abiertaId));
    }

    @IsTest
    static void rechazaIdDeOtroObjetoIdNuloYSolicitudVacia() {
        Id cuentaId = AgentesTestDataFactory.cuenta().Id;
        Test.startTest();
        List<AgentesActualizarProximoPaso.Resultado> resultados = AgentesActualizarProximoPaso.ejecutar(
            new List<AgentesActualizarProximoPaso.Solicitud>{
                solicitud(cuentaId, 'Algo'),
                solicitud(null, 'Algo'),
                null
            }
        );
        Test.stopTest();
        Assert.areEqual(3, resultados.size());
        Assert.isTrue(resultados[0].mensaje.contains('no es de una oportunidad'), resultados[0].mensaje);
        Assert.isTrue(resultados[1].mensaje.contains('Falta'), resultados[1].mensaje);
        Assert.areEqual('Solicitud vacía.', resultados[2].mensaje);
        for (AgentesActualizarProximoPaso.Resultado resultado : resultados) {
            Assert.isFalse(resultado.exito, resultado.mensaje);
        }
    }

    @IsTest
    static void actualizaUnLoteCompleto() {
        List<Opportunity> abiertas = AgentesTestDataFactory.abiertas();
        List<AgentesActualizarProximoPaso.Solicitud> solicitudes = new List<AgentesActualizarProximoPaso.Solicitud>();
        for (Opportunity abierta : abiertas) {
            solicitudes.add(solicitud(abierta.Id, 'Paso de ' + abierta.Name));
        }
        Test.startTest();
        List<AgentesActualizarProximoPaso.Resultado> resultados = AgentesActualizarProximoPaso.ejecutar(solicitudes);
        Test.stopTest();
        Assert.areEqual(AgentesTestDataFactory.CANTIDAD_MASIVA, resultados.size());
        for (Integer i = 0; i < resultados.size(); i++) {
            Assert.isTrue(resultados[i].exito, resultados[i].mensaje);
            Assert.areEqual(abiertas[i].Id, resultados[i].oportunidadId, 'El orden de los resultados es el de las solicitudes.');
        }
        for (Opportunity guardada : AgentesTestDataFactory.abiertas()) {
            Assert.areEqual('Paso de ' + guardada.Name, guardada.NextStep);
        }
    }

    @IsTest
    static void usuarioQueNoLeeOportunidadesNoCambiaNada() {
        Id abiertaId = AgentesTestDataFactory.primeraAbierta().Id;
        User sinAcceso = AgentesTestDataFactory.usuario(AgentesTestDataFactory.APELLIDO_SIN_ACCESO);
        List<AgentesActualizarProximoPaso.Resultado> resultados;
        Test.startTest();
        System.runAs(sinAcceso) {
            resultados = AgentesActualizarProximoPaso.ejecutar(new List<AgentesActualizarProximoPaso.Solicitud>{ solicitud(abiertaId, 'Intento') });
        }
        Test.stopTest();
        Assert.isFalse(resultados[0].exito);
        Assert.isTrue(resultados[0].mensaje.contains('permisos del usuario'), resultados[0].mensaje);
        Assert.isNull(resultados[0].valorNuevo);
        Assert.areEqual(AgentesTestDataFactory.PASO_INICIAL, proximoPaso(abiertaId));
    }

    @IsTest
    static void usuarioDeSoloLecturaNoCambiaNada() {
        Id abiertaId = AgentesTestDataFactory.primeraAbierta().Id;
        User soloLectura = AgentesTestDataFactory.usuario(AgentesTestDataFactory.APELLIDO_SOLO_LECTURA);
        List<AgentesActualizarProximoPaso.Resultado> resultados;
        Test.startTest();
        System.runAs(soloLectura) {
            resultados = AgentesActualizarProximoPaso.ejecutar(new List<AgentesActualizarProximoPaso.Solicitud>{ solicitud(abiertaId, 'Intento') });
        }
        Test.stopTest();
        // Según la compartición de la org, no ve la oportunidad o no la puede editar: falla igual.
        Assert.isFalse(resultados[0].exito, resultados[0].mensaje);
        Assert.isTrue(String.isNotBlank(resultados[0].mensaje));
        Assert.isNull(resultados[0].valorNuevo);
        Assert.areEqual(AgentesTestDataFactory.PASO_INICIAL, proximoPaso(abiertaId));
    }
}
