/**
 * Pruebas de `AgentesLeerHistorialOportunidad`.
 *
 * Cubre el orden y el recorte de tareas y eventos, el contacto principal (y que no devuelva uno
 * que no es principal), una oportunidad sin historial, cada valor inválido (regla T2), un lote
 * de `AgentesTestDataFactory.CANTIDAD_MASIVA` solicitudes en una sola consulta y dos usuarios
 * con permisos mínimos (`System.runAs`).
 */
@IsTest
private class AgentesLeerHistorialOportunidadTest {

    /** Valor inicial de `interacciones_a_leer` en criterios.md. */
    private static final Integer MAXIMO = 5;

    @TestSetup
    static void crearDatos() {
        AgentesTestDataFactory.crearEscenario(AgentesTestDataFactory.CANTIDAD_MASIVA);
    }

    private static AgentesLeerHistorialOportunidad.Solicitud solicitud(Id oportunidadId, Integer maximo) {
        AgentesLeerHistorialOportunidad.Solicitud solicitud = new AgentesLeerHistorialOportunidad.Solicitud();
        solicitud.oportunidadId = oportunidadId;
        solicitud.maximoActividades = maximo;
        return solicitud;
    }

    private static List<AgentesLeerHistorialOportunidad.Resultado> leer(
        List<AgentesLeerHistorialOportunidad.Solicitud> solicitudes
    ) {
        return AgentesLeerHistorialOportunidad.ejecutar(solicitudes);
    }

    /** Crea tres tareas (hace 1, 5 y 10 días) y dos eventos (hace 2 y 8 días) en la oportunidad. */
    private static void crearHistorial(Id oportunidadId) {
        insert new List<Task>{
            new Task(WhatId = oportunidadId, Subject = 'PRUEBA-Tarea-1', ActivityDate = Date.today().addDays(-1)),
            new Task(WhatId = oportunidadId, Subject = 'PRUEBA-Tarea-5', ActivityDate = Date.today().addDays(-5)),
            new Task(WhatId = oportunidadId, Subject = 'PRUEBA-Tarea-10', ActivityDate = Date.today().addDays(-10))
        };
        insert new List<Event>{
            nuevoEvento(oportunidadId, 'PRUEBA-Evento-2', -2),
            nuevoEvento(oportunidadId, 'PRUEBA-Evento-8', -8)
        };
    }

    private static Event nuevoEvento(Id oportunidadId, String asunto, Integer dias) {
        Datetime inicio = Datetime.now().addDays(dias);
        return new Event(WhatId = oportunidadId, Subject = asunto, StartDateTime = inicio, EndDateTime = inicio.addHours(1));
    }

    /** Liga el contacto de la fábrica como principal y otro contacto como no principal. */
    private static void crearContactos(Id oportunidadId) {
        Contact secundario = new Contact(LastName = 'PRUEBA-Secundario', AccountId = AgentesTestDataFactory.cuenta().Id);
        insert secundario;
        insert new List<OpportunityContactRole>{
            new OpportunityContactRole(OpportunityId = oportunidadId, ContactId = secundario.Id, IsPrimary = false),
            new OpportunityContactRole(OpportunityId = oportunidadId, ContactId = AgentesTestDataFactory.contacto().Id, IsPrimary = true)
        };
    }

