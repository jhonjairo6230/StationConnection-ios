import Foundation
import Observation

/// Biblioteca del usuario: favoritas, recientes e historial de canciones.
///
/// Es un estado **compartido** por todas las pantallas (el corazón de una fila
/// en Explorar y la lista de Mis estaciones muestran lo mismo), así que hay una
/// sola instancia, creada en `AppContainer` e inyectada por el entorno.
@MainActor
@Observable
final class LibraryViewModel {
    private(set) var favorites: [Station] = []
    private(set) var recents: [Station] = []
    private(set) var songs: [PlayedSong] = []
    var alert: AlertMessage?

    /// Avisa cuando cambian las favoritas (el reproductor adopta el nuevo orden).
    @ObservationIgnored var onFavoritesChanged: (([Station]) -> Void)?

    private let loadFavorites: LoadFavoritesUseCase
    private let toggleFavoriteUseCase: ToggleFavoriteUseCase
    private let reorderFavorites: ReorderFavoritesUseCase
    private let exportFavoritesUseCase: ExportFavoritesUseCase
    private let importFavoritesUseCase: ImportFavoritesUseCase
    private let recentsUseCase: RecentsUseCase
    private let songHistory: SongHistoryUseCase

    init(
        loadFavorites: LoadFavoritesUseCase,
        toggleFavorite: ToggleFavoriteUseCase,
        reorderFavorites: ReorderFavoritesUseCase,
        exportFavorites: ExportFavoritesUseCase,
        importFavorites: ImportFavoritesUseCase,
        recents: RecentsUseCase,
        songHistory: SongHistoryUseCase
    ) {
        self.loadFavorites = loadFavorites
        self.toggleFavoriteUseCase = toggleFavorite
        self.reorderFavorites = reorderFavorites
        self.exportFavoritesUseCase = exportFavorites
        self.importFavoritesUseCase = importFavorites
        self.recentsUseCase = recents
        self.songHistory = songHistory
        load()
    }

    /// Lee todo del disco.
    func load() {
        do {
            favorites = try loadFavorites.execute()
            recents = try recentsUseCase.load()
            songs = try songHistory.load()
        } catch {
            alert = AlertMessage(error: error)
        }
    }

    // MARK: - Favoritas

    func isFavorite(_ station: Station) -> Bool {
        favorites.contains { $0.id == station.id }
    }

    func toggleFavorite(_ station: Station) {
        perform { try toggleFavoriteUseCase.execute(station) }
    }

    func moveFavorites(from source: IndexSet, to destination: Int) {
        perform { try reorderFavorites.move(from: source, to: destination) }
    }

    func sortFavoritesByName() {
        perform { try reorderFavorites.sortByName() }
    }

    /// Archivo de respaldo listo para compartir o guardar.
    func exportFavorites() -> BackupFile? {
        do {
            let export = try exportFavoritesUseCase.execute()
            return BackupFile(fileName: export.fileName, data: export.data)
        } catch {
            alert = AlertMessage(error: error)
            return nil
        }
    }

    /// Importa un respaldo y avisa cuántas emisoras se añadieron.
    func importFavorites(_ data: Data) {
        do {
            let result = try importFavoritesUseCase.execute(data)
            setFavorites(result.favorites)
            alert = AlertMessage(title: "Respaldo importado", message: Self.importSummary(result))
        } catch {
            alert = AlertMessage(error: error)
        }
    }

    static func importSummary(_ result: ImportFavoritesUseCase.Result) -> String {
        var parts = [result.added == 1 ? "Se añadió 1 emisora" : "Se añadieron \(result.added) emisoras"]
        if result.existing > 0 {
            parts.append(result.existing == 1 ? "1 ya estaba en tu lista" : "\(result.existing) ya estaban en tu lista")
        }
        if result.skipped > 0 {
            parts.append(result.skipped == 1 ? "1 no válida se omitió" : "\(result.skipped) no válidas se omitieron")
        }
        return parts.joined(separator: ", ") + "."
    }

    // MARK: - Recientes e historial

    func addRecent(_ station: Station) {
        do { recents = try recentsUseCase.add(station) } catch { alert = AlertMessage(error: error) }
    }

    func clearRecents() {
        do { try recentsUseCase.clear(); recents = [] } catch { alert = AlertMessage(error: error) }
    }

    func recordSong(_ song: Song, on station: Station) {
        do { songs = try songHistory.record(song, on: station) } catch { alert = AlertMessage(error: error) }
    }

    func clearSongs() {
        do { try songHistory.clear(); songs = [] } catch { alert = AlertMessage(error: error) }
    }

    // MARK: - Utilidades

    private func perform(_ change: () throws -> [Station]) {
        do {
            setFavorites(try change())
        } catch {
            alert = AlertMessage(error: error)
        }
    }

    private func setFavorites(_ list: [Station]) {
        favorites = list
        onFavoritesChanged?(list)
    }
}

/// Un archivo de respaldo exportado.
struct BackupFile: Equatable {
    let fileName: String
    let data: Data
}
