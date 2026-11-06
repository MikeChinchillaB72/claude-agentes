"""La configuración se carga, se valida y falla con ruido (reglas M7, T12 y T13)."""

import logging
import shutil
from pathlib import Path

import pytest

from agentes import CONFIG, FiltroDatosPersonales, cargar, opciones_de_agente
from agentes.configuracion import ErrorDeConfiguracion, cargar_agente, cargar_config_general

RAIZ = Path(__file__).resolve().parent.parent


@pytest.fixture
def config(tmp_path: Path) -> Path:
    """Copia de config/ que cada test puede romper sin tocar la real."""
    destino = tmp_path / "config"
    shutil.copytree(RAIZ / "config", destino)
    return destino


def reemplazar(ruta: Path, antes: str, despues: str) -> None:
    """Cambia un texto en un archivo de configuración, comprobando que estaba."""
    texto = ruta.read_text(encoding="utf-8")
    assert antes in texto
    ruta.write_text(texto.replace(antes, despues), encoding="utf-8")


@pytest.mark.parametrize(
    "nombre", ["plantilla", "ejemplo_basico", "ejemplo_herramienta_propia", "ejemplo_subagentes"]
)
def test_todos_los_agentes_cargan(nombre):
    agente = cargar(nombre)
    opciones = opciones_de_agente(agente)
    assert opciones.model == agente.modelo == CONFIG.modelo
    assert opciones.max_turns == agente.max_turnos
    assert opciones.max_budget_usd == agente.max_presupuesto_usd
    assert opciones.permission_mode == "default"
    assert opciones.can_use_tool is not None


def test_los_subagentes_salen_de_la_configuracion():
    opciones = opciones_de_agente(cargar("ejemplo_subagentes"))
    assert set(opciones.agents) == {"revisor", "documentador"}
    assert opciones.agents["documentador"].tools == ["Read", "Glob"]


def test_la_variable_de_entorno_manda_sobre_el_archivo(config, monkeypatch):
    monkeypatch.setenv("AGENTE_MODELO", "modelo-de-prueba")
    assert cargar_config_general(config).modelo == "modelo-de-prueba"


def test_el_agente_puede_fijar_su_propio_modelo(config):
    reemplazar(config / "agentes" / "plantilla.toml", '# modelo = ""', 'modelo = "otro-modelo"')
    general = cargar_config_general(config)
    assert cargar_agente("plantilla", general, config).modelo == "otro-modelo"


def test_falta_una_clave_obligatoria(config):
    reemplazar(config / "agentes.toml", 'nivel = "INFO"', "")
    with pytest.raises(ErrorDeConfiguracion, match="registro.nivel"):
        cargar_config_general(config)


def test_tipo_no_valido(config):
    reemplazar(config / "agentes" / "plantilla.toml", "max_turnos = 10", 'max_turnos = "diez"')
    with pytest.raises(ErrorDeConfiguracion, match="limites.max_turnos"):
        cargar_agente("plantilla", cargar_config_general(config), config)


def test_un_booleano_no_pasa_por_numero(config):
    reemplazar(config / "agentes" / "plantilla.toml", "max_turnos = 10", "max_turnos = true")
    with pytest.raises(ErrorDeConfiguracion, match="limites.max_turnos"):
        cargar_agente("plantilla", cargar_config_general(config), config)


def test_una_herramienta_no_puede_ser_de_lectura_y_sensible(config):
    reemplazar(config / "agentes" / "plantilla.toml", "sensibles = []", 'sensibles = ["Read"]')
    with pytest.raises(ErrorDeConfiguracion, match="a la vez"):
        cargar_agente("plantilla", cargar_config_general(config), config)


def test_limites_deben_ser_positivos(config):
    reemplazar(config / "agentes" / "plantilla.toml", "max_presupuesto_usd = 1.0", "max_presupuesto_usd = 0")
    with pytest.raises(ErrorDeConfiguracion, match="mayores que cero"):
        cargar_agente("plantilla", cargar_config_general(config), config)


def test_agente_inexistente():
    with pytest.raises(ErrorDeConfiguracion, match="No existe"):
        cargar("no_existe")


def test_toml_roto(config):
    (config / "agentes.toml").write_text("[modelo\n", encoding="utf-8")
    with pytest.raises(ErrorDeConfiguracion, match="no es TOML válido"):
        cargar_config_general(config)


# ── Datos personales en los registros (T13) ─────────────────────────────────


def test_el_filtro_tapa_datos_personales():
    filtro = FiltroDatosPersonales(CONFIG.patrones_datos_personales, CONFIG.reemplazo_datos_personales)
    texto = filtro.tapar("Cliente ana.perez@ejemplo.com, tel +504 9999-8888, tarjeta 4111 1111 1111 1111.")
    assert "ana.perez" not in texto and "9999" not in texto and "4111" not in texto
    assert texto.count(CONFIG.reemplazo_datos_personales) == 3


def test_el_registro_de_los_agentes_sale_tapado(caplog):
    registro = logging.getLogger("agentes")
    registro.propagate = True  # para que caplog lo vea; el filtro está en el propio registro
    try:
        with caplog.at_level(logging.INFO, logger="agentes"):
            registro.info("aviso para %s", "ana.perez@ejemplo.com")
    finally:
        registro.propagate = False
    assert "ana.perez@ejemplo.com" not in caplog.text
    assert CONFIG.reemplazo_datos_personales in caplog.text
