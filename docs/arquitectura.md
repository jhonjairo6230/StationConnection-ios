# Arquitectura

StationConnection-ios usa **Clean Architecture** con **MVVM**. El porqué está
en [ADR 0003](adr/0003-clean-architecture-mvvm.md); aquí se explica cómo está
montado.

## 1. La idea en una frase

El código se separa en capas y **las dependencias solo apuntan hacia dentro**:
la interfaz y los detalles técnicos (AVFoundation, red, archivos) dependen de
las reglas de la app, nunca al revés.

```mermaid
flowchart TB
    subgraph APP["App — composition root"]
        A1["StationConnectionApp"]
        A2["AppContainer"]
    end
    subgraph PRES["Presentation — SwiftUI + MVVM"]
        P1["Pantallas<br/>Home · Explore · Tuner · Favorites · Detail"]
        P2["ViewModels<br/>PlayerViewModel · LibraryViewModel · …"]
        P3["Puertos de presentación<br/>AudioPlayer · SystemMediaControls · NoiseGenerator"]
        P4["Adaptadores<br/>AVFoundationAudioPlayer · MediaPlayerControls<br/>StaticNoiseGenerator · AirPlayButton"]
    end
    subgraph DOM["Domain — Swift puro"]
        D1["Casos de uso"]
        D2["Entidades · StationError<br/>lógica pura (cola, dial, temporizador, respaldo)"]
        D3["Puertos<br/>StationDirectory · FavoritesRepository<br/>RecentsRepository · SongHistoryRepository"]
    end
    subgraph DATA["Data — detalles técnicos"]
        T1["RadioBrowserDirectory<br/>(URLSession)"]
        T2["JSONFileRepository<br/>(archivos JSON)"]
    end

    P1 --> P2
    P2 --> P3
    P4 -. implementa .-> P3
    P2 --> D1
    D1 --> D2
    D1 --> D3
    T1 -. implementa .-> D3
    T2 -. implementa .-> D3
    A2 --> P2
    A2 --> P4
    A2 --> T1
    A2 --> T2
    A1 --> A2
```

Las flechas continuas son "usa"; las punteadas, "implementa". **Ninguna flecha
sale de Domain.**

## 2. Capas

| Capa | Carpeta | Qué contiene | Puede importar |
| ---- | ------- | ------------ | -------------- |
| **Domain** | `StationConnection/Domain` | Entidades, errores, puertos, casos de uso y lógica pura. | Solo `Foundation`. |
| **Data** | `StationConnection/Data` | Cliente de Radio Browser y repositorios JSON. | `Foundation`, Domain. |
| **Presentation** | `StationConnection/Presentation` | Vistas SwiftUI, ViewModels y adaptadores de frameworks del sistema. | `SwiftUI`, `AVFoundation`, `AVKit`, `MediaPlayer`, `UIKit`, Domain. |
| **App** | `StationConnection/App` | Punto de entrada, creación de dependencias y piezas falsas para `-uiTesting`. | Todo. |

Reglas (también en `AGENTS.md`):

1. **Domain no importa** nada salvo `Foundation`.
2. **Presentation no conoce Data.** Los ViewModels reciben casos de uso.
3. **AVFoundation y MediaPlayer solo se tocan en sus adaptadores**
   (`AVFoundationAudioPlayer`, `MediaPlayerControls`, `StaticNoiseGenerator`,
   `AirPlayButton`). Los ViewModels usan los protocolos.
4. **Solo `AppContainer` crea implementaciones concretas.**
5. Data traduce sus errores técnicos a `StationError`.

## 3. Estructura de carpetas

