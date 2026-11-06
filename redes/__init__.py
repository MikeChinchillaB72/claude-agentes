"""Redes: revisiones automáticas que hacen cumplir docs/REGLAS.md.

Premisa (regla T1 de docs/REGLAS.md): un estándar se sostiene con
una red ejecutable, no con un documento. Cada red es un módulo con:
- `NOMBRE`: cómo se llama la red (y cómo la nombra docs/REGLAS.md);
- `revisar(raiz, config) -> list[Hallazgo]`: lista vacía si todo está bien.

Se ejecutan con `python -m redes` (todas) o `python -m redes secretos docs`.
Su configuración está en config/redes.toml. Solo usan la biblioteca estándar.
"""

from redes import docs, docstrings, generados, literales, pendientes, secretos, silencios, vocabulario

# Orden de ejecución: primero la que protege lo irreversible.
REDES = (secretos, silencios, literales, docstrings, vocabulario, generados, pendientes, docs)

__all__ = ["REDES"]
