"""Cada red se prueba en verde y rompiéndola a propósito (regla T2 de docs/REGLAS.md).

Cada test trabaja sobre una copia del repositorio en una carpeta temporal con su
propio `git init`, mete una violación y comprueba que la red la caza. Así una red
que dejara de detectar su fallo daría rojo aquí.
"""

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

import pytest

from redes import REDES, docs, docstrings, generados, literales, pendientes, secretos, silencios, vocabulario
from redes.__main__ import main
from redes.comun import ErrorDeRed, archivos_del_repositorio, cargar_config

RAIZ = Path(__file__).resolve().parent.parent


@pytest.fixture
def copia(tmp_path: Path) -> Path:
    """Copia de los archivos del repositorio en un git nuevo (sin commits: git lista los no ignorados)."""
    for nombre in archivos_del_repositorio(RAIZ, cargar_config(RAIZ)):
        destino = tmp_path / nombre
        destino.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(RAIZ / nombre, destino)
    subprocess.run(["git", "init", "-q"], cwd=tmp_path, check=True)
    return tmp_path


def escribir(raiz: Path, nombre: str, texto: str) -> None:
    """Crea o sustituye un archivo dentro de la copia."""
    ruta = raiz / nombre
    ruta.parent.mkdir(parents=True, exist_ok=True)
    ruta.write_text(texto, encoding="utf-8")


def hallazgos(modulo, raiz: Path) -> list[str]:
    """Ejecuta una red sobre `raiz` y devuelve sus hallazgos como texto."""
    return [str(h) for h in modulo.revisar(raiz, cargar_config(raiz))]


# ── El repositorio real está en verde ───────────────────────────────────────


@pytest.mark.parametrize("modulo", REDES, ids=lambda m: m.NOMBRE)
def test_el_repositorio_esta_en_verde(modulo):
    assert hallazgos(modulo, RAIZ) == []


# ── Cada red caza su fallo ──────────────────────────────────────────────────


def test_secretos_caza_una_clave(copia):
    clave = "sk-ant-" + "a" * 30  # se arma en tiempo de ejecución para no versionar una clave falsa
    escribir(copia, "agentes/filtrado.py", f'"""m."""\nCLAVE = "{clave}"\n')
    resultado = hallazgos(secretos, copia)
    assert any("agentes/filtrado.py:2" in h and "anthropic" in h for h in resultado)
    assert not any(clave in h for h in resultado), "la red no debe imprimir el secreto"


def test_secretos_caza_un_env(copia):
    escribir(copia, "config/.env", "X=1\n")
    subprocess.run(["git", "add", "-f", "config/.env"], cwd=copia, check=True)  # forzado: .gitignore lo ignora
    assert any("config/.env" in h for h in hallazgos(secretos, copia))


def test_silencios_caza_un_except_mudo(copia):
    escribir(copia, "agentes/mudo.py", '"""m."""\ntry:\n    x = 1\nexcept Exception:\n    pass\n')
    assert any("agentes/mudo.py:4" in h for h in hallazgos(silencios, copia))


def test_silencios_acepta_el_marcador_con_motivo(copia):
    escribir(copia, "agentes/mudo.py", '"""m."""\ntry:\n    x = 1\nexcept KeyError:  # silencio-permitido: motivo\n    pass\n')
    assert hallazgos(silencios, copia) == []


def test_silencios_rechaza_el_marcador_sin_motivo(copia):
    escribir(copia, "agentes/mudo.py", '"""m."""\ntry:\n    x = 1\nexcept KeyError:  # silencio-permitido:\n    return\n')
    assert any("agentes/mudo.py:4" in h for h in hallazgos(silencios, copia))


def test_literales_caza_un_modelo_en_el_codigo(copia):
    modelo = "claude-" + "opus-5-5"
    escribir(copia, "agentes/fijo.py", f'"""m."""\nMODELO = "{modelo}"\nopciones = dict(max_turns=3)\n')
    resultado = hallazgos(literales, copia)
    assert any("agentes/fijo.py:2" in h for h in resultado)
    assert any("agentes/fijo.py:3" in h for h in resultado)


def test_docstrings_caza_una_funcion_sin_documentar(copia):
    escribir(copia, "agentes/sin_doc.py", "def publica():\n    return 1\n\ndef _privada():\n    return 2\n")
    resultado = hallazgos(docstrings, copia)
    assert any("agentes/sin_doc.py:1" in h and "módulo" in h for h in resultado)
    assert any("`publica`" in h for h in resultado)
    assert not any("_privada" in h for h in resultado)


def test_vocabulario_caza_un_nombre_mal_escrito(copia):
    mal = "Services" + " Cloud"
    escribir(copia, "docs/nota.md", f"Plugins para {mal}.\n")
    assert any("docs/nota.md:1" in h and "Service Cloud" in h for h in hallazgos(vocabulario, copia))


