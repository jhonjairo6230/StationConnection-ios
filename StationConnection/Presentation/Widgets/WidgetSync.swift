import Foundation
import Observation
import WidgetKit

/// Mantiene al día la ``WidgetSnapshot`` que leen los widgets.
///
/// Observa el reproductor y la biblioteca (`withObservationTracking`); cuando
/// cambia algo que un widget muestra, guarda la foto en el App Group y le pide
/// a iOS que redibuje los widgets. Si la foto no cambió, no hace nada (redibujar
/// widgets tiene un cupo diario).
@MainActor
final class WidgetSync {
    private let player: PlayerViewModel
    private let library: LibraryViewModel
    private let store: SharedWidgetStore
    private let reloadWidgets: () -> Void
    private var lastPublished: WidgetSnapshot?

    init(
        player: PlayerViewModel,
        library: LibraryViewModel,
        store: SharedWidgetStore,
        reloadWidgets: @escaping () -> Void = { WidgetCenter.shared.reloadAllTimelines() }
    ) {
        self.player = player
        self.library = library
        self.store = store
        self.reloadWidgets = reloadWidgets
    }

    /// Empieza a observar. Sin App Group no hay a dónde publicar.
    func start() {
        guard store.isAvailable else { return }
        observe()
    }

    /// Calcula la foto y la publica si cambió.
    func publish() {
        let snapshot = WidgetSnapshot.make(
            station: player.station,
            isPlaying: player.status == .playing,
            song: player.nowPlaying,
            recents: library.recents,
            favorites: library.favorites
        )
        guard snapshot != lastPublished else { return }
        lastPublished = snapshot
        store.save(snapshot)
        reloadWidgets()
    }

    private func observe() {
        withObservationTracking {
            publish()
        } onChange: { [weak self] in
            Task { @MainActor in self?.observe() }
        }
    }
}

extension WidgetSnapshot {
    /// La foto a partir del estado de la app.
    static func make(
        station: Station?,
        isPlaying: Bool,
        song: Song?,
        recents: [Station],
        favorites: [Station]
    ) -> WidgetSnapshot {
        let current = station ?? recents.first
        return WidgetSnapshot(
            current: current.map(Item.init),
            isPlaying: station != nil && isPlaying,
            songTitle: station == nil ? nil : song?.title,
            songArtist: station == nil ? nil : song?.artist,
            favorites: favorites.prefix(maxFavorites).map(Item.init)
        )
    }
}

extension WidgetSnapshot.Item {
    init(_ station: Station) {
        self.init(
            id: station.id,
            name: station.name,
            subtitle: station.subtitle,
            initials: station.initials,
            gradientIndex: station.gradientIndex
        )
    }
}
