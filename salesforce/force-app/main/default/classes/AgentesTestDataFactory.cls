/**
 * Fábrica de datos de prueba de las acciones de los agentes de ventas y de servicio.
 *
 * Es el único sitio donde se crean los datos de las pruebas (regla T10): la cuenta, el
 * contacto, las oportunidades abiertas y la cerrada, los casos y los dos usuarios con permisos
 * mínimos. Cada clase de prueba la llama desde su `@TestSetup`.
 *
 * No supone nada de la org:
 * - Las etapas se leen de `OpportunityStage` (la primera abierta y la primera cerrada).
 * - El perfil de los usuarios de prueba se busca por sus permisos, no por su nombre, porque
 *   los nombres de los perfiles estándar se traducen al idioma del usuario. Se elige un
 *   perfil de licencia Salesforce que no lee oportunidades ni casos, no crea tareas y no tiene
 *   «Ver todos los datos» ni «Modificar todos los datos» (en una org nueva es
 *   «Minimum Access - Salesforce»).
 */
@IsTest
public class AgentesTestDataFactory {

    /** Nombre de la cuenta de prueba. */
    public static final String NOMBRE_CUENTA = 'PRUEBA-Acciones';

    /** Apellido del contacto de prueba. */
    public static final String APELLIDO_CONTACTO = 'PRUEBA-Contacto';

    /** Prefijo de las oportunidades abiertas; les sigue un número de tres cifras. */
    public static final String PREFIJO_ABIERTA = 'PRUEBA-Abierta-';

    /** Nombre de la oportunidad cerrada. */
    public static final String NOMBRE_CERRADA = 'PRUEBA-Cerrada';

    /** Próximo paso con el que se crean las oportunidades abiertas. */
    public static final String PASO_INICIAL = 'Paso viejo';

    /** Días que lleva vencida la fecha de cierre de las oportunidades abiertas. */
    public static final Integer DIAS_VENCIDA = 3;

    /** Registros de las pruebas masivas: el tamaño de un lote de trigger. */
    public static final Integer CANTIDAD_MASIVA = 200;

    /** Prefijo del asunto de los casos de prueba; le sigue un número de tres cifras. */
    public static final String PREFIJO_CASO = 'PRUEBA-Caso-';

    /** Usuario que no puede leer oportunidades ni casos. */
    public static final String APELLIDO_SIN_ACCESO = 'PRUEBA-SinAcceso';

    /** Usuario que lee oportunidades y casos pero no los edita ni crea tareas. */
    public static final String APELLIDO_SOLO_LECTURA = 'PRUEBA-SoloLectura';

    /**
     * Se lanza si la org no tiene un perfil con permisos mínimos para los usuarios de prueba.
     * Apex no trae `IllegalStateException`, así que la fábrica define la suya.
     */
    public class PerfilNoEncontradoException extends Exception {}

    /** Nombre del conjunto de permisos de solo lectura que se crea en la prueba. */
    private static final String PERMISOS_SOLO_LECTURA = 'PRUEBA_Agentes_Solo_Lectura';

    /**
     * Crea todo lo que usan las pruebas: los dos usuarios, una cuenta, un contacto,
     * `cantidadAbiertas` oportunidades abiertas y una cerrada.
     *
     * @param cantidadAbiertas Oportunidades abiertas que se crean.
     */
    public static void crearEscenario(Integer cantidadAbiertas) {
        crearUsuarios();
        Account cuenta = crearCuenta();
        crearContacto(cuenta.Id);
        crearOportunidadesAbiertas(cuenta.Id, cantidadAbiertas);
        crearOportunidadCerrada(cuenta.Id);
    }

    /**
     * Crea lo que usan las pruebas de servicio: los dos usuarios, una cuenta, un contacto y
     * `cantidadCasos` casos abiertos de esa cuenta y ese contacto.
     *
     * @param cantidadCasos Casos que se crean.
     */
    public static void crearEscenarioServicio(Integer cantidadCasos) {
        crearUsuarios();
        Account cuenta = crearCuenta();
        Contact contacto = crearContacto(cuenta.Id);
        crearCasos(cuenta.Id, contacto.Id, cantidadCasos);
    }

