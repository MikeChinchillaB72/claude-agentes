/**
 * Pruebas de las acciones de `ventas-seguimiento`: `AgentesActualizarProximoPaso`,
 * `AgentesCrearTareaSeguimiento`, `AgentesMoverFechaCierre` y sus reglas comunes en
 * `AgentesCrmAcciones`.
 *
 * Cada regla se prueba también rota a propósito (regla T2): oportunidad cerrada, Id de
 * otro objeto, fecha pasada, texto vacío o demasiado largo e Id repetido. Las etapas se
 * leen de la org (`OpportunityStage`) para no depender de sus nombres.
 */
@IsTest
private class AgentesCrmAccionesTest {

    @TestSetup
    static void crearDatos() {
        OpportunityStage abierta = [
            SELECT ApiName FROM OpportunityStage
            WHERE IsActive = true AND IsClosed = false
            ORDER BY SortOrder LIMIT 1
        ];
        OpportunityStage cerrada = [
            SELECT ApiName FROM OpportunityStage
            WHERE IsActive = true AND IsClosed = true
            ORDER BY SortOrder LIMIT 1
        ];
        Account cuenta = new Account(Name = 'PRUEBA-Acciones');
        insert cuenta;
        insert new Contact(LastName = 'PRUEBA-Contacto', AccountId = cuenta.Id);
        insert new List<Opportunity>{
            new Opportunity(Name = 'PRUEBA-Abierta', AccountId = cuenta.Id, StageName = abierta.ApiName,
                CloseDate = Date.today().addDays(-3), NextStep = 'Paso viejo'),
            new Opportunity(Name = 'PRUEBA-Cerrada', AccountId = cuenta.Id, StageName = cerrada.ApiName,
                CloseDate = Date.today().addDays(-10))
        };
    }

    private static Opportunity oportunidad(String nombre) {
        return [SELECT Id, NextStep, CloseDate FROM Opportunity WHERE Name = :nombre];
    }

    // ── Actualizar próximo paso ──────────────────────────────────────────────

    private static AgentesActualizarProximoPaso.Solicitud pasoSolicitud(Id oportunidadId, String texto) {
        AgentesActualizarProximoPaso.Solicitud solicitud = new AgentesActualizarProximoPaso.Solicitud();
        solicitud.oportunidadId = oportunidadId;
        solicitud.proximoPaso = texto;
        return solicitud;
    }

    @IsTest
    static void proximoPasoSeGuarda() {
        Opportunity abierta = oportunidad('PRUEBA-Abierta');
        Test.startTest();
        List<AgentesActualizarProximoPaso.Resultado> resultados = AgentesActualizarProximoPaso.ejecutar(
            new List<AgentesActualizarProximoPaso.Solicitud>{ pasoSolicitud(abierta.Id, '  Enviar propuesta  ') }
        );
        Test.stopTest();
        Assert.isTrue(resultados[0].exito, resultados[0].mensaje);
        Assert.areEqual('Paso viejo', resultados[0].valorAnterior);
        Assert.areEqual('Enviar propuesta', oportunidad('PRUEBA-Abierta').NextStep);
    }

    @IsTest
    static void proximoPasoNoTocaOportunidadCerrada() {
        Opportunity cerrada = oportunidad('PRUEBA-Cerrada');
        List<AgentesActualizarProximoPaso.Resultado> resultados = AgentesActualizarProximoPaso.ejecutar(
            new List<AgentesActualizarProximoPaso.Solicitud>{ pasoSolicitud(cerrada.Id, 'Algo') }
        );
        Assert.isFalse(resultados[0].exito);
        Assert.isTrue(resultados[0].mensaje.contains('cerrada'), resultados[0].mensaje);
        Assert.isNull(oportunidad('PRUEBA-Cerrada').NextStep);
    }

