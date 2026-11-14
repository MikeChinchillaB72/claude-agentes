// Artículos de prueba de Knowledge para los agentes de servicio (fase 0 de
// salesforce/agentforce/servicio-conocimiento.md).
//
// Solo funciona después de activar Lightning Knowledge y de marcar Knowledge User en el usuario
// que lo ejecuta. Crea y publica cinco artículos PRUEBA sobre temas de servicio-casos-prueba.apex.
// Quedan sin artículo dos temas que sí tienen casos resueltos (la dirección de envío y la
// cancelación), para probar la creación de artículos, y uno que no cubre nada (el cambio de
// titular), para probar que el agente dice que no hay artículo. El texto va en Summary, que es un campo estándar; si la
// org usa un campo propio para el cuerpo (por ejemplo Answer__c), hay que decidir cuál indexar.
//
// Se ejecuta una sola vez, desde salesforce/:
//   sf apex run --target-org agentes-crm --file scripts/apex/servicio-articulos-prueba.apex
// Si ya hay artículos PRUEBA, no crea nada.

if (![SELECT Id FROM Knowledge__kav WHERE Title LIKE 'PRUEBA %' LIMIT 1].isEmpty()) {
    System.debug(LoggingLevel.WARN, 'Los artículos de prueba ya existen; no se crea nada.');
    return;
}

// Título, nombre de URL y texto de cada artículo.
List<List<String>> datos = new List<List<String>>{
    new List<String>{ 'PRUEBA Restablecer la contraseña del portal', 'prueba-restablecer-contrasena', 'Si no puedes entrar al portal, usa el enlace «¿Olvidaste tu contraseña?» de la página de inicio. Recibirás un correo con un enlace que caduca a las 24 horas. Tras cinco intentos fallidos el portal bloquea la cuenta durante 30 minutos; pasado ese tiempo puedes restablecerla.' },
    new List<String>{ 'PRUEBA Cargos repetidos en la tarjeta', 'prueba-cargos-repetidos', 'Si ves dos cargos iguales, uno suele ser una retención pendiente que el banco libera en 3 a 5 días hábiles. Si después de 5 días hábiles siguen los dos cargos, abre un caso con el número de factura para revisar un reembolso.' },
    new List<String>{ 'PRUEBA Facturas duplicadas', 'prueba-facturas-duplicadas', 'Si recibes dos facturas con el mismo número, el equipo de Facturación anula la repetida y te envía la correcta por correo. No hace falta pagar las dos.' },
    new List<String>{ 'PRUEBA La app no sincroniza con la web', 'prueba-app-no-sincroniza', 'Si los cambios del móvil no aparecen en la web: 1. Actualiza la app a la última versión. 2. Cierra sesión. 3. Vuelve a entrar. Las versiones antiguas de la app no sincronizan.' },
    new List<String>{ 'PRUEBA Exportar informes grandes', 'prueba-exportar-informes', 'Las exportaciones tienen un tiempo máximo. Si un informe de todo el año da error 504 o no termina, expórtalo por meses o por trimestres y une los archivos después.' }
};

List<Knowledge__kav> articulos = new List<Knowledge__kav>();
for (List<String> articulo : datos) {
    articulos.add(new Knowledge__kav(Title = articulo[0], UrlName = articulo[1], Summary = articulo[2]));
}
insert articulos;

for (Knowledge__kav articulo : [SELECT KnowledgeArticleId FROM Knowledge__kav WHERE Id IN :articulos]) {
    KbManagement.PublishingService.publishArticle(articulo.KnowledgeArticleId, true);
}

System.debug(LoggingLevel.INFO, 'Creados y publicados ' + articulos.size() + ' artículos PRUEBA.');
