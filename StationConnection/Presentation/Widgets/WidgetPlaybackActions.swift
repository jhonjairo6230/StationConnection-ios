import Foundation

/// Lo que hacen los botones de los widgets y los atajos de Siri, ya dentro de la app.
///
/// Los intents (`PlayStationIntent`, `TogglePlaybackIntent`) llegan por
/// `WidgetPlaybackBridge`; `AppContainer` conecta el puente con este tipo.
@MainActor
struct WidgetPlaybackActions {
    let player: PlayerViewModel
    let library: LibraryViewModel
    let getStations: GetStationsUseCase

    /// Pone a sonar una emisora por id. Si es favorita, ⏮/⏭ recorren las favoritas.
    func play(stationID: String) async {
        let known = library.favorites + library.recents + player.queue
        if let station = known.first(where: { $0.id == stationID }) {
            player.play(station, from: library.isFavorite(station) ? library.favorites : nil)
            return
        }
        // No está en el dispositivo: se pide al directorio.
        if let station = try? await getStations.execute(ids: [stationID]).first {
            player.play(station)
        }
    }

    /// ▶/■: detiene lo que suena o retoma la última emisora (o la primera favorita).
    func toggle() {
        if player.station != nil {
            player.toggle()
        } else if let last = library.recents.first {
            player.play(last, from: library.recents)
        } else if let favorite = library.favorites.first {
            player.play(favorite, from: library.favorites)
        }
    }

    /// Siri: suena la primera favorita y las demás quedan como cola de ⏮/⏭.
    /// - Returns: `false` si no hay favoritas.
    func playFavorites() -> Bool {
        guard let first = library.favorites.first else { return false }
        player.play(first, from: library.favorites)
        return true
    }
}
