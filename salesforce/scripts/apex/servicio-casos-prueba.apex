// Datos de prueba para los agentes de servicio (fase 0 de salesforce/agentforce/servicio-conocimiento.md).
//
// Crea una cuenta y un contacto PRUEBA, diez casos cerrados con su solución en un comentario
// interno y cuatro casos abiertos. Los casos abiertos se parecen a algunos cerrados, para probar
// la búsqueda de casos parecidos, y uno trata un tema que no cubre ningún caso ni artículo, para
// probar que el agente dice «no lo sé». Todo lleva el prefijo PRUEBA: no son datos reales.
//
// Se ejecuta una sola vez, desde salesforce/:
//   sf apex run --target-org agentes-crm --file scripts/apex/servicio-casos-prueba.apex
// Si la cuenta ya existe, no crea nada.

final String NOMBRE_CUENTA = 'PRUEBA-Servicio Soporte';

if (![SELECT Id FROM Account WHERE Name = :NOMBRE_CUENTA LIMIT 1].isEmpty()) {
    System.debug(LoggingLevel.WARN, 'Los datos de prueba ya existen; no se crea nada.');
    return;
}

String estadoCerrado = [SELECT ApiName FROM CaseStatus WHERE IsClosed = true ORDER BY SortOrder LIMIT 1].ApiName;

Account cuenta = new Account(Name = NOMBRE_CUENTA);
insert cuenta;
Contact contacto = new Contact(FirstName = 'Ana', LastName = 'PRUEBA-Servicio', AccountId = cuenta.Id);
insert contacto;

// Asunto, descripción y solución de cada caso cerrado.
List<List<String>> cerrados = new List<List<String>>{
    new List<String>{ 'PRUEBA No puedo entrar al portal', 'El cliente dice que su contraseña no funciona desde ayer.', 'Se le explicó cómo restablecer la contraseña con el enlace «¿Olvidaste tu contraseña?». El enlace caduca a las 24 horas.' },
    new List<String>{ 'PRUEBA Contraseña bloqueada', 'Tras cinco intentos el portal bloqueó la cuenta.', 'El bloqueo dura 30 minutos. Pasado ese tiempo, el cliente restableció la contraseña con el enlace del portal.' },
    new List<String>{ 'PRUEBA Me cobraron dos veces', 'Aparecen dos cargos iguales de la factura de octubre.', 'Era un cargo pendiente que el banco libera en 3 a 5 días hábiles. No hizo falta reembolso.' },
    new List<String>{ 'PRUEBA Factura duplicada', 'Recibí dos facturas con el mismo número.', 'Se anuló la factura repetida desde Facturación y se envió la correcta por correo.' },
    new List<String>{ 'PRUEBA La app no sincroniza', 'Los cambios del móvil no aparecen en la web.', 'Se pidió cerrar sesión, actualizar la app a la última versión y volver a entrar. La sincronización volvió.' },
    new List<String>{ 'PRUEBA Datos que no aparecen en la web', 'Lo que guardo en el teléfono no sale en el ordenador.', 'La app estaba en una versión antigua. Tras actualizarla, los datos se sincronizaron.' },
    new List<String>{ 'PRUEBA Cambiar dirección de envío', 'Quiero que el próximo pedido llegue a otra dirección.', 'El cliente cambió la dirección en Mi cuenta > Direcciones. Los pedidos ya enviados no se pueden desviar.' },
    new List<String>{ 'PRUEBA Error 504 al exportar', 'Al exportar el informe anual sale un error 504.', 'El informe superaba el tiempo máximo. Se exportó por meses y luego se unieron los archivos.' },
    new List<String>{ 'PRUEBA Exportación que no termina', 'La exportación de todo el año se queda cargando.', 'Se recomendó exportar por trimestres. Con periodos más cortos terminó sin error.' },
    new List<String>{ 'PRUEBA Cancelar suscripción', 'Quiero cancelar el plan mensual.', 'Se canceló desde Mi cuenta > Plan. El servicio sigue activo hasta el final del periodo pagado.' }
};

// Asunto y descripción de cada caso abierto.
List<List<String>> abiertos = new List<List<String>>{
    new List<String>{ 'PRUEBA Olvidé mi contraseña', 'No recuerdo la contraseña y el portal no me deja entrar.' },
    new List<String>{ 'PRUEBA Cargo repetido en mi tarjeta', 'Veo el mismo importe cobrado dos veces este mes.' },
    new List<String>{ 'PRUEBA El informe no se descarga', 'Intento exportar los datos de 2025 y da error.' },
    new List<String>{ 'PRUEBA Cambio de titular del contrato', 'La empresa cambió de razón social y queremos pasar el contrato al nuevo titular.' }
};

List<Case> casos = new List<Case>();
for (List<String> datos : cerrados) {
    casos.add(new Case(Subject = datos[0], Description = datos[1], AccountId = cuenta.Id, ContactId = contacto.Id, Origin = 'Web'));
}
for (List<String> datos : abiertos) {
    casos.add(new Case(Subject = datos[0], Description = datos[1], AccountId = cuenta.Id, ContactId = contacto.Id, Origin = 'Web'));
}
insert casos;

List<CaseComment> soluciones = new List<CaseComment>();
for (Integer i = 0; i < cerrados.size(); i++) {
    soluciones.add(new CaseComment(ParentId = casos[i].Id, CommentBody = 'Solución: ' + cerrados[i][2], IsPublished = false));
}
insert soluciones;

List<Case> aCerrar = new List<Case>();
for (Integer i = 0; i < cerrados.size(); i++) {
    aCerrar.add(new Case(Id = casos[i].Id, Status = estadoCerrado));
}
update aCerrar;

System.debug(LoggingLevel.INFO, 'Creados ' + cerrados.size() + ' casos cerrados y ' + abiertos.size() + ' abiertos en ' + NOMBRE_CUENTA + '.');
