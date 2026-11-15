# 0004. Compilar sin Mac: GitHub Actions, XcodeGen e IPA sin firmar

- **Estado:** Aceptada
- **Fecha:** 2026-11-15
- **Origen:** ADR 0004 de DrawPad (se aplica igual).

## Contexto

El autor trabaja en **Windows**, sin Mac ni cuenta de pago de Apple
Developer. Xcode solo existe para macOS.

## Decisión

1. **Compilar en GitHub Actions** con un runner `macos-latest`.
2. **Generar el proyecto con XcodeGen** desde `project.yml`. El
   `.xcodeproj` y el `Info.plist` no se guardan en git.
3. **Publicar un `.ipa` sin firmar** como artefacto del workflow, y
   **firmarlo e instalarlo con Sideloadly** desde Windows con un Apple ID
   gratuito.
4. El workflow ejecuta las **pruebas unitarias y de interfaz** en un
   simulador de iPhone antes de generar el `.ipa`.
5. La app es **universal** (iPhone y iPad) y requiere **iOS 17**
   (`@Observable`).

Guía: [compilacion-e-instalacion.md](../compilacion-e-instalacion.md).

## Alternativas consideradas

- **Guardar el `.xcodeproj` en git:** imposible de mantener sin Xcode.
- **Capacitor envolviendo la web:** reutiliza la app web, pero no da audio
  nativo ni acceso limpio a CarPlay, y Apple rechaza las apps que solo
  envuelven una web. Se prefirió una app nativa en SwiftUI.
- **Firmar en el CI con cuenta de pago (99 USD/año):** la app duraría un año
  y permitiría TestFlight y CarPlay ([ADR 0009](0009-carplay.md)); queda como
  mejora futura.

## Consecuencias

- No hace falta Mac ni pagar nada.
- **No hay compilador en local:** cada cambio se comprueba con un push y
  unos minutos de espera; los errores se leen en el log del workflow.
- **La firma gratuita caduca a los 7 días** y limita a 3 apps por
  dispositivo.
- Con firma gratuita, iOS **descarta los permisos especiales** como el de
  CarPlay.