    /**
     * Crea casos con el estado y la prioridad por defecto de la org.
     *
     * @param cuentaId Cuenta de los casos; puede ser `null`.
     * @param contactoId Contacto de los casos; puede ser `null`.
     * @param cantidad Cuántos.
     * @return Los casos, ya insertados, en orden de asunto.
     */
    public static List<Case> crearCasos(Id cuentaId, Id contactoId, Integer cantidad) {
        List<Case> casos = new List<Case>();
        for (Integer i = 0; i < cantidad; i++) {
            casos.add(new Case(
                Subject = PREFIJO_CASO + String.valueOf(i).leftPad(3, '0'),
                Description = 'Descripción de prueba ' + i,
                AccountId = cuentaId,
                ContactId = contactoId
            ));
        }
        insert casos;
        return casos;
    }

    /** @return Los casos de prueba, en orden de asunto. */
    public static List<Case> casos() {
        return [
            SELECT Id, Subject, CaseNumber FROM Case
            WHERE Subject LIKE :(PREFIJO_CASO + '%')
            ORDER BY Subject
        ];
    }

    /** @return El `ApiName` del primer estado cerrado de caso de la org. */
    public static String estadoCasoCerrado() {
        return [SELECT ApiName FROM CaseStatus WHERE IsClosed = true ORDER BY SortOrder LIMIT 1].ApiName;
    }

    /** @return El `ApiName` de la primera etapa abierta y activa de la org. */
    public static String etapaAbierta() {
        return [
            SELECT ApiName FROM OpportunityStage
            WHERE IsActive = true AND IsClosed = false
            ORDER BY SortOrder LIMIT 1
        ].ApiName;
    }

    /** @return El `ApiName` de la primera etapa cerrada y activa de la org. */
    public static String etapaCerrada() {
        return [
            SELECT ApiName FROM OpportunityStage
            WHERE IsActive = true AND IsClosed = true
            ORDER BY SortOrder LIMIT 1
        ].ApiName;
    }

    /** @return La cuenta de prueba, ya insertada. */
    public static Account crearCuenta() {
        Account cuenta = new Account(Name = NOMBRE_CUENTA);
        insert cuenta;
        return cuenta;
    }

    /**
     * @param cuentaId Cuenta del contacto.
     * @return El contacto de prueba, ya insertado.
     */
    public static Contact crearContacto(Id cuentaId) {
        Contact contacto = new Contact(LastName = APELLIDO_CONTACTO, AccountId = cuentaId);
        insert contacto;
        return contacto;
    }

    /**
     * Crea oportunidades abiertas con la fecha de cierre vencida y `PASO_INICIAL`.
     *
     * @param cuentaId Cuenta de las oportunidades.
     * @param cantidad Cuántas.
     * @return Las oportunidades, ya insertadas, en orden de nombre.
     */
    public static List<Opportunity> crearOportunidadesAbiertas(Id cuentaId, Integer cantidad) {
        String etapa = etapaAbierta();
        List<Opportunity> oportunidades = new List<Opportunity>();
        for (Integer i = 0; i < cantidad; i++) {
            oportunidades.add(new Opportunity(
                Name = PREFIJO_ABIERTA + String.valueOf(i).leftPad(3, '0'),
                AccountId = cuentaId,
                StageName = etapa,
                CloseDate = Date.today().addDays(-DIAS_VENCIDA),
                NextStep = PASO_INICIAL
            ));
        }
        insert oportunidades;
        return oportunidades;
    }

    /**
     * @param cuentaId Cuenta de la oportunidad.
     * @return La oportunidad cerrada, ya insertada, sin próximo paso.
     */
    public static Opportunity crearOportunidadCerrada(Id cuentaId) {
        Opportunity cerrada = new Opportunity(
            Name = NOMBRE_CERRADA,
            AccountId = cuentaId,
            StageName = etapaCerrada(),
            CloseDate = Date.today().addDays(-10)
        );
        insert cerrada;
        return cerrada;
    }

