import Foundation

/// Lee las favoritas en el orden del usuario.
struct LoadFavoritesUseCase {
    let repository: FavoritesRepository

    func execute() throws -> [Station] { try repository.load() }
}

/// Añade o quita una favorita y devuelve la lista nueva.
struct ToggleFavoriteUseCase {
    let repository: FavoritesRepository

    func execute(_ station: Station) throws -> [Station] {
        let updated = ListOperations.toggle(station, in: try repository.load())
        try repository.save(updated)
        return updated
    }
}

/// Cambia el orden de las favoritas: mover una o ponerlas de la A a la Z.
struct ReorderFavoritesUseCase {
    let repository: FavoritesRepository

    func move(from source: IndexSet, to destination: Int) throws -> [Station] {
        var list = try repository.load()
        // Misma semántica que `onMove` de SwiftUI.
        let moving = source.map { list[$0] }
        list.removeAll { station in moving.contains { $0.id == station.id } }
        let insertAt = destination - source.filter { $0 < destination }.count
        list.insert(contentsOf: moving, at: min(max(insertAt, 0), list.count))
        try repository.save(list)
        return list
    }

    func sortByName() throws -> [Station] {
        let sorted = ListOperations.sortedByName(try repository.load())
        try repository.save(sorted)
        return sorted
    }
}

/// Convierte las favoritas en un archivo de respaldo (compatible con la web).
struct ExportFavoritesUseCase {
    let repository: FavoritesRepository
    var now: () -> Date = Date.init

    func execute() throws -> (fileName: String, data: Data) {
        let date = now()
        return (FavoritesBackup.fileName(now: date), try FavoritesBackup.encode(try repository.load(), now: date))
    }
}

/// Importa un respaldo y añade solo las emisoras que no estaban.
struct ImportFavoritesUseCase {
    let repository: FavoritesRepository

    struct Result: Equatable {
        let favorites: [Station]
        let added: Int
        let existing: Int
        let skipped: Int
    }

    func execute(_ data: Data) throws -> Result {
        let contents = try FavoritesBackup.decode(data)
        let current = try repository.load()
        let ids = Set(current.map(\.id))
        let added = contents.stations.filter { !ids.contains($0.id) }
        let merged = current + added
        try repository.save(merged)
        return Result(
            favorites: merged,
            added: added.count,
            existing: contents.stations.count - added.count,
            skipped: contents.skipped
        )
    }
}

/// Emisoras recientes: leer, añadir y borrar.
struct RecentsUseCase {
    let repository: RecentsRepository

    func load() throws -> [Station] { try repository.load() }

    func add(_ station: Station) throws -> [Station] {
        let updated = ListOperations.pushRecent(station, to: try repository.load())
        try repository.save(updated)
        return updated
    }

    func clear() throws {
        try repository.save([])
    }
}

/// Historial de canciones: leer, registrar y borrar.
struct SongHistoryUseCase {
    let repository: SongHistoryRepository
    var now: () -> Date = Date.init

    func load() throws -> [PlayedSong] { try repository.load() }

    func record(_ song: Song, on station: Station) throws -> [PlayedSong] {
        let played = PlayedSong(song: song, stationID: station.id, stationName: station.name, playedAt: now())
        let updated = ListOperations.pushSong(played, to: try repository.load())
        try repository.save(updated)
        return updated
    }

    func clear() throws {
        try repository.save([])
    }
}
