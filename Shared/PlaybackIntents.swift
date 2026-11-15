import AppIntents

/// Botón de un widget que pone a sonar una emisora concreta (favoritas).
///
/// Adopta `AudioPlaybackIntent`: iOS ejecuta `perform()` **dentro de la app**
/// (abriéndola en segundo plano si hace falta), que es donde vive el
/// reproductor. El widget solo declara el botón.
///
/// Este archivo se compila en la app **y** en la extensión de widgets.
struct PlayStationIntent: AudioPlaybackIntent {
    static let title: LocalizedStringResource = "Reproducir emisora"
    static let description = IntentDescription("Pone a sonar una emisora de StationConnection.")

    @Parameter(title: "Emisora")
    var stationID: String

    init() {}

    init(stationID: String) {
        self.stationID = stationID
    }

    func perform() async throws -> some IntentResult {
        await WidgetPlaybackBridge.play(stationID: stationID)
        return .result()
    }
}

/// Botón ▶/■ de un widget: detiene lo que suena o retoma la última emisora.
struct TogglePlaybackIntent: AudioPlaybackIntent {
    static let title: LocalizedStringResource = "Reproducir o detener la radio"
    static let description = IntentDescription("Detiene la radio o vuelve a poner la última emisora.")

    init() {}

    func perform() async throws -> some IntentResult {
        await WidgetPlaybackBridge.toggle()
        return .result()
    }
}

/// Puente entre los intents (widgets y Siri) y el reproductor (solo en la app).
///
/// La app registra aquí sus acciones al arrancar (`AppContainer`). En la
/// extensión de widgets queda vacío: los `AudioPlaybackIntent` nunca se
/// ejecutan ahí.
@MainActor
enum WidgetPlaybackBridge {
    static var playHandler: (@MainActor (String) async -> Void)?
    static var toggleHandler: (@MainActor () -> Void)?
    /// Siri: devuelve `false` si no hay favoritas.
    static var playFavoritesHandler: (@MainActor () -> Bool)?

    static func play(stationID: String) async {
        await playHandler?(stationID)
    }

    static func toggle() {
        toggleHandler?()
    }

    static func playFavorites() -> Bool {
        playFavoritesHandler?() ?? false
    }
}
