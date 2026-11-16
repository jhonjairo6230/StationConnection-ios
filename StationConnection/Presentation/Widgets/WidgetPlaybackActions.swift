import Foundation

/// Lo que hacen los botones de los widgets y los atajos de Siri, ya dentro de la app.
///
/// Los intents (`PlayStationIntent`, `ResumePlaybackIntent`,
/// `StopPlaybackIntent`, `TogglePlaybackIntent`, `PlayFavoritesIntent`) llegan
/// por `WidgetPlaybackBridge`; `AppContainer` conecta el puente con este tipo.
///
/// Todas las acciones son **idempotentes**: un widget sin App Group no sabe qué
/// suena, e iOS puede entregar el mismo toque dos veces. Repetir ▶ o ■ no
/// debe reiniciar la emisora.
@MainActor
final class WidgetPlaybackActions {
    private let player: PlayerViewModel
    private let library: LibraryViewModel
    private let getStations: GetStationsUseCase
    private let clock: () -> Date
    private var lastToggleAt: Date?

    /// Un segundo toque de ▶/■ dentro de este margen se considera repetido.
    static let toggleDebounce: TimeInterval = 1

    init(
        player: PlayerViewModel,
        library: LibraryViewModel,
        getStations: GetStationsUseCase,
        clock: @escaping () -> Date = Date.init
    ) {
        self.player = player
        self.library = library
        self.getStations = getStations
        self.clock = clock
    }

    /// Pone a sonar una emisora por id. Si es favorita, ⏮/⏭ recorren las favoritas.
    /// Si ya suena, no hace nada.
    func play(stationID: String) async {
        if player.station?.id == stationID, player.isActive { return }
        let known = library.favorites + library.recents + player.queue
        if let station = known.first(where: { $0.id == stationID }) {
            player.play(station, from: library.isFavorite(station) ? library.favorites : nil)
            return
        }
        // No está en el dispositivo (p. ej. elegida al configurar el widget): se pide al directorio.
        if let station = try? await getStations.execute(ids: [stationID]).first {
            player.play(station)
        }
    }

    /// ▶: retoma la emisora actual, la última escuchada o la primera favorita.
    /// Si ya suena algo, no hace nada.
    func resume() {
        guard !player.isActive else { return }
        if let station = player.station {
            player.play(station, from: player.queue)
        } else if let last = library.recents.first {
            player.play(last, from: library.recents)
        } else if let favorite = library.favorites.first {
            player.play(favorite, from: library.favorites)
        }
    }

    /// ■: detiene y evita que iOS vuelva a poner la radio justo después.
    func stop() {
        player.stopFromShortcut()
    }

    /// ▶/■ de un solo botón (pantalla de bloqueo). Ignora toques repetidos.
    func toggle() {
        let now = clock()
        if let last = lastToggleAt, now.timeIntervalSince(last) < Self.toggleDebounce { return }
        lastToggleAt = now
        if player.isActive { stop() } else { resume() }
    }

    /// Siri: suena la primera favorita y las demás quedan como cola de ⏮/⏭.
    /// - Returns: `false` si no hay favoritas.
    func playFavorites() -> Bool {
        guard let first = library.favorites.first else { return false }
        if player.station?.id == first.id, player.isActive { return true }
        player.play(first, from: library.favorites)
        return true
    }
}