```text
StationConnection/
├── App/
│   ├── StationConnectionApp.swift   Punto de entrada (@main)
│   ├── AppContainer.swift           Crea y conecta las dependencias (shared)
│   ├── CarPlaySceneDelegate.swift   Escena de CarPlay
│   └── UITestingSupport.swift       Directorio, audio y repos falsos (-uiTesting)
├── Domain/
│   ├── Entities/                    Station, Song, Tag, Country, StationQuery
│   ├── Errors/StationError.swift    Errores con mensaje para el usuario
│   ├── Repositories/                Puertos: StationDirectory y biblioteca
│   ├── Services/                    Lógica pura: PlaybackQueue, ListOperations,
│   │                                TunerDial, SleepTimer, MusicSearchLinks,
│   │                                FavoritesBackup
│   └── UseCases/                    DirectoryUseCases, LibraryUseCases
├── Data/
│   ├── Network/                     RadioBrowserDirectory, DTO y Mapper
│   └── Persistence/                 JSONFileRepository<Item>
├── Presentation/
│   ├── Common/                      Tema, LibraryViewModel, filas, tarjetas,
│   │                                carátulas, botones ▶ y ❤️, cola del entorno
│   ├── Player/                      PlayerViewModel, puertos y adaptadores de
│   │                                audio y controles, barra mini, "Reproduciendo",
│   │                                AirPlay, temporizador, enlaces de música
│   ├── Home/ · Explore/ · StationDetail/ · Favorites/
│   ├── Tuner/                       TunerViewModel, TunerScreen, estática
│   ├── CarPlay/CarPlayInterface.swift Plantillas de CarPlay (Favoritas, Recientes, Populares)
│   └── Root/RootView.swift          Pestañas + barra del reproductor
└── Resources/Assets.xcassets        Ícono, carátula para "Reproduciendo", colores

StationConnectionTests/
├── Doubles/                         Directorio, audio, controles y estática falsos
├── Domain/ · Data/ · Presentation/
StationConnectionUITests/            Toca la app real en el simulador
```

## 4. Tipos principales

```mermaid
classDiagram
    direction LR

    class PlayerViewModel {
        <<Observable>>
        +station Station?
        +status PlayerStatus
        +nowPlaying Song?
        +queue [Station]
        +sleepEndsAt Date?
        +play(station, from)
        +toggle(station, from)
        +stop()
        +skip(direction)
        +setSleepTimer(after)
    }
    class LibraryViewModel {
        <<Observable>>
        +favorites [Station]
        +recents [Station]
        +songs [PlayedSong]
        +toggleFavorite(station)
        +moveFavorites(from, to)
        +sortFavoritesByName()
        +exportFavorites() BackupFile?
        +importFavorites(Data)
    }
    class AudioPlayer {
        <<protocol>>
        +onStateChange
        +onMetadataTitle
        +volume Float
        +play(url)
        +stop()
    }
    class SystemMediaControls {
        <<protocol>>
        +onCommand
        +update(info, canSkip)
    }
    class StationDirectory {
        <<protocol>>
        +search(query) [Station]
        +stations(ids) [Station]
        +topTags(limit) [Tag]
        +countries() [Country]
        +registerPlay(stationID)
    }
    class FavoritesRepository {
        <<protocol>>
        +load() [Station]
        +save([Station])
    }
    class PlaybackQueue {
        <<lógica pura>>
        +resolve(for, source, current, favorites)
        +neighbor(in, of, direction)
    }

    PlayerViewModel --> AudioPlayer
    PlayerViewModel --> SystemMediaControls
    PlayerViewModel --> LibraryViewModel
    PlayerViewModel ..> PlaybackQueue
    LibraryViewModel ..> FavoritesRepository : casos de uso
    AVFoundationAudioPlayer ..|> AudioPlayer
    MediaPlayerControls ..|> SystemMediaControls
    RadioBrowserDirectory ..|> StationDirectory
    JSONFileRepository ..|> FavoritesRepository
```

`PlayerViewModel` y `LibraryViewModel` son **una sola instancia** para toda la
app, inyectada con `.environment(_:)`: la barra mini, "Reproduciendo", el Dial,
los corazones de cada fila y CarPlay ven el mismo estado.

## 5. Reproducir una emisora y "Sonando ahora"

```mermaid
sequenceDiagram
    autonumber
    actor U as Usuario
    participant B as PlayButton
    participant P as PlayerViewModel
    participant Q as PlaybackQueue
    participant A as AVFoundationAudioPlayer
    participant S as Stream de la emisora
    participant L as LibraryViewModel
    participant C as MediaPlayerControls

    U->>B: toca ▶ en un carrusel
    B->>P: toggle(station, from: lista del carrusel)
    P->>Q: resolve(...) → cola
    P->>A: play(url)
    A->>S: AVPlayer (MP3, AAC o HLS)
    A-->>P: .loading → .playing
    P->>L: addRecent(station)
    P-)P: registrar la reproducción en Radio Browser
    S-->>A: metadatos ICY "Artista - Canción"
    A-->>P: onMetadataTitle
    P->>P: Song.parse → nowPlaying
    P->>L: recordSong (historial)
    P->>C: update(título, artista, carátula, canSkip)
```

