/**
 * Pruebas de `AgentesCrearTareaSeguimiento`.
 *
 * Cubre el caso válido, cada regla rota a propósito (regla T2), un lote de
 * `AgentesTestDataFactory.CANTIDAD_MASIVA` tareas y dos usuarios con permisos mínimos
 * (`System.runAs`): uno que no lee oportunidades y otro que las lee pero no crea tareas.
 * En los casos que deben fallar se comprueba también que no se creó ninguna tarea.
 */
@IsTest
private class AgentesCrearTareaSeguimientoTest {

    @TestSetup
    static void crearDatos() {
        AgentesTestDataFactory.crearEscenario(AgentesTestDataFactory.CANTIDAD_MASIVA);
    }

    private static AgentesCrearTareaSeguimiento.Solicitud solicitud(Id oportunidadId, String asunto, Date fecha) {
        AgentesCrearTareaSeguimiento.Solicitud solicitud = new AgentesCrearTareaSeguimiento.Solicitud();
        solicitud.oportunidadId = oportunidadId;
        solicitud.asunto = asunto;
        solicitud.fechaVencimiento = fecha;
        return solicitud;
    }

    private static Integer tareasDe(Set<Id> oportunidadIds) {
        return [SELECT COUNT() FROM Task WHERE WhatId IN :oportunidadIds];
    }

    @IsTest
    static void creaLaTareaLigadaYAsignadaAlUsuario() {
        Id abiertaId = AgentesTestDataFactory.primeraAbierta().Id;
        Id contactoId = AgentesTestDataFactory.contacto().Id;
        Date vence = Date.today().addDays(2);
        AgentesCrearTareaSeguimiento.Solicitud conTodo = solicitud(abiertaId, '  Llamar a Ana  ', vence);
        conTodo.contactoId = contactoId;
        conTodo.descripcion = '  Confirmar la propuesta.  ';
        Test.startTest();
        List<AgentesCrearTareaSeguimiento.Resultado> resultados = AgentesCrearTareaSeguimiento.ejecutar(
            new List<AgentesCrearTareaSeguimiento.Solicitud>{ conTodo }
        );
        Test.stopTest();
        Assert.isTrue(resultados[0].exito, resultados[0].mensaje);
        Assert.areEqual(abiertaId, resultados[0].oportunidadId);
        Task tarea = [
            SELECT WhatId, WhoId, OwnerId, Subject, ActivityDate, Description
            FROM Task WHERE Id = :resultados[0].tareaId
        ];
        Assert.areEqual(abiertaId, tarea.WhatId);
        Assert.areEqual(contactoId, tarea.WhoId);
        Assert.areEqual(UserInfo.getUserId(), tarea.OwnerId);
        Assert.areEqual('Llamar a Ana', tarea.Subject);
        Assert.areEqual(vence, tarea.ActivityDate);
        Assert.areEqual('Confirmar la propuesta.', tarea.Description);
    }

    @IsTest
    static void creaLaTareaSinContactoNiDescripcion() {
        Id abiertaId = AgentesTestDataFactory.primeraAbierta().Id;
        AgentesCrearTareaSeguimiento.Solicitud minima = solicitud(abiertaId, 'Asunto', Date.today());
        minima.descripcion = '   ';
        Test.startTest();
        List<AgentesCrearTareaSeguimiento.Resultado> resultados = AgentesCrearTareaSeguimiento.ejecutar(
            new List<AgentesCrearTareaSeguimiento.Solicitud>{ minima }
        );
        Test.stopTest();
        Assert.isTrue(resultados[0].exito, resultados[0].mensaje);
        Task tarea = [SELECT WhoId, Description FROM Task WHERE Id = :resultados[0].tareaId];
        Assert.isNull(tarea.WhoId);
        Assert.isNull(tarea.Description);
    }

    @IsTest
    static void rechazaDatosInvalidosSinCrearNada() {
        Id abiertaId = AgentesTestDataFactory.primeraAbierta().Id;
        Id cerradaId = AgentesTestDataFactory.cerrada().Id;
        Integer largoAsunto = Task.Subject.getDescribe().getLength();
        Integer largoDescripcion = Task.Description.getDescribe().getLength();

        AgentesCrearTareaSeguimiento.Solicitud cuentaComoContacto = solicitud(abiertaId, 'Asunto', Date.today());
        cuentaComoContacto.contactoId = AgentesTestDataFactory.cuenta().Id;
        AgentesCrearTareaSeguimiento.Solicitud descripcionLarga = solicitud(abiertaId, 'Asunto', Date.today());
        descripcionLarga.descripcion = 'x'.repeat(largoDescripcion + 1);

        List<AgentesCrearTareaSeguimiento.Solicitud> solicitudes = new List<AgentesCrearTareaSeguimiento.Solicitud>{
            solicitud(cerradaId, 'Asunto', Date.today()),
            solicitud(abiertaId, '', Date.today()),
            solicitud(abiertaId, 'x'.repeat(largoAsunto + 1), Date.today()),
            solicitud(abiertaId, 'Asunto', Date.today().addDays(-1)),
            solicitud(abiertaId, 'Asunto', null),
            cuentaComoContacto,
            descripcionLarga,
            null
        };
        List<String> esperados = new List<String>{
            'cerrada', 'vacío', 'máximo', 'ya pasó', 'Falta', 'no es de un contacto', 'descripción', 'Solicitud vacía'
        };
        Test.startTest();
        List<AgentesCrearTareaSeguimiento.Resultado> resultados = AgentesCrearTareaSeguimiento.ejecutar(solicitudes);
        Test.stopTest();
        Assert.areEqual(solicitudes.size(), resultados.size());
        for (Integer i = 0; i < resultados.size(); i++) {
            Assert.isFalse(resultados[i].exito, resultados[i].mensaje);
            Assert.isNull(resultados[i].tareaId);
            Assert.isTrue(resultados[i].mensaje.contains(esperados[i]), 'Solicitud ' + i + ': ' + resultados[i].mensaje);
        }
        Assert.areEqual(0, tareasDe(new Set<Id>{ abiertaId, cerradaId }));
    }

