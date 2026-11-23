# 0015. Compilar el IPA solo al fusionar en develop o main

- **Estado:** Aceptada
- **Fecha:** 2026-11-23
- **Origen:** nueva (pedido del autor). Cambia cuándo se ejecuta el workflow
  del [ADR 0004](0004-compilar-sin-mac.md); el resto de ese ADR sigue igual.

## Contexto

"Compilar IPA" se ejecutaba en cada `push` a cualquier rama de Git Flow y en
cada pull request. Un mismo cambio lanzaba varias ejecuciones: el push de la
rama, el del PR y el de la fusión. Cada una tarda unos 10 minutos en un Mac
de GitHub. Coincidían varias a la vez, había colas y fallos por simuladores
saturados, y la lista de Actions se llenaba de `.ipa` que nadie instalaba.

## Decisión

El workflow se dispara solo con:

- **`push` a `develop`, `main` o `master`**, es decir, al fusionar un PR. El
  `.ipa` de esa ejecución es el que se instala.
- **`workflow_dispatch`** (Actions → Compilar IPA → Run workflow), en
  cualquier rama, para probar una rama antes de abrir o fusionar su PR.

Se quitan los disparadores de `feature/**`, `release/**`, `hotfix/**`,
`backport/**` y `pull_request`.

## Alternativas consideradas

- **Pruebas en cada PR e `.ipa` solo al fusionar** (dos workflows): da más
  seguridad, pero sigue gastando un Mac por PR, que es lo que se quería evitar.
- **Filtrar por rutas cambiadas (`paths`):** casi todos los cambios tocan
  código, así que ahorra poco.

## Consecuencias

- Un PR ya no muestra el resultado de las pruebas por sí solo. Antes de
  fusionar hay que **lanzar el workflow a mano en la rama**. Si no se hace,
  un error se descubre después de fusionar, en `develop`.
- Menos ejecuciones simultáneas: menos colas y menos fallos por simuladores
  saturados.
- Hay un `.ipa` por cada fusión en `develop` o `main`.
