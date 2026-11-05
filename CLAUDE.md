# claude-agentes

Agentes de Claude en Python con el Claude Agent SDK. Se trabaja en español.

- Lee y cumple `docs/ESTANDARES.md` en cualquier cambio a un agente.
- Los agentes nuevos parten de `agentes/plantilla_agente.py` y se ejecutan con `ejecutar_agente()`.
- Las herramientas con efectos nunca van en `allowed_tools`; usan `politica_de_herramientas()`.
- Antes de proponer un cambio: `pytest`.