    @IsTest
    static void creaVariasTareasParaLaMismaOportunidad() {
        Id abiertaId = AgentesTestDataFactory.primeraAbierta().Id;
        Test.startTest();
        List<AgentesCrearTareaSeguimiento.Resultado> resultados = AgentesCrearTareaSeguimiento.ejecutar(
            new List<AgentesCrearTareaSeguimiento.Solicitud>{
                solicitud(abiertaId, 'Uno', Date.today()),
                solicitud(abiertaId, 'Dos', Date.today().addDays(1))
            }
        );
        Test.stopTest();
        Assert.isTrue(resultados[0].exito, resultados[0].mensaje);
        Assert.isTrue(resultados[1].exito, resultados[1].mensaje);
        Assert.areNotEqual(resultados[0].tareaId, resultados[1].tareaId);
        Assert.areEqual(2, tareasDe(new Set<Id>{ abiertaId }));
    }

    @IsTest
    static void creaUnLoteCompleto() {
        List<Opportunity> abiertas = AgentesTestDataFactory.abiertas();
        List<AgentesCrearTareaSeguimiento.Solicitud> solicitudes = new List<AgentesCrearTareaSeguimiento.Solicitud>();
        for (Opportunity abierta : abiertas) {
            solicitudes.add(solicitud(abierta.Id, 'Seguimiento de ' + abierta.Name, Date.today().addDays(1)));
        }
        Test.startTest();
        List<AgentesCrearTareaSeguimiento.Resultado> resultados = AgentesCrearTareaSeguimiento.ejecutar(solicitudes);
        Test.stopTest();
        Assert.areEqual(AgentesTestDataFactory.CANTIDAD_MASIVA, resultados.size());
        for (Integer i = 0; i < resultados.size(); i++) {
            Assert.isTrue(resultados[i].exito, resultados[i].mensaje);
            Assert.areEqual(abiertas[i].Id, resultados[i].oportunidadId, 'El orden de los resultados es el de las solicitudes.');
        }
        Assert.areEqual(AgentesTestDataFactory.CANTIDAD_MASIVA, tareasDe(AgentesTestDataFactory.ids(abiertas)));
    }

    @IsTest
    static void usuarioQueNoLeeOportunidadesNoCreaNada() {
        Id abiertaId = AgentesTestDataFactory.primeraAbierta().Id;
        User sinAcceso = AgentesTestDataFactory.usuario(AgentesTestDataFactory.APELLIDO_SIN_ACCESO);
        List<AgentesCrearTareaSeguimiento.Resultado> resultados;
        Test.startTest();
        System.runAs(sinAcceso) {
            resultados = AgentesCrearTareaSeguimiento.ejecutar(
                new List<AgentesCrearTareaSeguimiento.Solicitud>{ solicitud(abiertaId, 'Intento', Date.today()) }
            );
        }
        Test.stopTest();
        Assert.isFalse(resultados[0].exito);
        Assert.isTrue(resultados[0].mensaje.contains('permisos del usuario'), resultados[0].mensaje);
        Assert.isNull(resultados[0].tareaId);
        Assert.areEqual(0, tareasDe(new Set<Id>{ abiertaId }));
    }

    @IsTest
    static void usuarioSinPermisoDeTareasNoCreaNada() {
        Id abiertaId = AgentesTestDataFactory.primeraAbierta().Id;
        User soloLectura = AgentesTestDataFactory.usuario(AgentesTestDataFactory.APELLIDO_SOLO_LECTURA);
        List<AgentesCrearTareaSeguimiento.Resultado> resultados;
        Test.startTest();
        System.runAs(soloLectura) {
            resultados = AgentesCrearTareaSeguimiento.ejecutar(
                new List<AgentesCrearTareaSeguimiento.Solicitud>{ solicitud(abiertaId, 'Intento', Date.today()) }
            );
        }
        Test.stopTest();
        // Según la compartición de la org, no ve la oportunidad o no puede crear tareas: falla igual.
        Assert.isFalse(resultados[0].exito, resultados[0].mensaje);
        Assert.isTrue(String.isNotBlank(resultados[0].mensaje));
        Assert.isNull(resultados[0].tareaId);
        Assert.areEqual(0, tareasDe(new Set<Id>{ abiertaId }));
    }
}
