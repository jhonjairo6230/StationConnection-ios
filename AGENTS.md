# StationConnection-ios — notas del proyecto

App de radio en vivo para iPhone y iPad (SwiftUI + AVFoundation), versión
nativa de https://github.com/jhonjairo6230/StationConnection. Se compila solo
en GitHub Actions: **no hay Mac ni compilador de Swift en local**.
Documentación en `docs/`; decisiones en `docs/adr/` (siguen las de DrawPad
que aplican).

## Reglas de arquitectura

- `StationConnection/Domain` solo importa `Foundation`.
- `Presentation` no conoce `Data`: los ViewModels reciben casos de uso.
- AVFoundation y MediaPlayer solo se tocan en `AVFoundationAudioPlayer`,
  `MediaPlayerControls`, `StaticNoiseGenerator` y `AirPlayButton`. Los
  ViewModels usan los protocolos `AudioPlayer`, `SystemMediaControls` y
  `NoiseGenerator`.
- CarPlay: `App/CarPlaySceneDelegate.swift` toma dependencias de
  `AppContainer.shared` (UIKit la crea sin parámetros); las plantillas viven
  en `Presentation/CarPlay/`. Nadie más usa `AppContainer.shared`.
- Widgets: la extensión `StationConnectionWidgets/` solo lee la foto
  (`Shared/SharedWidgetStore`); sus botones son `AudioPlaybackIntent` que se
  ejecutan en la app por `WidgetPlaybackBridge`. Lo que use la extensión va en
  `Shared/` (sin tipos de la app). Los widgets configurables buscan emisoras
  con `RadioBrowserLookup` (en la extensión) porque la firma gratuita no trae
  App Group. Ver `docs/adr/0010-widgets.md` y `0013-widgets-configurables.md`.
- Las implementaciones concretas solo se crean en `App/AppContainer.swift`
  (todo `lazy`). Las falsas para `-uiTesting` viven en `App/UITestingSupport.swift`.
- `Data` convierte sus errores a `StationError`.
- `Station` mantiene los nombres JSON de la web (`streamUrl`, `hls`…): no los
  cambies o se rompe la compatibilidad del respaldo.
- Los logos solo por https; el audio puede ser http (ATS solo para medios).
- Cada tipo lleva un comentario `///` que explica su papel (el porqué).
- Interfaz, comentarios y documentación en español; identificadores en inglés.
- Lógica nueva → pruebas en `StationConnectionTests` con los dobles de `Doubles/`.

## Proyecto de Xcode

- La fuente de verdad es `project.yml` (XcodeGen). No se guardan en git ni el
  `.xcodeproj` ni los `Info.plist` (`StationConnection/Resources/` y `StationConnectionWidgets/`).
- Permisos y claves de `Info.plist` van en `project.yml` → `info.properties`.

## Comprobar un cambio

Push a la rama y mirar el workflow **Compilar IPA**: ejecuta las pruebas en
un simulador de iPhone y publica `StationConnection-unsigned.ipa`. Si falla,
el paso "Errores de compilación o pruebas" resume el error.

## Documentación

- Si cambia un flujo o una capa, actualiza los diagramas de `docs/arquitectura.md`.
- Una decisión importante → nuevo ADR en `docs/adr/` y su fila en
  `docs/adr/README.md`. Los ADR aceptados no se reescriben.

## Flujo de ramas (Git Flow)

| Rama | Sale de | PR hacia | Para qué |
| ---- | ------- | -------- | -------- |
| `feature/<nombre>` | `develop` | `develop` | Cualquier funcionalidad, arreglo o documentación. |
| `release/<x.y.z>` | `develop` | `main` | Subir `MARKETING_VERSION` en `project.yml`. |
| `backport/<x.y.z>` | `main` (tras la release) | `develop` | Igualar `develop` con `main`. |
| `hotfix/<x.y.z>` | `main` | `main` | Arreglo urgente. Después, `backport/<x.y.z>`. |

- **Nunca** un PR de `develop` a `main` ni commits directos en `develop` o `main`.
- **No uses ramas `claude/…`** ni otros prefijos.
- Fusiona el backport de una release **antes** de sacar la siguiente.
- Versionado semántico: funcionalidad sube `y`, arreglos suben `z`.