    @IsTest
    static void proximoPasoRechazaVacioLargoYRepetido() {
        Opportunity abierta = oportunidad('PRUEBA-Abierta');
        Integer largoMaximo = Opportunity.NextStep.getDescribe().getLength();
        List<AgentesActualizarProximoPaso.Resultado> resultados = AgentesActualizarProximoPaso.ejecutar(
            new List<AgentesActualizarProximoPaso.Solicitud>{
                pasoSolicitud(abierta.Id, '   '),
                pasoSolicitud(abierta.Id, 'x'.repeat(largoMaximo + 1)),
                pasoSolicitud(abierta.Id, 'Primero'),
                pasoSolicitud(abierta.Id, 'Repetido')
            }
        );
        Assert.isFalse(resultados[0].exito, 'Texto vacío');
        Assert.isFalse(resultados[1].exito, 'Texto largo');
        Assert.isTrue(resultados[2].exito, resultados[2].mensaje);
        Assert.isFalse(resultados[3].exito, 'Id repetido');
        Assert.areEqual('Primero', oportunidad('PRUEBA-Abierta').NextStep);
    }

    @IsTest
    static void proximoPasoRechazaIdDeOtroObjeto() {
        Account cuenta = [SELECT Id FROM Account WHERE Name = 'PRUEBA-Acciones'];
        List<AgentesActualizarProximoPaso.Resultado> resultados = AgentesActualizarProximoPaso.ejecutar(
            new List<AgentesActualizarProximoPaso.Solicitud>{ pasoSolicitud(cuenta.Id, 'Algo') }
        );
        Assert.isFalse(resultados[0].exito);
        Assert.isTrue(resultados[0].mensaje.contains('no es de una oportunidad'), resultados[0].mensaje);
    }

    // ── Mover fecha de cierre ────────────────────────────────────────────────

    private static AgentesMoverFechaCierre.Solicitud fechaSolicitud(Id oportunidadId, Date fecha) {
        AgentesMoverFechaCierre.Solicitud solicitud = new AgentesMoverFechaCierre.Solicitud();
        solicitud.oportunidadId = oportunidadId;
        solicitud.nuevaFechaCierre = fecha;
        return solicitud;
    }

    @IsTest
    static void fechaDeCierreSeMueve() {
        Opportunity abierta = oportunidad('PRUEBA-Abierta');
        Date nueva = Date.today().addDays(14);
        List<AgentesMoverFechaCierre.Resultado> resultados = AgentesMoverFechaCierre.ejecutar(
            new List<AgentesMoverFechaCierre.Solicitud>{ fechaSolicitud(abierta.Id, nueva) }
        );
        Assert.isTrue(resultados[0].exito, resultados[0].mensaje);
        Assert.areEqual(abierta.CloseDate, resultados[0].fechaAnterior);
        Assert.areEqual(nueva, oportunidad('PRUEBA-Abierta').CloseDate);
    }

    @IsTest
    static void fechaDeCierreRechazaPasadaYCerrada() {
        Opportunity abierta = oportunidad('PRUEBA-Abierta');
        Opportunity cerrada = oportunidad('PRUEBA-Cerrada');
        List<AgentesMoverFechaCierre.Resultado> resultados = AgentesMoverFechaCierre.ejecutar(
            new List<AgentesMoverFechaCierre.Solicitud>{
                fechaSolicitud(abierta.Id, Date.today().addDays(-1)),
                fechaSolicitud(cerrada.Id, Date.today().addDays(5)),
                fechaSolicitud(abierta.Id, null)
            }
        );
        Assert.isFalse(resultados[0].exito, 'Fecha pasada');
        Assert.isFalse(resultados[1].exito, 'Oportunidad cerrada');
        Assert.isFalse(resultados[2].exito, 'Sin fecha');
        Assert.areEqual(abierta.CloseDate, oportunidad('PRUEBA-Abierta').CloseDate);
    }

    // ── Crear tarea de seguimiento ──────────────────────────────────────────

    private static AgentesCrearTareaSeguimiento.Solicitud tareaSolicitud(Id oportunidadId, String asunto, Date fecha) {
        AgentesCrearTareaSeguimiento.Solicitud solicitud = new AgentesCrearTareaSeguimiento.Solicitud();
        solicitud.oportunidadId = oportunidadId;
        solicitud.asunto = asunto;
        solicitud.fechaVencimiento = fecha;
        return solicitud;
    }

