# claude-agentes

Agentes y plugins de Claude en Python con el Claude Agent SDK. Se trabaja en español.

- **Reglas de trabajo:** lee y cumple [docs/REGLAS.md](docs/REGLAS.md) en todo cambio
  (M1–M9 de Miguel, T1–T16 de TeloHago). En corto: nada se cambia sin el «hazlo» de Miguel; no asumir; investigar mejores
  prácticas actuales antes de crear; preguntar a Miguel lo que es decisión suya y no
  preguntar lo que se sabe; no dejar nada pendiente sin escribirlo en
  `docs/pendientes.md`; documentar todo y el código; nada ajustable en el código.
- **Estándares de agentes:** [docs/ESTANDARES.md](docs/ESTANDARES.md).
- **Documentación:** la puerta de entrada es [docs/README.md](docs/README.md). Cada
  jornada se anota en `docs/cambios_AAAA-MM-DD.md`.
- Los agentes nuevos parten de `agentes/plantilla_agente.py` y `config/agentes/plantilla.toml`,
  y se ejecutan con `ejecutar_agente()`. Sus valores van en `config/` ([docs/CONFIGURACION.md](docs/CONFIGURACION.md)).
- Los plugins están en `plugins/` y su catálogo en `.claude-plugin/marketplace.json`. Cinco son de solo
  lectura (servidor `sobject-reads` y app de monday.com sin *scopes* de escritura). `ventas-seguimiento`
  0.2.0 escribe tres acciones confirmadas: en Salesforce, Apex en el servidor personalizado `AgentesCRM`
  ([salesforce/](salesforce/README.md)); nunca escritura genérica (`sobject-mutations`, `sobject-all`). Comprueba
  con `claude plugin validate .` y actualiza sus 7 documentos y `docs/cliente/` en el mismo cambio.
- Las herramientas con efectos nunca van en `herramientas.lectura`; van en `herramientas.sensibles`
  y pasan por `politica_de_herramientas()`.
- Antes de proponer un cambio: `python -m redes` y `pytest`. El hook de commit corre las redes
  y deniega el commit si alguna falla: arregla el fallo, no lo silencies.
