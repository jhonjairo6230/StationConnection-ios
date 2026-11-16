import Foundation

/// *Composition root*: el único lugar donde se crean las implementaciones
/// concretas y se conectan entre sí (inyección de dependencias manual).
///
/// El resto del código solo conoce protocolos. Para cambiar, por ejemplo, el
/// directorio de radios, bastaría con cambiar una línea aquí.
///
/// **Todo es `lazy`.** `StationConnectionApp.init()` se ejecuta antes de que
/// exista la escena; nada (ni el audio ni la red) se crea hasta que la
/// interfaz lo pide.
@MainActor
final class AppContainer {
    /// La instancia de la app. La usan los puntos de entrada que crea UIKit sin
    /// pasarles nada (la escena de CarPlay); el resto recibe sus dependencias.
    static let shared = AppContainer()

    /// Cuando las pruebas de interfaz arrancan la app con `-uiTesting`, se usan
    /// datos falsos y almacenamiento en memoria: sin red ni audio reales.
    let isUITesting: Bool

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        isUITesting = arguments.contains("-uiTesting")
    }

    // MARK: - ViewModels compartidos

    private(set) lazy var library = LibraryViewModel(
        loadFavorites: LoadFavoritesUseCase(repository: favoritesRepository),
        toggleFavorite: ToggleFavoriteUseCase(repository: favoritesRepository),
        reorderFavorites: ReorderFavoritesUseCase(repository: favoritesRepository),
        exportFavorites: ExportFavoritesUseCase(repository: favoritesRepository),
        importFavorites: ImportFavoritesUseCase(repository: favoritesRepository),
        recents: RecentsUseCase(repository: recentsRepository),
        songHistory: SongHistoryUseCase(repository: songHistoryRepository)
    )

    private(set) lazy var player = PlayerViewModel(
        audio: audioPlayer,
        controls: systemControls,
        library: library,
        registerPlay: RegisterPlayUseCase(directory: directory)
    )

    // MARK: - Pantallas

    private(set) lazy var home = HomeViewModel(
        search: SearchStationsUseCase(directory: directory),
        getTags: GetTagsUseCase(directory: directory)
    )

    private(set) lazy var explore = ExploreViewModel(
        search: SearchStationsUseCase(directory: directory),
        getTags: GetTagsUseCase(directory: directory),
        getCountries: GetCountriesUseCase(directory: directory)
    )

    private(set) lazy var tuner = TunerViewModel(
        search: SearchStationsUseCase(directory: directory),
        getTags: GetTagsUseCase(directory: directory),
        getCountries: GetCountriesUseCase(directory: directory),
        player: player,
        noise: noiseGenerator
    )

    // MARK: - Widgets

    /// Publica la foto que leen los widgets (sin App Group, no hace nada).
    private(set) lazy var widgetSync = WidgetSync(
        player: player,
        library: library,
        store: isUITesting ? SharedWidgetStore(defaults: nil) : SharedWidgetStore.live()
    )

    /// Conecta los botones de los widgets y Siri (`AudioPlaybackIntent`) con el reproductor.
    /// Se llama al arrancar, también cuando iOS abre la app en segundo plano
    /// solo para ejecutar un intent.
    func registerWidgetActions() {
        let actions = WidgetPlaybackActions(
            player: player,
            library: library,
            getStations: GetStationsUseCase(directory: directory)
        )
        WidgetPlaybackBridge.playHandler = { stationID in await actions.play(stationID: stationID) }
        WidgetPlaybackBridge.toggleHandler = { actions.toggle() }
        WidgetPlaybackBridge.resumeHandler = { actions.resume() }
        WidgetPlaybackBridge.stopHandler = { actions.stop() }
        WidgetPlaybackBridge.playFavoritesHandler = { actions.playFavorites() }
        widgetSync.start()
    }

    /// Para CarPlay (lista de Populares).
    var searchStations: SearchStationsUseCase { SearchStationsUseCase(directory: directory) }

    func makeStationDetail(_ station: Station) -> StationDetailViewModel {
        StationDetailViewModel(station: station, search: SearchStationsUseCase(directory: directory))
    }

    // MARK: - Implementaciones concretas

    private lazy var directory: StationDirectory = isUITesting
        ? SampleStationDirectory()
        : RadioBrowserDirectory()

    private lazy var favoritesRepository: FavoritesRepository = isUITesting
        ? InMemoryListRepository<Station>()
        : JSONFileRepository<Station>.live(name: "favorites")

    private lazy var recentsRepository: RecentsRepository = isUITesting
        ? InMemoryListRepository<Station>()
        : JSONFileRepository<Station>.live(name: "recents")

    private lazy var songHistoryRepository: SongHistoryRepository = isUITesting
        ? InMemoryListRepository<PlayedSong>()
        : JSONFileRepository<PlayedSong>.live(name: "songs")

    private lazy var audioPlayer: AudioPlayer = isUITesting ? SilentAudioPlayer() : AVFoundationAudioPlayer()
    private lazy var systemControls: SystemMediaControls = isUITesting ? SilentMediaControls() : MediaPlayerControls()
    private lazy var noiseGenerator: NoiseGenerator = isUITesting ? SilentNoiseGenerator() : StaticNoiseGenerator()
}
