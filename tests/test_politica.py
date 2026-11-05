"""La política de herramientas se prueba sin llamar a la API."""

from claude_agent_sdk import PermissionResultAllow, PermissionResultDeny, ToolPermissionContext

from agentes import politica_de_herramientas

CTX = ToolPermissionContext()


async def aprobar(nombre, entrada):
    return True


async def test_sensible_sin_aprobador_se_deniega():
    politica = politica_de_herramientas(["Write"])
    assert isinstance(await politica("Write", {}, CTX), PermissionResultDeny)


async def test_sensible_con_aprobacion_se_permite():
    politica = politica_de_herramientas(["Write"], aprobador=aprobar)
    assert isinstance(await politica("Write", {}, CTX), PermissionResultAllow)


async def test_herramienta_no_prevista_se_deniega():
    politica = politica_de_herramientas(["Write"], aprobador=aprobar)
    assert isinstance(await politica("Bash", {"command": "rm -rf /"}, CTX), PermissionResultDeny)
