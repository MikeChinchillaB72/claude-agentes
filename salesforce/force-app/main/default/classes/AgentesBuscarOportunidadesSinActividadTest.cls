/**
 * Pruebas de `AgentesBuscarOportunidadesSinActividad`.
 *
 * Cubre el orden por monto, el límite, el monto mínimo, el corte exacto de días (con una
 * tarea cerrada, que es lo que actualiza `LastActivityDate`), cada valor inválido (regla
 * T2), un lote de `AgentesTestDataFactory.CANTIDAD_MASIVA` oportunidades y dos usuarios
 * con permisos mínimos (`System.runAs`). Las oportunidades de la fábrica son del usuario
 * que corre la prueba y no tienen actividad.
 */
@IsTest
private class AgentesBuscarOportunidadesSinActividadTest {

    /** Días que usan las pruebas; el valor inicial de `dias_sin_actividad` en criterios.md. */
    private static final Integer DIAS = 7;

    @TestSetup
    static void crearDatos() {
        AgentesTestDataFactory.crearEscenario(AgentesTestDataFactory.CANTIDAD_MASIVA);
    }

    private static AgentesBuscarOportunidadesSinActividad.Solicitud solicitud(
        Integer dias, Integer maximo, Decimal montoMinimo
    ) {
        AgentesBuscarOportunidadesSinActividad.Solicitud solicitud = new AgentesBuscarOportunidadesSinActividad.Solicitud();
        solicitud.diasSinActividad = dias;
        solicitud.maximoOportunidades = maximo;
        solicitud.montoMinimo = montoMinimo;
        return solicitud;
    }

    private static List<AgentesBuscarOportunidadesSinActividad.Resultado> buscar(
        List<AgentesBuscarOportunidadesSinActividad.Solicitud> solicitudes
    ) {
        return AgentesBuscarOportunidadesSinActividad.ejecutar(solicitudes);
    }

    /** Registra una tarea cerrada en la oportunidad, con la fecha dada. */
    private static void registrarActividad(Id oportunidadId, Date fecha) {
        String estadoCerrado = [SELECT ApiName FROM TaskStatus WHERE IsClosed = true ORDER BY SortOrder LIMIT 1].ApiName;
        insert new Task(WhatId = oportunidadId, Subject = 'PRUEBA-Llamada', ActivityDate = fecha, Status = estadoCerrado);
    }

    /** Pone montos a las tres primeras abiertas: 100, 300 y 200. */
    private static List<Opportunity> ponerMontos() {
        List<Opportunity> abiertas = AgentesTestDataFactory.abiertas();
        List<Opportunity> conMonto = new List<Opportunity>{
            new Opportunity(Id = abiertas[0].Id, Amount = 100),
            new Opportunity(Id = abiertas[1].Id, Amount = 300),
            new Opportunity(Id = abiertas[2].Id, Amount = 200)
        };
        update conMonto;
        return abiertas;
    }

    @IsTest
    static void devuelveLasDeMayorMontoHastaElMaximo() {
        List<Opportunity> abiertas = ponerMontos();
        Test.startTest();
        List<AgentesBuscarOportunidadesSinActividad.Resultado> resultados = buscar(
            new List<AgentesBuscarOportunidadesSinActividad.Solicitud>{ solicitud(DIAS, 3, null) }
        );
        Test.stopTest();
        AgentesBuscarOportunidadesSinActividad.Resultado resultado = resultados[0];
        Assert.isTrue(resultado.exito, resultado.mensaje);
        Assert.areEqual(3, resultado.cantidad);
        Assert.areEqual(abiertas[1].Id, resultado.oportunidades[0].Id, 'Primero la de 300.');
        Assert.areEqual(abiertas[2].Id, resultado.oportunidades[1].Id, 'Después la de 200.');
        Assert.areEqual(abiertas[0].Id, resultado.oportunidades[2].Id, 'Después la de 100.');
        Assert.areEqual(AgentesTestDataFactory.NOMBRE_CUENTA, resultado.oportunidades[0].Account.Name);
        Assert.areEqual(AgentesTestDataFactory.PASO_INICIAL, resultado.oportunidades[0].NextStep);
    }

