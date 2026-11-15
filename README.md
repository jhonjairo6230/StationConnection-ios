# StationConnection para iOS

Radio en vivo para **iPhone y iPad**, versión nativa de la app web
[StationConnection](https://github.com/jhonjairo6230/StationConnection).
Miles de emisoras del mundo desde el directorio público
[Radio Browser](https://www.radio-browser.info).

Se compila **sin Mac** (GitHub Actions) y se instala desde **Windows** con
Sideloadly.

[![Compilar IPA](https://github.com/jhonjairo6230/StationConnection-ios/actions/workflows/build.yml/badge.svg)](https://github.com/jhonjairo6230/StationConnection-ios/actions/workflows/build.yml)

## Qué hace

- **Inicio:** lo que suena o "continuar escuchando", tus favoritas, recientes,
  Populares, En tendencia, Géneros y Más votadas.
- **Explorar:** búsqueda por nombre, filtros por género y país, orden y
  "Cargar más".
- **Reproductor:** sigue sonando con la pantalla bloqueada; **⏮ ⏭** recorren la
  lista de donde elegiste la emisora, también desde el **volante del auto**,
  los auriculares y la pantalla de bloqueo.
- **Sonando ahora:** artista y canción (metadatos ICY), con historial y enlaces
  a **YouTube Music**, YouTube y Spotify.
- **Dial retro:** radio de madera con estática entre emisoras, aguja y perilla.
- **Mis estaciones:** favoritas ordenables (arrastrar o A–Z), respaldo en
  Archivos/iCloud **compatible con la web**.
- **Temporizador para dormir** (15–90 min, con fundido) y **AirPlay**.
- **CarPlay:** pestañas Favoritas, Recientes y Populares. Necesita el permiso
  `carplay-audio` de Apple (cuenta de pago); con Sideloadly la app suena por
  CarPlay en "Reproduciendo" pero no muestra su ícono ([ADR 0009](docs/adr/0009-carplay.md)).
- **Widgets:** "Sonando" (inicio, pantalla de bloqueo y **CarPlay desde
  iOS 26**, sin permiso especial) y "Favoritas" (cuatro favoritas a un toque).
  Ver [ADR 0010](docs/adr/0010-widgets.md).
- **Siri:** "Oye Siri, pon mis favoritas en StationConnection", también en
  el auto ([ADR 0011](docs/adr/0011-siri-favoritas.md)).
- Ícono de radio retro cromado; la carátula de "Reproduciendo" usa el ícono
  cuando la emisora no tiene logo.

Requiere iOS 17 o posterior.

## Instalar en tu iPhone

1. Ve a [Actions → Compilar IPA](https://github.com/jhonjairo6230/StationConnection-ios/actions/workflows/build.yml)
   y descarga **StationConnection-ipa** de la última ejecución en verde.
2. Fírmalo e instálalo con [Sideloadly](https://sideloadly.io) desde Windows.

Guía completa: [docs/compilacion-e-instalacion.md](docs/compilacion-e-instalacion.md).

## Cómo está hecho

- **SwiftUI + AVFoundation + MediaPlayer**, Swift 5, iOS 17.
- **Clean Architecture + MVVM**: `Domain`, `Data`, `Presentation`, `App`.
- **XcodeGen**: el proyecto se genera desde `project.yml`.
- **GitHub Actions**: pruebas unitarias y de interfaz en simulador y `.ipa` sin firmar.
- **Git Flow**: `main`, `develop`, `feature/`, `release/`, `backport/`, `hotfix/`.
- Sigue los ADR de [DrawPad](https://github.com/jhonjairo6230/DrawPad) que aplican.

## Documentación

Todo está en [`docs/`](docs/README.md): compilación, arquitectura (con
diagramas), conceptos de iOS, flujo de trabajo y decisiones (ADR).
