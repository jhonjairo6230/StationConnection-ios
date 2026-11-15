import Foundation

/// Guarda una lista en un archivo JSON dentro del contenedor de la app.
///
/// Usa `Application Support`, que el sistema respalda pero no muestra en la
/// app Archivos. Escribe de forma atómica: si la app se cierra a mitad, nunca
/// queda un archivo a medias. Ver docs/adr/0007-persistencia-json.md.
final class JSONFileRepository<Item: Codable> {
    let fileURL: URL
    private let fileManager: FileManager

    /// - Parameters:
    ///   - directory: carpeta del archivo. Las pruebas pasan una temporal.
    ///   - name: nombre del archivo sin extensión ("favorites").
    init(directory: URL, name: String, fileManager: FileManager = .default) {
        self.fileURL = directory.appendingPathComponent("\(name).json")
        self.fileManager = fileManager
    }

    /// Repositorio real, en `Application Support/StationConnection/<name>.json`.
    static func live(name: String, fileManager: FileManager = .default) -> JSONFileRepository {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return JSONFileRepository(
            directory: base.appendingPathComponent("StationConnection", isDirectory: true),
            name: name,
            fileManager: fileManager
        )
    }

    func load() throws -> [Item] {
        guard fileManager.fileExists(atPath: fileURL.path) else { return [] }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([Item].self, from: Data(contentsOf: fileURL))
        } catch {
            throw StationError.storageFailed
        }
    }

    func save(_ items: [Item]) throws {
        do {
            try fileManager.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            try encoder.encode(items).write(to: fileURL, options: .atomic)
        } catch {
            throw StationError.storageFailed
        }
    }
}

// Un mismo tipo genérico sirve para los tres puertos del dominio.
extension JSONFileRepository: FavoritesRepository where Item == Station {}
extension JSONFileRepository: RecentsRepository where Item == Station {}
extension JSONFileRepository: SongHistoryRepository where Item == PlayedSong {}
