# 0003. Clean Architecture con MVVM

- **Estado:** Aceptada
- **Fecha:** 2026-11-15
- **Origen:** ADR 0003 de DrawPad.

## Contexto

La app tiene bastante lógica que no es de interfaz: la cola de ⏮/⏭, el
temporizador con fundido, la matemática del dial, el respaldo compatible con
la web, el paso entre espejos de Radio Browser… Se quiere probarla sin
simulador, sin red y sin audio, y que cambiar de proveedor (directorio,
reproductor, almacenamiento) afecte a una sola capa.

## Decisión

Cuatro capas, con dependencias solo hacia dentro:

- **Domain:** entidades, errores, puertos (protocolos), casos de uso y lógica
  pura (`PlaybackQueue`, `TunerDial`, `SleepTimer`, `FavoritesBackup`…).
  Solo `Foundation`.
- **Data:** implementaciones de los puertos: `RadioBrowserDirectory`
  (`URLSession`) y `JSONFileRepository` (archivos).
- **Presentation:** SwiftUI con **MVVM** (`@Observable`). Los frameworks del
  sistema quedan detrás de protocolos propios de la presentación, como el
  `DrawingCanvas` de DrawPad: `AudioPlayer` (AVFoundation),
  `SystemMediaControls` (MediaPlayer) y `NoiseGenerator` (AVAudioEngine).
- **App:** `AppContainer` como *composition root* con inyección manual.

El reproductor (`PlayerViewModel`) y la biblioteca (`LibraryViewModel`) son
**estado compartido**: una sola instancia, inyectada por el entorno de
SwiftUI (`.environment(_:)`).

Todo vive en un único target de Xcode; las capas son carpetas.

## Alternativas consideradas

- **Todo en las vistas:** rápido, pero sin pruebas posibles de la lógica.
- **Un paquete Swift por capa:** el compilador impediría saltarse las capas,
  pero complica el proyecto y el CI para una app de este tamaño (igual que
  en DrawPad).
- **TCA:** potente, pero añade una dependencia y muchos conceptos.
- **Un singleton para el reproductor:** más corto, pero imposible de
  sustituir en las pruebas.

## Consecuencias

- La lógica tiene pruebas unitarias con dobles (`StationConnectionTests/Doubles`).
- Las pruebas de interfaz arrancan la app con `-uiTesting` y el
  `AppContainer` cambia las implementaciones por falsas, sin tocar nada más.
- Más archivos e indirección que una app "de ejemplo"; es el precio asumido.
- Al ser carpetas y no módulos, las reglas se respetan por disciplina (están
  en `AGENTS.md`).
