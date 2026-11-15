# 0002. Usar Git Flow como flujo de ramas

- **Estado:** Aceptada
- **Fecha:** 2026-11-15
- **Origen:** ADR 0002 de DrawPad y reglas de la app web StationConnection.

## Contexto

El autor usa el mismo flujo en todos sus proyectos para no recordar reglas
distintas. Cada rama produce un `.ipa` instalable, así que conviene distinguir
"lo que estoy probando" de "la versión que funciona".

## Decisión

Se usa **Git Flow**:

- `main`: versiones publicadas. `develop`: integración.
- `feature/<nombre>` sale de `develop` y vuelve a `develop`.
- `release/<x.y.z>` sale de `develop` y va a `main`; solo sube
  `MARKETING_VERSION` en `project.yml` y arreglos de última hora.
- Tras fusionar una release, `backport/<x.y.z>` sale de `main` y va a
  `develop`.
- `hotfix/<x.y.z>` sale de `main` y va a `main`, seguido de un backport.
- **Nunca** un pull request de `develop` a `main` ni commits directos en
  `main` o `develop`.
- **No se usan otros prefijos** (por ejemplo `claude/…`), tampoco cuando el
  trabajo lo hace un asistente.
- Versionado semántico.
- **El backport de una release se fusiona antes de sacar la siguiente.** En
  la app web, saltarse ese orden dejó dos ancestros comunes y GitHub marcó un
  conflicto en la versión que Git resolvía solo.

Detalle y diagramas en [flujo-de-trabajo.md](../flujo-de-trabajo.md).

## Alternativas consideradas

- **GitHub Flow** (solo `main` + ramas cortas): más simple, pero no separa lo
  que está en pruebas de la versión estable.
- **Trunk-based:** mínimo esfuerzo, sin historial de versiones claro.

## Consecuencias

- `main` siempre tiene una versión que funcionó en el iPhone.
- Una release necesita dos pull requests (release y backport).
- La rama de producción se llama `main` (como en DrawPad); en la app web se
  llama `master`.