## 6. Botones del auto, auriculares y pantalla de bloqueo

```mermaid
sequenceDiagram
    autonumber
    actor U as Usuario
    participant Car as Auto / auriculares / pantalla de bloqueo
    participant MP as MPRemoteCommandCenter
    participant C as MediaPlayerControls
    participant P as PlayerViewModel

    U->>Car: ⏭ en el volante
    Car->>MP: nextTrackCommand
    MP->>C: handler
    C->>P: onCommand(.next)
    P->>P: skip(.next): PlaybackQueue.neighbor (da la vuelta al final)
    P->>C: update(nueva emisora)
```

Si las favoritas suenan como cola y el usuario las reordena,
`LibraryViewModel.onFavoritesChanged` avisa al reproductor, que adopta el
nuevo orden al instante.

## 7. El Dial

```mermaid
flowchart LR
    move["Mover el dial<br/>(escala, perilla, ◀◀ ▶▶)"] --> tune["TunerDial.tune(valor, n)"]
    tune --> locked{"¿Dentro del 30 %<br/>del carril?"}
    locked -- no --> noise["Estática más fuerte cuanto más lejos;<br/>si sonaba una emisora de la banda, se detiene"]
    locked -- sí --> settle["Quieto 350 ms"] --> play["player.play(emisora, from: banda)"]
    play --> quiet["Estática en silencio al sonar"]
    ext["⏮/⏭ o el auto cambian la emisora"] --> sync["syncToPlayingStation():<br/>la aguja se mueve a ella"]
```

## 8. Datos guardados

| Archivo (`Application Support/StationConnection/`) | Contenido |
| --- | --- |
| `favorites.json` | Favoritas en el orden del usuario (mismo formato de campos que la web) |
| `recents.json` | Últimas 12 emisoras escuchadas |
| `songs.json` | Últimas 50 canciones detectadas |

El respaldo exportado (`stationconnection-favoritas-AAAA-MM-DD.json`) tiene el
formato de la web: `{ app, version, exportedAt, favorites }`. Al importar,
cada emisora se **vuelve a sanear** (`FavoritesBackup.sanitize`): un archivo es
un dato no confiable.

## 9. CarPlay

```mermaid
flowchart LR
    car["Auto con CarPlay"] --> scene["CarPlaySceneDelegate<br/>(UIKit la crea)"]
    scene --> shared["AppContainer.shared"]
    shared --> ui["CarPlayInterface"]
    ui --> tabs["CPTabBarTemplate<br/>Favoritas · Recientes · Populares"]
    tabs -- "elige emisora" --> play["player.play(emisora, from: lista)"]
    play --> np["CPNowPlayingTemplate<br/>(lee MPNowPlayingInfoCenter)"]
```

Requiere el permiso `carplay-audio` (cuenta de pago); con Sideloadly la app no
aparece en el auto, pero "Reproduciendo" y ⏮/⏭ sí funcionan. Ver
[ADR 0009](adr/0009-carplay.md).

## 10. Pruebas

| Qué | Dónde | Cómo |
| --- | ----- | ---- |
| Lógica pura y casos de uso | `StationConnectionTests/Domain` | Sin dobles o con repositorios en memoria. |
| Radio Browser | `StationConnectionTests/Data` | `StubURLProtocol` responde sin red (espejos, 4xx, caché). |
| Repositorio JSON | `StationConnectionTests/Data` | Carpeta temporal. |
| ViewModels | `StationConnectionTests/Presentation` | `FakeAudioPlayer`, `FakeMediaControls`, `FakeNoiseGenerator`, reloj inyectado. |
| Interfaz | `StationConnectionUITests` | La app real con `-uiTesting` (sin red ni audio). |

Los adaptadores de AVFoundation y MediaPlayer no tienen pruebas automáticas:
se verifican a mano en el iPhone.