    /**
     * Crea los dos usuarios de prueba. Los objetos de configuración (usuarios y permisos)
     * se insertan dentro de `System.runAs` para no mezclarlos con el DML de registros
     * (error MIXED_DML_OPERATION).
     */
    public static void crearUsuarios() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Id perfilId = perfilConPermisosMinimos();
            User sinAcceso = nuevoUsuario(APELLIDO_SIN_ACCESO, perfilId);
            User soloLectura = nuevoUsuario(APELLIDO_SOLO_LECTURA, perfilId);
            insert new List<User>{ sinAcceso, soloLectura };
            insert new PermissionSetAssignment(
                AssigneeId = soloLectura.Id,
                PermissionSetId = crearPermisosSoloLectura()
            );
        }
    }

    /**
     * @param apellido `APELLIDO_SIN_ACCESO` o `APELLIDO_SOLO_LECTURA`.
     * @return El usuario de prueba con ese apellido.
     */
    public static User usuario(String apellido) {
        return [SELECT Id FROM User WHERE LastName = :apellido AND Username LIKE 'prueba.agentes.%' LIMIT 1];
    }

    /** @return Las oportunidades abiertas de prueba, en orden de nombre. */
    public static List<Opportunity> abiertas() {
        return [
            SELECT Id, Name, NextStep, CloseDate FROM Opportunity
            WHERE Name LIKE :(PREFIJO_ABIERTA + '%')
            ORDER BY Name
        ];
    }

    /** @return La primera oportunidad abierta de prueba. */
    public static Opportunity primeraAbierta() {
        return abiertas()[0];
    }

    /** @return La oportunidad cerrada de prueba. */
    public static Opportunity cerrada() {
        return [SELECT Id, Name, NextStep, CloseDate FROM Opportunity WHERE Name = :NOMBRE_CERRADA];
    }

    /** @return La cuenta de prueba, para probar un Id que no es de oportunidad. */
    public static Account cuenta() {
        return [SELECT Id FROM Account WHERE Name = :NOMBRE_CUENTA];
    }

    /** @return El contacto de prueba. */
    public static Contact contacto() {
        return [SELECT Id FROM Contact WHERE LastName = :APELLIDO_CONTACTO];
    }

    /**
     * @param registros Registros de los que se quieren los Ids.
     * @return Sus Ids.
     */
    public static Set<Id> ids(List<SObject> registros) {
        return new Map<Id, SObject>(registros).keySet();
    }

    private static Id perfilConPermisosMinimos() {
        List<PermissionSet> perfiles = [
            SELECT ProfileId FROM PermissionSet
            WHERE IsOwnedByProfile = true
                AND Profile.UserLicense.Name = 'Salesforce'
                AND PermissionsViewAllData = false
                AND PermissionsModifyAllData = false
                AND PermissionsEditTask = false
                AND Id NOT IN (
                    SELECT ParentId FROM ObjectPermissions
                    WHERE SobjectType IN ('Opportunity', 'Case') AND PermissionsRead = true
                )
            ORDER BY Profile.Name
            LIMIT 1
        ];
        if (perfiles.isEmpty()) {
            throw new PerfilNoEncontradoException(
                'La org no tiene un perfil de licencia Salesforce sin acceso a oportunidades, casos ni tareas ' +
                '(por ejemplo «Minimum Access - Salesforce»); las pruebas de permisos lo necesitan.'
            );
        }
        return perfiles[0].ProfileId;
    }

    private static Id crearPermisosSoloLectura() {
        PermissionSet permisos = new PermissionSet(
            Name = PERMISOS_SOLO_LECTURA,
            Label = 'PRUEBA Agentes solo lectura'
        );
        insert permisos;
        // La lectura de oportunidades exige la de cuentas, así que va primero.
        insert new ObjectPermissions(ParentId = permisos.Id, SobjectType = 'Account', PermissionsRead = true);
        insert new ObjectPermissions(ParentId = permisos.Id, SobjectType = 'Opportunity', PermissionsRead = true);
        // Contactos y casos, para las pruebas de servicio.
        insert new ObjectPermissions(ParentId = permisos.Id, SobjectType = 'Contact', PermissionsRead = true);
        insert new ObjectPermissions(ParentId = permisos.Id, SobjectType = 'Case', PermissionsRead = true);
        insert new FieldPermissions(
            ParentId = permisos.Id,
            SobjectType = 'Opportunity',
            Field = 'Opportunity.NextStep',
            PermissionsRead = true,
            PermissionsEdit = false
        );
        return permisos.Id;
    }

    private static User nuevoUsuario(String apellido, Id perfilId) {
        String unico = UserInfo.getOrganizationId() + String.valueOf(Crypto.getRandomInteger()).remove('-');
        return new User(
            LastName = apellido,
            Alias = apellido.right(8),
            Email = 'prueba.agentes@example.com',
            Username = 'prueba.agentes.' + apellido.toLowerCase() + '.' + unico + '@example.com',
            ProfileId = perfilId,
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = UserInfo.getLanguage(),
            LocaleSidKey = UserInfo.getLocale(),
            TimeZoneSidKey = UserInfo.getTimeZone().getID()
        );
    }
}
