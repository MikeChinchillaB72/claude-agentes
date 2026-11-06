"""Ejecuta las redes desde la línea de comandos.

Uso:  python -m redes [nombre ...]
Sale con 0 si todo está bien, 1 si hay hallazgos y 2 si una red no pudo
ejecutarse (eso nunca cuenta como verde).
"""

from __future__ import annotations

import sys
from pathlib import Path

from redes import REDES
from redes.comun import ErrorDeRed, cargar_config


def main(argumentos: list[str], raiz: Path) -> int:
    """Ejecuta las redes pedidas (o todas) sobre `raiz` e imprime los hallazgos."""
    por_nombre = {modulo.NOMBRE: modulo for modulo in REDES}
    desconocidas = [a for a in argumentos if a not in por_nombre]
    if desconocidas:
        print(f"Redes desconocidas: {', '.join(desconocidas)}. Existen: {', '.join(por_nombre)}.", file=sys.stderr)
        return 2
    elegidas = [por_nombre[a] for a in argumentos] or list(REDES)

    try:
        config = cargar_config(raiz)
        hallazgos = [h for modulo in elegidas for h in modulo.revisar(raiz, config)]
    except ErrorDeRed as error:
        print(f"Una red no pudo ejecutarse: {error}", file=sys.stderr)
        return 2

    for hallazgo in hallazgos:
        print(hallazgo)
    nombres = ", ".join(m.NOMBRE for m in elegidas)
    if hallazgos:
        print(f"\n{len(hallazgos)} hallazgo(s) en: {nombres}.", file=sys.stderr)
        return 1
    print(f"Redes en verde: {nombres}.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:], Path.cwd()))