    @IsTest
    static void respetaElMontoMinimo() {
        List<Opportunity> abiertas = ponerMontos();
        Test.startTest();
        List<AgentesBuscarOportunidadesSinActividad.Resultado> resultados = buscar(
            new List<AgentesBuscarOportunidadesSinActividad.Solicitud>{ solicitud(DIAS, 10, 200) }
        );
        Test.stopTest();
        Assert.isTrue(resultados[0].exito, resultados[0].mensaje);
        Assert.areEqual(2, resultados[0].cantidad, 'Solo las de 300 y 200.');
        Assert.areEqual(
            new Set<Id>{ abiertas[1].Id, abiertas[2].Id },
            AgentesTestDataFactory.ids(resultados[0].oportunidades)
        );
    }

    @IsTest
    static void excluyeLaQueTuvoActividadReciente() {
        Id conActividadId = AgentesTestDataFactory.primeraAbierta().Id;
        registrarActividad(conActividadId, Date.today());
        Test.startTest();
        List<AgentesBuscarOportunidadesSinActividad.Resultado> resultados = buscar(
            new List<AgentesBuscarOportunidadesSinActividad.Solicitud>{
                solicitud(DIAS, AgentesTestDataFactory.CANTIDAD_MASIVA, null)
            }
        );
        Test.stopTest();
        Assert.isTrue(resultados[0].exito, resultados[0].mensaje);
        Assert.areEqual(AgentesTestDataFactory.CANTIDAD_MASIVA - 1, resultados[0].cantidad);
        Assert.isFalse(AgentesTestDataFactory.ids(resultados[0].oportunidades).contains(conActividadId));
    }

    @IsTest
    static void cuentaLosDiasExactos() {
        Id oportunidadId = AgentesTestDataFactory.primeraAbierta().Id;
        registrarActividad(oportunidadId, Date.today().addDays(-DIAS));
        Integer todas = AgentesTestDataFactory.CANTIDAD_MASIVA;
        Test.startTest();
        List<AgentesBuscarOportunidadesSinActividad.Resultado> resultados = buscar(
            new List<AgentesBuscarOportunidadesSinActividad.Solicitud>{
                solicitud(DIAS, todas, null),
                solicitud(DIAS + 1, todas, null)
            }
        );
        Test.stopTest();
        Assert.isTrue(
            AgentesTestDataFactory.ids(resultados[0].oportunidades).contains(oportunidadId),
            'Con actividad hace justo los días pedidos, entra.'
        );
        Assert.isFalse(
            AgentesTestDataFactory.ids(resultados[1].oportunidades).contains(oportunidadId),
            'Con un día más de margen, ya no entra.'
        );
    }

    @IsTest
    static void devuelveUnLoteCompletoSinLaCerrada() {
        Id cerradaId = AgentesTestDataFactory.cerrada().Id;
        Test.startTest();
        List<AgentesBuscarOportunidadesSinActividad.Resultado> resultados = buscar(
            new List<AgentesBuscarOportunidadesSinActividad.Solicitud>{
                solicitud(DIAS, AgentesTestDataFactory.CANTIDAD_MASIVA + 1, null)
            }
        );
        Test.stopTest();
        Assert.isTrue(resultados[0].exito, resultados[0].mensaje);
        Assert.areEqual(AgentesTestDataFactory.CANTIDAD_MASIVA, resultados[0].cantidad);
        Assert.areEqual(
            AgentesTestDataFactory.ids(AgentesTestDataFactory.abiertas()),
            AgentesTestDataFactory.ids(resultados[0].oportunidades)
        );
        Assert.isFalse(AgentesTestDataFactory.ids(resultados[0].oportunidades).contains(cerradaId));
    }

    @IsTest
    static void sinResultadosTambienEsExito() {
        Test.startTest();
        List<AgentesBuscarOportunidadesSinActividad.Resultado> resultados = buscar(
            new List<AgentesBuscarOportunidadesSinActividad.Solicitud>{ solicitud(DIAS, 10, 1000000) }
        );
        Test.stopTest();
        Assert.isTrue(resultados[0].exito, resultados[0].mensaje);
        Assert.areEqual(0, resultados[0].cantidad);
        Assert.isTrue(resultados[0].oportunidades.isEmpty());
        Assert.isTrue(resultados[0].mensaje.startsWith('No hay'), resultados[0].mensaje);
    }

