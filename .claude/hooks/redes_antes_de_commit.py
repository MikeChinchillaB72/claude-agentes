"""Hook PreToolUse de Claude Code: corre las redes y BLOQUEA el commit si alguna falla.

Por qué existe: una regla que hay que acordarse de correr no es una red. Esto lo
ejecuta Claude Code, no el modelo, así que no depende de que nadie se acuerde.

Lo llama .claude/settings.json en cada llamada a Bash. Recibe el JSON de la
llamada por la entrada estándar y solo actúa si el comando contiene `git commit`
(lo normal es `git add -A && git commit ...`, por eso se busca dentro del texto).

Respuestas:
- No es un commit, o las redes están en verde: sale con 0 sin escribir nada.
- Alguna red falla: escribe `permissionDecision: "deny"` con los hallazgos.
- El propio hook falla (JSON roto, Python sin `tomllib`...): sale con error y,
  como settings.json declara `onFailure: "block"`, el commit también se bloquea.
  Fallar hace ruido (regla T12 de docs/REGLAS.md).
"""

import json
import os
import subprocess
import sys
from pathlib import Path


def main() -> int:
    """Lee la llamada a Bash, y si es un commit ejecuta `python -m redes` en la raíz del proyecto."""
    llamada = json.load(sys.stdin)
    comando = llamada.get("tool_input", {}).get("command", "")
    if "git commit" not in comando:
        return 0

    raiz = Path(os.environ.get("CLAUDE_PROJECT_DIR") or Path(__file__).resolve().parents[2])
    resultado = subprocess.run(
        [sys.executable, "-m", "redes"], cwd=raiz, capture_output=True, text=True, check=False
    )
    if resultado.returncode == 0:
        return 0

    motivo = (
        "Commit bloqueado: falló una red de docs/REGLAS.md. Arregla el fallo; no lo silencies "
        "ni añadas una excepción sin motivo escrito.\n\n" + resultado.stdout + resultado.stderr
    )
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": motivo,
        }
    }))
    return 0


if __name__ == "__main__":
    sys.exit(main())