def test_generados_caza_un_pdf(copia):
    (copia / "docs" / "exportado.pdf").write_bytes(b"%PDF-1.7")
    assert any("docs/exportado.pdf" in h for h in hallazgos(generados, copia))


def test_pendientes_caza_un_punto_tachado(copia):
    texto = (copia / "docs" / "pendientes.md").read_text(encoding="utf-8")
    escribir(copia, "docs/pendientes.md", texto + "\n- ~~P9 · algo ya hecho~~\n")
    assert any("muévelo" in h for h in hallazgos(pendientes, copia))


def test_docs_caza_un_enlace_roto(copia):
    escribir(copia, "docs/nota.md", "Ver [esto](no-existe.md).\n")
    assert any("enlace roto: no-existe.md" in h for h in hallazgos(docs, copia))


def test_docs_caza_una_clave_sin_documentar(copia):
    ruta = copia / "config" / "agentes.toml"
    ruta.write_text(ruta.read_text(encoding="utf-8") + "\n[nueva]\nvalor = 1\n", encoding="utf-8")
    resultado = hallazgos(docs, copia)
    assert any("`nueva`" in h for h in resultado) and any("`nueva.valor`" in h for h in resultado)


def test_docs_caza_una_red_que_reglas_no_nombra(copia):
    ruta = copia / "docs" / "REGLAS.md"
    ruta.write_text(ruta.read_text(encoding="utf-8").replace("`vocabulario`", "vocabulario"), encoding="utf-8")
    assert any("no menciona la red `vocabulario`" in h for h in hallazgos(docs, copia))


def test_docs_caza_un_enlace_obligatorio_que_falta(copia):
    ruta = copia / "CLAUDE.md"
    ruta.write_text(ruta.read_text(encoding="utf-8").replace("(docs/REGLAS.md)", ""), encoding="utf-8")
    assert any("CLAUDE.md" in h and "docs/REGLAS.md" in h for h in hallazgos(docs, copia))


# ── Fallar hace ruido (T3 y T12) ────────────────────────────────────────────


def test_excepcion_sin_motivo_hace_fallar_la_red(copia):
    ruta = copia / "config" / "redes.toml"
    ruta.write_text(
        ruta.read_text(encoding="utf-8").replace(
            'motivo = "Contiene los patrones de búsqueda, no credenciales."', 'motivo = ""'
        ),
        encoding="utf-8",
    )
    with pytest.raises(ErrorDeRed, match="no tiene motivo"):
        hallazgos(secretos, copia)


def test_sin_git_la_red_no_da_verde(tmp_path):
    shutil.copytree(RAIZ / "config", tmp_path / "config")
    with pytest.raises(ErrorDeRed):
        hallazgos(secretos, tmp_path)


def test_la_linea_de_comandos_devuelve_1_con_hallazgos(copia, capsys):
    (copia / "informe.docx").write_bytes(b"x")
    assert main(["generados"], copia) == 1
    assert main([], RAIZ) == 0
    assert main(["no-existe"], RAIZ) == 2


# ── El hook de commit ───────────────────────────────────────────────────────

HOOK = RAIZ / ".claude" / "hooks" / "redes_antes_de_commit.py"


def correr_hook(proyecto: Path, comando: str) -> subprocess.CompletedProcess:
    """Llama al hook como lo hace Claude Code: JSON por la entrada estándar."""
    entorno = {**os.environ, "CLAUDE_PROJECT_DIR": str(proyecto), "PYTHONPATH": str(proyecto)}
    return subprocess.run(
        [sys.executable, str(HOOK)],
        input=json.dumps({"tool_name": "Bash", "tool_input": {"command": comando}}),
        capture_output=True,
        text=True,
        env=entorno,
        check=False,
    )


def test_el_hook_ignora_lo_que_no_es_un_commit(copia):
    (copia / "informe.docx").write_bytes(b"x")
    resultado = correr_hook(copia, "ls -la")
    assert resultado.returncode == 0 and resultado.stdout == ""


def test_el_hook_deja_pasar_un_commit_en_verde(copia):
    resultado = correr_hook(copia, "git add -A && git commit -m x")
    assert resultado.returncode == 0 and resultado.stdout == "", resultado.stdout + resultado.stderr


def test_el_hook_deniega_un_commit_en_rojo(copia):
    (copia / "informe.docx").write_bytes(b"x")
    resultado = correr_hook(copia, "git add -A && git commit -m x")
    salida = json.loads(resultado.stdout)["hookSpecificOutput"]
    assert salida["permissionDecision"] == "deny"
    assert "informe.docx" in salida["permissionDecisionReason"]


def test_el_hook_falla_con_ruido_si_la_entrada_esta_rota(copia):
    resultado = subprocess.run([sys.executable, str(HOOK)], input="no es json", capture_output=True, text=True, check=False)
    assert resultado.returncode != 0