    @IsTest
    static void rechazaValoresInvalidosYSolicitudVacia() {
        Test.startTest();
        List<AgentesBuscarOportunidadesSinActividad.Resultado> resultados = buscar(
            new List<AgentesBuscarOportunidadesSinActividad.Solicitud>{
                solicitud(null, 10, null),
                solicitud(0, 10, null),
                solicitud(DIAS, null, null),
                solicitud(DIAS, 0, null),
                solicitud(DIAS, 10, -1),
                null
            }
        );
        Integer consultas = Limits.getQueries();
        Test.stopTest();
        Assert.areEqual(0, consultas, 'Una solicitud inválida no consulta.');
        Assert.areEqual(6, resultados.size());
        Assert.isTrue(resultados[0].mensaje.contains('días'), resultados[0].mensaje);
        Assert.isTrue(resultados[1].mensaje.contains('días'), resultados[1].mensaje);
        Assert.isTrue(resultados[2].mensaje.contains('máximo'), resultados[2].mensaje);
        Assert.isTrue(resultados[3].mensaje.contains('máximo'), resultados[3].mensaje);
        Assert.isTrue(resultados[4].mensaje.contains('negativo'), resultados[4].mensaje);
        Assert.areEqual('Solicitud vacía.', resultados[5].mensaje);
        for (AgentesBuscarOportunidadesSinActividad.Resultado resultado : resultados) {
            Assert.isFalse(resultado.exito, resultado.mensaje);
            Assert.areEqual(0, resultado.cantidad);
        }
    }

    @IsTest
    static void usaUnaConsultaPorSolicitud() {
        Test.startTest();
        buscar(new List<AgentesBuscarOportunidadesSinActividad.Solicitud>{
            solicitud(DIAS, 10, null),
            solicitud(DIAS, 5, 100)
        });
        Integer consultas = Limits.getQueries();
        Test.stopTest();
        Assert.areEqual(2, consultas);
    }

    @IsTest
    static void usuarioQueNoLeeOportunidadesRecibeElMotivo() {
        User sinAcceso = AgentesTestDataFactory.usuario(AgentesTestDataFactory.APELLIDO_SIN_ACCESO);
        List<AgentesBuscarOportunidadesSinActividad.Resultado> resultados;
        Test.startTest();
        System.runAs(sinAcceso) {
            resultados = buscar(
                new List<AgentesBuscarOportunidadesSinActividad.Solicitud>{ solicitud(DIAS, 10, null) }
            );
        }
        Test.stopTest();
        Assert.isFalse(resultados[0].exito);
        Assert.isTrue(resultados[0].mensaje.contains('permisos del usuario'), resultados[0].mensaje);
        Assert.isTrue(resultados[0].oportunidades.isEmpty());
    }

    @IsTest
    static void usuarioDeSoloLecturaNoVeLasDeOtro() {
        User soloLectura = AgentesTestDataFactory.usuario(AgentesTestDataFactory.APELLIDO_SOLO_LECTURA);
        List<AgentesBuscarOportunidadesSinActividad.Resultado> resultados;
        Test.startTest();
        System.runAs(soloLectura) {
            resultados = buscar(
                new List<AgentesBuscarOportunidadesSinActividad.Solicitud>{
                    solicitud(DIAS, AgentesTestDataFactory.CANTIDAD_MASIVA, null)
                }
            );
        }
        Test.stopTest();
        // No es dueño de ninguna. Según sus permisos de campo, la búsqueda sale vacía o falla
        // con el motivo; en ningún caso devuelve oportunidades de otro usuario.
        Assert.isTrue(resultados[0].oportunidades.isEmpty());
        Assert.areEqual(0, resultados[0].cantidad);
        Assert.isTrue(String.isNotBlank(resultados[0].mensaje));
    }
}
