# Lista de revisión por agente

Cópiala en el pull request que añade o cambia un agente.

## Diseño
- [ ] La arquitectura elegida (API, SDK, Managed Agents, plugin) está justificada
- [ ] Responsable del agente: ___
- [ ] Herramientas: cada una hace una sola cosa y valida sus parámetros

## Seguridad
- [ ] `allowed_tools` solo tiene herramientas de lectura
- [ ] Las herramientas con efectos están en `HERRAMIENTAS_SENSIBLES` y requieren aprobación
- [ ] Ningún identificador de usuario o cliente lo decide el modelo
- [ ] El contenido externo se trata como datos; el agente que lo lee no escribe sin control
- [ ] Sin `Bash` salvo necesidad, y entonces con `SANDBOX_ESTRICTO`
- [ ] Sin `bypassPermissions`
- [ ] Secretos fuera del código; clave de API propia del agente
- [ ] `max_turns` y `max_budget_usd` definidos
- [ ] Datos personales: qué campos llegan al modelo y cuáles se enmascaran

## Calidad
- [ ] Evaluaciones en `evals/<agente>/` con resultado registrado en el PR
- [ ] Pruebas de herramientas sin API
- [ ] Salidas que lee el código con esquema JSON
- [ ] `VERSION` actualizada

## Plataforma real (regla T5)
- [ ] Probado en un sandbox de Salesforce o una cuenta de prueba de Monday, con el resultado en el PR
- [ ] Sus valores están en `config/` y documentados en `docs/CONFIGURACION.md`
- [ ] `python -m redes` en verde

## Operación
- [ ] Costo medido con ejecuciones reales y dentro del presupuesto
- [ ] Alertas de costo y errores
- [ ] Se puede apagar sin desplegar
