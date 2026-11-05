"""Las herramientas se prueban como funciones normales, sin llamar a la API."""

import importlib.util
from pathlib import Path

ruta = Path(__file__).parent.parent / "ejemplos" / "02_herramienta_propia.py"
spec = importlib.util.spec_from_file_location("herramienta_propia", ruta)
modulo = importlib.util.module_from_spec(spec)
spec.loader.exec_module(modulo)


async def test_producto_existente():
    r = await modulo.consultar_stock.handler({"producto": "Teclado"})
    assert r["content"][0]["text"] == "teclado: 12 unidades"


async def test_producto_inexistente():
    r = await modulo.consultar_stock.handler({"producto": "silla"})
    assert r["is_error"] is True
