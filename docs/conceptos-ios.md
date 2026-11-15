# Conceptos de iOS

Glosario de lo que aparece en el código, en el orden en que conviene
aprenderlo.

## Swift y SwiftUI

| Concepto | Qué es | Dónde se usa |
| -------- | ------ | ------------ |
| `@Observable` | Macro (iOS 17) que hace que SwiftUI redibuje solo lo que lee de un objeto cuando cambia. | Todos los ViewModels. |
| `@MainActor` | Garantiza que un tipo se usa desde el hilo principal (el de la interfaz). | ViewModels, adaptadores de audio. |
| `.environment(_:)` / `@Environment` | Inyecta un objeto en todas las vistas de debajo. | `PlayerViewModel` y `LibraryViewModel`. |
| `@Bindable` | Permite crear `Binding` (`$viewModel.text`) a propiedades de un `@Observable`. | Explorar (`.searchable`), Favoritas (alertas). |
| `NavigationStack` + `navigationDestination(for:)` | Navegación por valores: se empuja una `Station` y se abre su detalle. | `RootView`. |
| `safeAreaInset(edge:)` | Reserva espacio en un borde; ahí vive la barra del reproductor. | `RootView`. |
| `async`/`await`, `Task` | Concurrencia: pedir datos a la red sin bloquear la interfaz. | Casos de uso, ViewModels. |
| `Task.sleep` + cancelar | Espera cancelable: *debounce* de la búsqueda, 350 ms del Dial, tics del temporizador. | `ExploreViewModel`, `TunerViewModel`, `PlayerViewModel`. |
| `Layout` | Protocolo para escribir un contenedor propio. | `FlowLayout` (géneros que saltan de línea). |
| `FileDocument`, `fileExporter`, `fileImporter` | Guardar o abrir archivos en la app Archivos / iCloud. | Respaldo de favoritas. |

## Audio

| Concepto | Qué es | Dónde se usa |
| -------- | ------ | ------------ |
| `AVPlayer` | Reproductor de Apple. Entiende MP3, AAC y **HLS** (`.m3u8`) sin librerías. | `AVFoundationAudioPlayer`. |
| `timeControlStatus` (KVO) | Si el reproductor está sonando, esperando datos (buffering) o en pausa. | Estado "Conectando…" / "En vivo". |
| `AVPlayerItemMetadataOutput` | Entrega los metadatos que viajan con el stream: el **ICY `StreamTitle`** de Shoutcast/Icecast ("Artista - Canción"). | "Sonando ahora". |
| `AVAudioSession` `.playback` | Le dice a iOS que la app reproduce audio "de verdad": suena con el interruptor de silencio y en segundo plano. | `AudioSession.activate()`. |
| `UIBackgroundModes: audio` | Permiso en `Info.plist` para seguir sonando con la pantalla bloqueada. | `project.yml`. |
| `MPNowPlayingInfoCenter` | Título, artista y carátula de la pantalla de bloqueo, el Centro de control, el reloj y CarPlay. | `MediaPlayerControls`. |
| `MPRemoteCommandCenter` | Botones de esos lugares, de los auriculares y del **volante del auto**. | ⏮/⏭ cambian de emisora. |
| `AVRoutePickerView` | El botón oficial para elegir AirPlay o Bluetooth. | `AirPlayButton`. |
| `AVAudioEngine` + `AVAudioSourceNode` | Motor para generar audio en tiempo real; el bloque corre en un hilo especial donde no se debe reservar memoria. | Estática del Dial. |

## Red y seguridad

| Concepto | Qué es | Dónde se usa |
| -------- | ------ | ------------ |
| `URLSession` | Cliente HTTP de Apple. | `RadioBrowserDirectory`. |
| `URLProtocol` | Permite interceptar peticiones; en pruebas, responder sin red. | `StubURLProtocol`. |
| App Transport Security (ATS) | iOS exige https por defecto. `NSAllowsArbitraryLoadsForMedia` lo relaja **solo** para audio y video. | `project.yml`, [ADR 0008](adr/0008-radio-browser-desde-la-app.md). |
| ICY | Protocolo de Shoutcast/Icecast que intercala metadatos (`StreamTitle`) en el audio. | "Sonando ahora". |

## Proyecto y herramientas

| Concepto | Qué es |
| -------- | ------ |
| **XcodeGen** / `project.yml` | Genera el `.xcodeproj` desde un YAML legible. |
| **Target** | Algo que se compila: la app, las pruebas unitarias y las de interfaz. |
| **Asset catalog** | `Assets.xcassets`: ícono (1024×1024, iOS redondea las esquinas), colores y la carátula `AppArtwork`. |
| **XCTest** / **XCUITest** | Pruebas unitarias y pruebas que tocan la app real en el simulador. |
| **Entitlement** | Permiso especial firmado en la app (por ejemplo, CarPlay). Lo otorga Apple; con Apple ID gratuito no se incluye. |
| **Sideloadly** | Programa de Windows que firma un `.ipa` con tu Apple ID y lo instala. |
