import Foundation

// Piezas falsas para las pruebas de interfaz (`-uiTesting`): la app arranca sin
// red, sin audio y sin tocar el disco, con datos fijos y predecibles.

/// Directorio con emisoras de ejemplo.
struct SampleStationDirectory: StationDirectory {
    static let stations: [Station] = [
        "La Mega", "Radio Activa", "Jazz FM", "Tropicana", "Clásica 24",
        "Rock & Pop", "Noticias 360", "Electro Beat", "Salsa Brava", "Retro 80s",
    ].enumerated().map { index, name in
        Station(
            id: String(format: "00000000-0000-4000-8000-%012d", index),
            name: name,
            streamURL: URL(string: "https://example.com/stream/\(index)")!,
            tags: ["pop", "music"],
            country: "Colombia",
            countryCode: "CO",
            codec: "MP3",
            bitrate: 128
        )
    }

    func search(_ query: StationQuery) async throws -> [Station] {
        let name = query.name.lowercased()
        let filtered = name.isEmpty ? Self.stations : Self.stations.filter { $0.name.lowercased().contains(name) }
        return Array(filtered.dropFirst(query.offset).prefix(query.limit))
    }

    func stations(ids: [String]) async throws -> [Station] {
        ids.compactMap { id in Self.stations.first { $0.id == id } }
    }

    func topTags(limit: Int) async throws -> [Tag] {
        [Tag(name: "pop", stationCount: 10), Tag(name: "rock", stationCount: 5)]
    }

    func countries() async throws -> [Country] {
        [Country(name: "Colombia", code: "CO", stationCount: 10)]
    }

    func registerPlay(stationID: String) async {}
}

/// Lista en memoria para los tres puertos de la biblioteca.
final class InMemoryListRepository<Item> {
    private var items: [Item] = []

    func load() throws -> [Item] { items }
    func save(_ items: [Item]) throws { self.items = items }
}

extension InMemoryListRepository: FavoritesRepository where Item == Station {}
extension InMemoryListRepository: RecentsRepository where Item == Station {}
extension InMemoryListRepository: SongHistoryRepository where Item == PlayedSong {}

/// Reproductor que "suena" al instante, sin audio real.
@MainActor
final class SilentAudioPlayer: AudioPlayer {
    var onStateChange: ((AudioPlayerState) -> Void)?
    var onMetadataTitle: ((String) -> Void)?
    var volume: Float = 1

    func play(url: URL) {
        onStateChange?(.loading)
        Task { @MainActor [weak self] in
            self?.onStateChange?(.playing)
            self?.onMetadataTitle?("Shakira - Hips Don't Lie")
        }
    }

    func stop() {}
}

/// Controles del sistema que no hacen nada.
@MainActor
final class SilentMediaControls: SystemMediaControls {
    var onCommand: ((MediaCommand) -> Void)?
    func update(_ info: NowPlayingInfo?, canSkip: Bool) {}
}

/// Estática muda.
@MainActor
final class SilentNoiseGenerator: NoiseGenerator {
    func start() {}
    func setLevel(_ level: Double) {}
    func stop() {}
}