    @IsTest
    static void devuelveLoMasRecienteRecortadoYElContactoPrincipal() {
        Id oportunidadId = AgentesTestDataFactory.primeraAbierta().Id;
        crearHistorial(oportunidadId);
        crearContactos(oportunidadId);
        Test.startTest();
        List<AgentesLeerHistorialOportunidad.Resultado> resultados = leer(
            new List<AgentesLeerHistorialOportunidad.Solicitud>{ solicitud(oportunidadId, 2) }
        );
        Test.stopTest();
        AgentesLeerHistorialOportunidad.Resultado resultado = resultados[0];
        Assert.isTrue(resultado.exito, resultado.mensaje);
        Assert.areEqual(2, resultado.tareas.size(), 'Se recorta al máximo pedido.');
        Assert.areEqual('PRUEBA-Tarea-1', resultado.tareas[0].Subject, 'Primero la más reciente.');
        Assert.areEqual('PRUEBA-Tarea-5', resultado.tareas[1].Subject);
        Assert.areEqual(2, resultado.eventos.size());
        Assert.areEqual('PRUEBA-Evento-2', resultado.eventos[0].Subject);
        Assert.areEqual(AgentesTestDataFactory.contacto().Id, resultado.contactoPrincipal.Id, 'Solo el principal.');
        Assert.areEqual(AgentesTestDataFactory.APELLIDO_CONTACTO, resultado.contactoPrincipal.Name);
        Assert.areEqual(AgentesTestDataFactory.primeraAbierta().Name, resultado.nombreOportunidad);
    }

    @IsTest
    static void cadaSolicitudRespetaSuPropioMaximo() {
        Id oportunidadId = AgentesTestDataFactory.primeraAbierta().Id;
        crearHistorial(oportunidadId);
        Test.startTest();
        List<AgentesLeerHistorialOportunidad.Resultado> resultados = leer(
            new List<AgentesLeerHistorialOportunidad.Solicitud>{
                solicitud(oportunidadId, 1),
                solicitud(oportunidadId, MAXIMO)
            }
        );
        Test.stopTest();
        Assert.areEqual(1, resultados[0].tareas.size());
        Assert.areEqual(1, resultados[0].eventos.size());
        Assert.areEqual(3, resultados[1].tareas.size(), 'Hay 3 tareas y el máximo es mayor.');
        Assert.areEqual(2, resultados[1].eventos.size());
    }

    @IsTest
    static void oportunidadSinHistorialEsExitoVacio() {
        Id oportunidadId = AgentesTestDataFactory.primeraAbierta().Id;
        Test.startTest();
        List<AgentesLeerHistorialOportunidad.Resultado> resultados = leer(
            new List<AgentesLeerHistorialOportunidad.Solicitud>{ solicitud(oportunidadId, MAXIMO) }
        );
        Test.stopTest();
        Assert.isTrue(resultados[0].exito, resultados[0].mensaje);
        Assert.isTrue(resultados[0].tareas.isEmpty());
        Assert.isTrue(resultados[0].eventos.isEmpty());
        Assert.isNull(resultados[0].contactoPrincipal);
        Assert.isTrue(resultados[0].mensaje.contains('sin contacto principal'), resultados[0].mensaje);
    }

    @IsTest
    static void leeTambienUnaOportunidadCerrada() {
        Id cerradaId = AgentesTestDataFactory.cerrada().Id;
        crearHistorial(cerradaId);
        Test.startTest();
        List<AgentesLeerHistorialOportunidad.Resultado> resultados = leer(
            new List<AgentesLeerHistorialOportunidad.Solicitud>{ solicitud(cerradaId, MAXIMO) }
        );
        Test.stopTest();
        Assert.isTrue(resultados[0].exito, 'Leer no modifica, así que una cerrada se puede leer.');
        Assert.areEqual(3, resultados[0].tareas.size());
    }

    @IsTest
    static void rechazaValoresInvalidosSinConsultar() {
        Id cuentaId = AgentesTestDataFactory.cuenta().Id;
        Id abiertaId = AgentesTestDataFactory.primeraAbierta().Id;
        Test.startTest();
        List<AgentesLeerHistorialOportunidad.Resultado> resultados = leer(
            new List<AgentesLeerHistorialOportunidad.Solicitud>{
                solicitud(null, MAXIMO),
                solicitud(cuentaId, MAXIMO),
                solicitud(abiertaId, 0),
                solicitud(abiertaId, null),
                null
            }
        );
        Integer consultas = Limits.getQueries();
        Test.stopTest();
        Assert.areEqual(0, consultas, 'Una solicitud inválida no consulta.');
        Assert.isTrue(resultados[0].mensaje.contains('Falta'), resultados[0].mensaje);
        Assert.isTrue(resultados[1].mensaje.contains('no es de una oportunidad'), resultados[1].mensaje);
        Assert.isTrue(resultados[2].mensaje.contains('máximo'), resultados[2].mensaje);
        Assert.isTrue(resultados[3].mensaje.contains('máximo'), resultados[3].mensaje);
        Assert.areEqual('Solicitud vacía.', resultados[4].mensaje);
        for (AgentesLeerHistorialOportunidad.Resultado resultado : resultados) {
            Assert.isFalse(resultado.exito, resultado.mensaje);
            Assert.isTrue(resultado.tareas.isEmpty());
        }
    }

