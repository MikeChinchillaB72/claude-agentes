# Crear el agente de Agentforce paso a paso

> Actualizado: 2026-11-08. Es el orden en que se creó el «Asistente de Seguimiento» en la Developer
> Edition, con Claude como modelo. Los textos que se copian (descripción, instrucciones, acciones) están
> en [seguimiento-oportunidades.md](seguimiento-oportunidades.md); aquí solo se dice qué hacer y dónde.

## Antes de empezar

- Una org con Agentforce. La Developer Edition gratuita lo trae.
- Las clases Apex de [`salesforce/`](../README.md) desplegadas, con sus pruebas pasando.
- El Permission Set **Agentes CRM - Acciones** (`Agentes_CRM_Acciones`) con las 5 clases.

## 1. Preparar la org

1. **Setup > Einstein Setup:** activar Einstein.
2. **Setup > Agentforce Agents:** activar Agentforce.

## 2. Subir el Apex

3. En **Developer Console**, crear las clases en este orden: `AgentesCrmAcciones` (reglas comunes),
   las 5 acciones y, al final, `AgentesTestDataFactory` y una clase de prueba por cada acción
   (ver [salesforce/README.md](../README.md)).
4. Correr las pruebas (**Test > Run All**) y comprobar que pasan todas.
5. Crear el Permission Set **Agentes CRM - Acciones** con acceso a las 5 clases y asignarlo a los
   vendedores. Un nombre de clase tiene como máximo 40 caracteres.

## 3. Crear el agente

6. **Agentforce Agents > New Agent** en el Builder nuevo. Elegir la plantilla **Agentforce Employee
   Agent**: trae el Agent Router y los subagentes estándar (General FAQ, Off Topic, Ambiguous Question).
7. En **Agent Details**, poner nombre «Asistente de Seguimiento» y la descripción.
8. Abrir el script con el icono **</>** del lienzo y añadir el modelo en el nivel superior, al mismo nivel
   que `system:` (sección «Modelo»):
   ```
   model_config:
       model: "model://sfdc_ai__DefaultBedrockAnthropicClaude55Sonnet"
   ```

## 4. Crear el subagente

9. **Add Subagent** «Seguimiento de oportunidades» con la descripción de la sección «Descripción». El
   Builder añade la transición en el Agent Router.
10. Pegar las instrucciones bajo `reasoning:` > `instructions: ->`: una línea por instrucción, empezando
    por `|`, con 12 espacios de sangría. En el script la sangría es la estructura: siempre espacios, de 4
    en 4, nunca tabuladores.

## 5. Añadir las acciones

11. Por cada clase, **Add Action** en el subagente: *Action Name* (por ejemplo
    `leer_historial_oportunidad`), la descripción del `@InvocableMethod`, tipo **Apex**, categoría
    **Invocable Method** y la clase.
12. En el script, corregir a mano cada acción, porque el Builder no lo hace:
    - `label` con la etiqueta en español (tabla de «Acciones»);
    - `require_user_confirmation: True` en las 3 que escriben y `False` en las 2 que leen;
    - quitar líneas en blanco o espacios sobrantes.
13. Revisar el bloque `actions:` entero y la pestaña **Problems**. Los avisos de `id` obsoleto son
    normales; cualquier otra cosa se corrige antes de seguir.

Si cambian las salidas de una clase, la acción no se actualiza sola: se quita del script y se vuelve a
añadir (pasos 11 a 13), o se escriben las salidas a mano.

## 6. Idioma

14. **Settings > Language Settings:** idioma por defecto Spanish.
15. **Settings > System Messages:** bienvenida y error en español (sección «Idioma»).
16. Los vendedores deben tener su usuario de Salesforce en español: la tarjeta de confirmación usa el
    idioma del usuario, no el del agente.

## 7. Probar

17. Probar en el Preview en modo **Live Test**. El modo que simula acciones inventa la salida y no sirve
    para probar.
18. Pasar las pruebas de [06-pruebas-de-aceptacion.md](../../plugins/ventas-seguimiento/docs/06-pruebas-de-aceptacion.md)
    y comprobar cada cambio en la org con una consulta de solo lectura.

## 8. Activar y dar acceso

19. **Commit Version** y **Activate**. Para cambiar algo después se abre una versión nueva.
20. **Setup > Permission Sets > New** (por ejemplo «Asistente de Seguimiento - Acceso»): en **Apps > Agent
    Access > Edit**, pasar el agente a *Enabled Agents*.
21. Asignar a los vendedores ese Permission Set y **Agentes CRM - Acciones**.
22. Probar en la consola de Sales: icono **Agentforce** arriba a la derecha, con una oportunidad abierta.

## Lo que aprendimos

- La regla de diseño: lo que debe cumplirse siempre va en Apex o en configuración
  (`require_user_confirmation`, permisos, la lista de acciones); el criterio y el estilo van en las
  instrucciones.
- Las reglas al final de las instrucciones pesan poco; funciona mejor decir qué hacer que solo prohibir.
- Al volver a crear una acción, el Builder deja la etiqueta técnica y puede dejar mal la confirmación:
  así se encontró la tarea sin confirmación (2026-11-08).
- Para cambios grandes, es más seguro reemplazar el script completo que pegar trozos sueltos.
