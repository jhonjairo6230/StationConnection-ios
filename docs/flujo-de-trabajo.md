# Flujo de trabajo (Git Flow)

Decisión registrada en [ADR 0002](adr/0002-git-flow.md).

## Ramas

| Rama | Sale de | Se fusiona en | Para qué |
| ---- | ------- | ------------- | -------- |
| `main` | — | — | Versiones publicadas. |
| `develop` | `main` | — | Integración: lo próximo que saldrá. |
| `feature/<nombre>` | `develop` | `develop` | Funcionalidades, arreglos o documentación. |
| `release/<x.y.z>` | `develop` | `main` | Subir `MARKETING_VERSION` y arreglos de última hora. |
| `backport/<x.y.z>` | `main` (tras la release) | `develop` | Igualar `develop` con `main`. |
| `hotfix/<x.y.z>` | `main` | `main` | Arreglo urgente. Después, `backport/<x.y.z>`. |

Reglas:

- **Nunca** commits directos en `main` ni en `develop`, ni pull requests de
  `develop` a `main`.
- Solo esos prefijos, en minúsculas y con guiones. **No** ramas `claude/…`.
- Antes de fusionar, **Compilar IPA** tiene que estar en verde.
- **Fusiona el backport de una release antes de sacar la siguiente.**

```mermaid
%%{init: { "gitGraph": { "mainBranchName": "main" } } }%%
gitGraph
    commit id: "inicio"
    branch develop
    checkout develop
    branch feature/estructura-inicial
    checkout feature/estructura-inicial
    commit id: "app + CI + docs"
    checkout develop
    merge feature/estructura-inicial
    branch release/0.1.0
    checkout release/0.1.0
    commit id: "versión 0.1.0"
    checkout main
    merge release/0.1.0 tag: "v0.1.0"
    branch backport/0.1.0
    checkout backport/0.1.0
    commit id: "desde main" type: HIGHLIGHT
    checkout develop
    merge backport/0.1.0
```

## Versiones

Versionado semántico `x.y.z` en `project.yml` (`MARKETING_VERSION`):
funcionalidad nueva sube `y`, solo arreglos suben `z`. Solo se cambia en
ramas `release/` o `hotfix/`.

## Publicar una versión

1. `git switch develop && git pull && git switch -c release/0.2.0`
2. Sube `MARKETING_VERSION` en `project.yml`. Commit, push y pull request a `main`.
3. Tras fusionar: `git switch main && git pull && git switch -c backport/0.2.0`,
   push y pull request a `develop`.
