# Hecho

> Pendientes cerrados, el más reciente arriba. Cada punto llega aquí desde
> [pendientes.md](pendientes.md) en el mismo commit en que se cierra.

## 2026-11-07

- **P6 · Licencia de los plugins:** propietaria, todos los derechos reservados a Codexue (decisión de
  Miguel). Archivo [LICENSE](../LICENSE) en la raíz y campo `license` en cada `plugin.json`.
- **P7 · ¿Algún plugin debe escribir en el CRM?** Decisión de Miguel: **solo lectura por ahora**. Se
  vuelve a decidir cuando lleguen los requisitos del cliente (P1) y haya pruebas en plataforma real.
- **P8 · Validación de plugins en CI:** job `plugins` en `.github/workflows/pruebas.yml`, que valida el
  catálogo y cada plugin. Miguel decidió que sea check obligatorio: hay que añadirlo al ruleset
  `proteger-main` después de fusionar.
- **Regla M9** («nada se cambia sin el hazlo de Miguel») escrita en [REGLAS.md](REGLAS.md), por decisión de Miguel.

## 2026-11-06

- **P2 · Protecciones de GitHub activadas** por Miguel:
  - *Secret Protection* y *Push protection*: GitHub rechaza cualquier push que contenga un secreto reconocido.
  - Ruleset `proteger-main` sobre la rama por defecto: impide borrarla y hacer force push, y exige
    PR (0 aprobaciones, porque Miguel es el único revisor) y los checks `redes-y-pytest` y `secretos`
    de GitHub Actions.
- **Reglas de trabajo adoptadas** en [REGLAS.md](REGLAS.md): las 8 de Miguel y las 16 de
  TeloHago que aplican, con 8 redes ejecutables, hook de commit y CI. Detalle en
  [cambios_2026-11-06.md](cambios_2026-11-06.md).
