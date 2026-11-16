import Foundation

/// Puerto para guardar las emisoras favoritas, **en el orden del usuario**
/// (es el orden que siguen ⏮/⏭ y los botones del auto).
protocol FavoritesRepository {
    /// - Throws: ``StationError/storageFailed``.
    func load() throws -> [Station]
    /// - Throws: ``StationError/storageFailed``.
    func save(_ stations: [Station]) throws
}

/// Puerto para las emisoras escuchadas recientemente (la más reciente primero).
protocol RecentsRepository {
    func load() throws -> [Station]
    func save(_ stations: [Station]) throws
}

/// Puerto para el historial de canciones detectadas.
protocol SongHistoryRepository {
    func load() throws -> [PlayedSong]
    func save(_ songs: [PlayedSong]) throws
}
