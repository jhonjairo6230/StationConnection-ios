# 0005. AVFoundation y MediaPlayer para reproducir la radio

- **Estado:** Aceptada
- **Fecha:** 2026-11-15
- **Origen:** nueva. Ocupa el lugar del ADR 0005 de DrawPad (PencilKit), que
  no aplica a una app de radio.

## Contexto

La app reproduce streams en vivo (MP3, AAC, HLS) y debe seguir sonando con la
pantalla bloqueada, mostrar la canción, responder a los botones del auto y
los auriculares, y enviar el audio por AirPlay. En la versión web, leer la
canción (metadatos ICY) necesitaba un endpoint en el servidor.

## Decisión

Usar los frameworks de Apple, cada uno **aislado detrás de un protocolo** de
la capa de presentación:

| Necesidad | Framework | Puerto | Adaptador |
| --------- | --------- | ------ | --------- |
| Reproducir (MP3, AAC y **HLS nativo**) | `AVPlayer` | `AudioPlayer` | `AVFoundationAudioPlayer` |
| Canción actual (ICY `StreamTitle`, título HLS) | `AVPlayerItemMetadataOutput` | `AudioPlayer.onMetadataTitle` | ídem |
| Sonar en segundo plano | `AVAudioSession` (`.playback`, `.longFormAudio`) + `UIBackgroundModes: audio` | — | `AudioSession` |
| Pantalla de bloqueo, Centro de control, CarPlay "Reproduciendo", volante | `MPNowPlayingInfoCenter`, `MPRemoteCommandCenter` | `SystemMediaControls` | `MediaPlayerControls` |
| AirPlay | `AVRoutePickerView` | — | `AirPlayButton` |
| Estática del dial | `AVAudioEngine` + `AVAudioSourceNode` | `NoiseGenerator` | `StaticNoiseGenerator` |

## Alternativas consideradas

- **Un endpoint propio para la canción (como en la web):** innecesario;
  `AVPlayer` entrega los metadatos ICY directamente y no hay servidor que
  mantener.
- **Una librería de audio de terceros (por ejemplo, basada en FFmpeg):** más
  formatos, pero añade una dependencia grande; `AVPlayer` cubre lo que usan
  las emisoras de Radio Browser.
- **Google Cast:** el SDK de Cast para iOS no se distribuye como paquete
  Swift oficial y complicaría la compilación sin Mac. Se deja para el futuro;
  AirPlay cubre parlantes Apple y compatibles.

## Consecuencias

- La canción, el audio en segundo plano y los controles del sistema
  funcionan sin servidor.
- `PlayerViewModel` se prueba entero con `FakeAudioPlayer` y
  `FakeMediaControls`.
- Los adaptadores no tienen pruebas automáticas (el simulador no reproduce
  streams de forma fiable); se verifican a mano en el iPhone.
- Los streams que `AVPlayer` no soporta (algunos OGG o AAC raros) fallan y se
  muestra "No se pudo reproducir esta emisora".
