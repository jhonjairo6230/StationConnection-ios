# 0009. Kit de CarPlay para apps de audio

- **Estado:** Aceptada
- **Fecha:** 2026-11-15
- **Origen:** nueva (pedido del autor tras usar la versión web en el auto).

## Contexto

La app se usa en el auto. Sin integración propia, CarPlay solo muestra la
radio en "Reproduciendo" (gracias a `MPNowPlayingInfoCenter`, ADR 0005). Para
que la app tenga **su ícono en la pantalla del auto** y listas para elegir
emisoras, iOS exige:

- Una escena de CarPlay basada en **plantillas** (`CPTemplateApplicationScene`).
- El permiso **`com.apple.developer.carplay-audio`** en la firma, que Apple
  concede a pedido y **solo a cuentas de pago** de Apple Developer.

Con el Apple ID gratuito que usa Sideloadly ([ADR 0004](0004-compilar-sin-mac.md)),
iOS **descarta** ese permiso al firmar.

## Decisión

Incluir ya el kit completo, listo para cuando exista el permiso:

- `CarPlaySceneDelegate` (en `App/`) declarado en `project.yml` →
  `UIApplicationSceneManifest`. Toma las dependencias de
  `AppContainer.shared`, el mismo contenedor de la app.
- `CarPlayInterface` (en `Presentation/CarPlay/`): `CPTabBarTemplate` con
  **Favoritas**, **Recientes** y **Populares** (`CPListTemplate`). Al elegir
  una emisora suena con esa lista como cola de ⏮/⏭ y se abre
  `CPNowPlayingTemplate`. Las listas se repintan solas cuando cambian
  (`withObservationTracking`).
- `StationConnection.entitlements` con `carplay-audio = true` y
  `CODE_SIGN_ENTITLEMENTS` en `project.yml`.

## Alternativas consideradas

- **No hacer nada hasta tener cuenta de pago:** "Reproduciendo" ya funciona,
  pero el código quedaría pendiente.
- **Envolver la app web con Capacitor para CarPlay:** igual necesita el
  permiso y código nativo de plantillas.
- **`AppContainer.shared` vs. pasar dependencias:** UIKit crea el delegado de
  la escena sin parámetros; un acceso compartido al *composition root* es el
  punto mínimo de entrada. El resto del código sigue recibiendo sus
  dependencias por inyección.

## Consecuencias

- **Con firma gratuita (Sideloadly), la app no aparece en la pantalla del
  auto.** Lo que sí funciona: el audio por CarPlay o Bluetooth, la pantalla
  "Reproduciendo" con la carátula y ⏮/⏭ del volante.
- Con cuenta de pago y permiso aprobado, basta con firmar con un perfil que
  incluya `carplay-audio`: no hay que cambiar código.
- CarPlay no se puede probar en el CI. Se verifica con el simulador de
  CarPlay de Xcode (en un Mac) o en un auto.
- `UIApplicationSupportsMultipleScenes` queda en `true` (lo exige la escena
  extra). En iPad permite abrir varias ventanas, que comparten reproductor.
