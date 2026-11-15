import CarPlay
import Observation
import UIKit

/// Interfaz de CarPlay: pestañas con listas de emisoras y la pantalla
/// "Reproduciendo" del sistema.
///
/// Usa **el mismo** ``PlayerViewModel`` y ``LibraryViewModel`` que el teléfono:
/// lo que suena, la cola de ⏮/⏭ y las favoritas son las mismas.
///
/// CarPlay solo permite plantillas (`CPListTemplate`, `CPTabBarTemplate`…),
/// no vistas propias. "Reproduciendo" (`CPNowPlayingTemplate`) se alimenta
/// solo de `MPNowPlayingInfoCenter`, que ya actualiza ``MediaPlayerControls``.
///
/// Para que la app aparezca en el auto hace falta el permiso
/// `com.apple.developer.carplay-audio` (ver docs/adr/0009-carplay.md).
@MainActor
final class CarPlayInterface {
    private let interfaceController: CPInterfaceController
    private let player: PlayerViewModel
    private let library: LibraryViewModel
    private let search: SearchStationsUseCase

    private let favoritesTemplate = CPListTemplate(title: "Favoritas", sections: [])
    private let recentsTemplate = CPListTemplate(title: "Recientes", sections: [])
    private let popularTemplate = CPListTemplate(title: "Populares", sections: [])
    private var popular: [Station] = []
    private var artwork: [URL: UIImage] = [:]

    init(
        interfaceController: CPInterfaceController,
        player: PlayerViewModel,
        library: LibraryViewModel,
        search: SearchStationsUseCase
    ) {
        self.interfaceController = interfaceController
        self.player = player
        self.library = library
        self.search = search
    }

    func start() {
        favoritesTemplate.tabImage = UIImage(systemName: "heart.fill")
        recentsTemplate.tabImage = UIImage(systemName: "clock")
        popularTemplate.tabImage = UIImage(systemName: "flame")
        favoritesTemplate.emptyViewTitleVariants = ["Aún no tienes favoritas"]
        favoritesTemplate.emptyViewSubtitleVariants = ["Márcalas con ❤️ en el teléfono"]
        recentsTemplate.emptyViewTitleVariants = ["Nada escuchado todavía"]

        let tabs = CPTabBarTemplate(templates: [favoritesTemplate, recentsTemplate, popularTemplate])
        interfaceController.setRootTemplate(tabs, animated: false, completion: nil)

        observeLibrary()
        Task { await loadPopular() }
    }

    // MARK: - Listas

    /// Vuelve a pintar favoritas y recientes cada vez que cambian (Observation).
    private func observeLibrary() {
        withObservationTracking {
            render(library.favorites, in: favoritesTemplate)
            render(library.recents, in: recentsTemplate)
        } onChange: { [weak self] in
            Task { @MainActor in self?.observeLibrary() }
        }
    }

    private func loadPopular() async {
        popular = (try? await search.execute(StationQuery(order: .popular, limit: 24))) ?? []
        render(popular, in: popularTemplate)
    }

    private func render(_ stations: [Station], in template: CPListTemplate) {
        let items = stations.prefix(CPListTemplate.maximumItemCount).map { station in
            let item = CPListItem(
                text: station.name,
                detailText: station.subtitle,
                image: station.favicon.flatMap { artwork[$0] } ?? UIImage(named: "AppArtwork")
            )
            item.isPlaying = player.isPlaying(station)
            item.handler = { [weak self] _, completion in
                self?.play(station, from: stations)
                completion()
            }
            if let url = station.favicon, artwork[url] == nil { loadArtwork(url, for: item) }
            return item
        }
        template.updateSections([CPListSection(items: Array(items))])
    }

    private func play(_ station: Station, from list: [Station]) {
        player.play(station, from: list)
        let nowPlaying = CPNowPlayingTemplate.shared
        if interfaceController.topTemplate !== nowPlaying {
            interfaceController.pushTemplate(nowPlaying, animated: true, completion: nil)
        }
    }

    private func loadArtwork(_ url: URL, for item: CPListItem) {
        Task { [weak self] in
            guard let response = try? await URLSession.shared.data(from: url),
                  let image = UIImage(data: response.0), let self else { return }
            self.artwork[url] = image
            item.setImage(image)
        }
    }
}