    @IsTest
    static void unLoteCompletoUsaUnaSolaConsulta() {
        List<Opportunity> abiertas = AgentesTestDataFactory.abiertas();
        crearHistorial(abiertas[0].Id);
        List<AgentesLeerHistorialOportunidad.Solicitud> solicitudes = new List<AgentesLeerHistorialOportunidad.Solicitud>();
        for (Opportunity abierta : abiertas) {
            solicitudes.add(solicitud(abierta.Id, MAXIMO));
        }
        Test.startTest();
        List<AgentesLeerHistorialOportunidad.Resultado> resultados = leer(solicitudes);
        Integer consultas = Limits.getQueries();
        Test.stopTest();
        Assert.areEqual(1, consultas);
        Assert.areEqual(AgentesTestDataFactory.CANTIDAD_MASIVA, resultados.size());
        for (Integer i = 0; i < resultados.size(); i++) {
            Assert.isTrue(resultados[i].exito, resultados[i].mensaje);
            Assert.areEqual(abiertas[i].Id, resultados[i].oportunidadId, 'El orden de los resultados es el de las solicitudes.');
        }
        Assert.areEqual(3, resultados[0].tareas.size());
    }

    @IsTest
    static void usuarioQueNoLeeOportunidadesRecibeElMotivo() {
        Id oportunidadId = AgentesTestDataFactory.primeraAbierta().Id;
        crearHistorial(oportunidadId);
        User sinAcceso = AgentesTestDataFactory.usuario(AgentesTestDataFactory.APELLIDO_SIN_ACCESO);
        List<AgentesLeerHistorialOportunidad.Resultado> resultados;
        Test.startTest();
        System.runAs(sinAcceso) {
            resultados = leer(new List<AgentesLeerHistorialOportunidad.Solicitud>{ solicitud(oportunidadId, MAXIMO) });
        }
        Test.stopTest();
        Assert.isFalse(resultados[0].exito);
        Assert.isTrue(resultados[0].mensaje.contains('permisos del usuario'), resultados[0].mensaje);
        Assert.isTrue(resultados[0].tareas.isEmpty());
    }

    @IsTest
    static void usuarioDeSoloLecturaNoRompeNiDevuelveDeMas() {
        Id oportunidadId = AgentesTestDataFactory.primeraAbierta().Id;
        crearHistorial(oportunidadId);
        User soloLectura = AgentesTestDataFactory.usuario(AgentesTestDataFactory.APELLIDO_SOLO_LECTURA);
        List<AgentesLeerHistorialOportunidad.Resultado> resultados;
        Test.startTest();
        System.runAs(soloLectura) {
            resultados = leer(new List<AgentesLeerHistorialOportunidad.Solicitud>{ solicitud(oportunidadId, MAXIMO) });
        }
        Test.stopTest();
        // Según la compartición y los permisos de campo de la org, lee lo que puede ver o falla
        // con el motivo; nunca devuelve más actividades de las que hay ni lanza una excepción.
        Assert.isTrue(String.isNotBlank(resultados[0].mensaje));
        Assert.isTrue(resultados[0].tareas.size() <= 3);
        if (!resultados[0].exito) {
            Assert.isTrue(resultados[0].tareas.isEmpty());
        }
    }
}
