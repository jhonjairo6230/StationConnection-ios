import Foundation

/// La canción que suena, según los metadatos que envía la emisora
/// (`StreamTitle` de ICY o `title` de HLS).
struct Song: Equatable, Hashable, Codable, Sendable {
    /// Texto tal cual lo envía la emisora.
    let raw: String
    let artist: String?
    let title: String

    /// Textos que las emisoras ponen cuando no hay canción (cuñas, programas…).
    private static let placeholders: Set<String> = ["-", "unknown", "desconocido", "n/a", "null", "undefined"]

    /// "Artista - Canción" → artista y título. Sin separador, todo es título.
    /// Devuelve `nil` si el texto está vacío o es de relleno.
    static func parse(_ raw: String) -> Song? {
        let clean = raw
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
        guard !clean.isEmpty, !placeholders.contains(clean.lowercased()) else { return nil }
        if let range = clean.range(of: " - ") {
            let artist = clean[..<range.lowerBound].trimmingCharacters(in: .whitespaces)
            let title = clean[range.upperBound...].trimmingCharacters(in: .whitespaces)
            if !artist.isEmpty, !title.isEmpty {
                return Song(raw: clean, artist: artist, title: title)
            }
        }
        return Song(raw: clean, artist: nil, title: clean)
    }
}

/// Una canción detectada mientras se escuchaba una emisora (historial).
struct PlayedSong: Identifiable, Equatable, Codable, Sendable {
    let song: Song
    let stationID: String
    let stationName: String
    let playedAt: Date

    var id: String { "\(playedAt.timeIntervalSince1970)-\(song.raw)" }
}