    @IsTest
    static void tareaSeCreaLigadaYAsignadaAlUsuario() {
        Opportunity abierta = oportunidad('PRUEBA-Abierta');
        Contact contacto = [SELECT Id FROM Contact WHERE LastName = 'PRUEBA-Contacto'];
        AgentesCrearTareaSeguimiento.Solicitud solicitud = tareaSolicitud(abierta.Id, 'Llamar a Ana', Date.today().addDays(2));
        solicitud.contactoId = contacto.Id;
        solicitud.descripcion = 'Confirmar la propuesta.';
        List<AgentesCrearTareaSeguimiento.Resultado> resultados = AgentesCrearTareaSeguimiento.ejecutar(
            new List<AgentesCrearTareaSeguimiento.Solicitud>{ solicitud }
        );
        Assert.isTrue(resultados[0].exito, resultados[0].mensaje);
        Task tarea = [SELECT WhatId, WhoId, OwnerId, Subject, ActivityDate FROM Task WHERE Id = :resultados[0].tareaId];
        Assert.areEqual(abierta.Id, tarea.WhatId);
        Assert.areEqual(contacto.Id, tarea.WhoId);
        Assert.areEqual(UserInfo.getUserId(), tarea.OwnerId);
        Assert.areEqual(Date.today().addDays(2), tarea.ActivityDate);
    }

    @IsTest
    static void tareaRechazaDatosInvalidos() {
        Opportunity abierta = oportunidad('PRUEBA-Abierta');
        Opportunity cerrada = oportunidad('PRUEBA-Cerrada');
        AgentesCrearTareaSeguimiento.Solicitud conCuentaComoContacto = tareaSolicitud(abierta.Id, 'Asunto', Date.today());
        conCuentaComoContacto.contactoId = [SELECT Id FROM Account WHERE Name = 'PRUEBA-Acciones'].Id;
        List<AgentesCrearTareaSeguimiento.Resultado> resultados = AgentesCrearTareaSeguimiento.ejecutar(
            new List<AgentesCrearTareaSeguimiento.Solicitud>{
                tareaSolicitud(cerrada.Id, 'Asunto', Date.today()),
                tareaSolicitud(abierta.Id, '', Date.today()),
                tareaSolicitud(abierta.Id, 'Asunto', Date.today().addDays(-1)),
                conCuentaComoContacto
            }
        );
        for (AgentesCrearTareaSeguimiento.Resultado resultado : resultados) {
            Assert.isFalse(resultado.exito, resultado.mensaje);
        }
        Assert.areEqual(0, [SELECT COUNT() FROM Task WHERE WhatId = :abierta.Id]);
    }

    @IsTest
    static void variasTareasParaLaMismaOportunidad() {
        Opportunity abierta = oportunidad('PRUEBA-Abierta');
        List<AgentesCrearTareaSeguimiento.Resultado> resultados = AgentesCrearTareaSeguimiento.ejecutar(
            new List<AgentesCrearTareaSeguimiento.Solicitud>{
                tareaSolicitud(abierta.Id, 'Uno', Date.today()),
                tareaSolicitud(abierta.Id, 'Dos', Date.today().addDays(1))
            }
        );
        Assert.isTrue(resultados[0].exito && resultados[1].exito);
        Assert.areEqual(2, [SELECT COUNT() FROM Task WHERE WhatId = :abierta.Id]);
    }

    // ── Reglas comunes ──────────────────────────────────────────────────────

    @IsTest
    static void consultaNoAceptaCamposFueraDeLaLista() {
        try {
            AgentesCrmAcciones.leerOportunidades(
                new Set<Id>{ oportunidad('PRUEBA-Abierta').Id }, new List<String>{ 'Amount' }
            );
            Assert.fail('Debió rechazar un campo fuera de la lista.');
        } catch (IllegalArgumentException e) {
            Assert.isTrue(e.getMessage().contains('Amount'));
        }
    }
}
