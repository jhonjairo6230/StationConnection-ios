# Documentación de StationConnection-ios

Orden sugerido para estudiar el proyecto:

| # | Documento | Qué responde |
| - | --------- | ------------ |
| 1 | [Compilación e instalación](compilacion-e-instalacion.md) | ¿Cómo llega el código al iPhone sin un Mac, desde Windows? |
| 2 | [Arquitectura](arquitectura.md) | ¿Cómo está organizado el código y cómo fluye cada acción? |
| 3 | [Conceptos de iOS](conceptos-ios.md) | ¿Qué es cada pieza de Swift, SwiftUI y AVFoundation que aparece? |
| 4 | [Flujo de trabajo](flujo-de-trabajo.md) | ¿Cómo se usan las ramas y las versiones? |
| 5 | [Decisiones (ADR)](adr/README.md) | ¿Por qué se hizo así y qué se descartó? |

Recorrido de lectura del código:

1. `StationConnection/App/StationConnectionApp.swift` y `AppContainer.swift`: cómo se monta todo.
2. `StationConnection/Domain/`: las reglas, sin frameworks.
3. `StationConnection/Presentation/Player/PlayerViewModel.swift`: el corazón de la app.
4. `StationConnection/Presentation/Player/AVFoundationAudioPlayer.swift` y `MediaPlayerControls.swift`: el audio y los controles del sistema.
5. `StationConnection/Data/`: Radio Browser y archivos.
6. `StationConnectionTests/`: cómo se prueba cada capa con dobles.
