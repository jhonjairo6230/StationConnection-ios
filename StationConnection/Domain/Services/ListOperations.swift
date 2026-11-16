import Foundation

/// Operaciones puras sobre listas de emisoras (favoritas, recientes, historial).
enum ListOperations {
    /// Máximo de emisoras recientes.
    static let maxRecents = 12
    /// Máximo de canciones en el historial.
    static let maxSongs = 50

    /// Quita duplicados por id conservando el primer orden.
    static func uniqued(_ list: [Station]) -> [Station] {
        var seen = Set<String>()
        return list.filter { seen.insert($0.id).inserted }
    }

    /// Añade al inicio o quita si ya estaba.
    static func toggle(_ station: Station, in list: [Station]) -> [Station] {
        list.contains { $0.id == station.id }
            ? list.filter { $0.id != station.id }
            : [station] + list
    }

    /// Pone la emisora al principio sin duplicarla y respeta el máximo.
    static func pushRecent(_ station: Station, to list: [Station], max: Int = maxRecents) -> [Station] {
        Array(([station] + list.filter { $0.id != station.id }).prefix(max))
    }

    /// Mueve un elemento de `from` a `to` (índices; el destino se acota).
    static func move<T>(_ list: [T], from: Int, to: Int) -> [T] {
        guard list.indices.contains(from) else { return list }
        let target = min(max(to, 0), list.count - 1)
        guard target != from else { return list }
        var copy = list
        let item = copy.remove(at: from)
        copy.insert(item, at: target)
        return copy
    }

    /// Orden alfabético en español, sin distinguir mayúsculas ni tildes.
    static func sortedByName(_ list: [Station]) -> [Station] {
        let spanish = Locale(identifier: "es")
        return list.sorted {
            $0.name.compare($1.name, options: [.caseInsensitive, .diacriticInsensitive], range: nil, locale: spanish)
                == .orderedAscending
        }
    }

    /// `true` si las listas tienen exactamente las mismas emisoras (en cualquier orden).
    static func sameStations(_ a: [Station], _ b: [Station]) -> Bool {
        a.count == b.count && Set(a.map(\.id)) == Set(b.map(\.id))
    }

    /// Añade la canción al inicio, salvo que sea la misma que ya está arriba para esa emisora.
    static func pushSong(_ song: PlayedSong, to list: [PlayedSong], max: Int = maxSongs) -> [PlayedSong] {
        if let last = list.first, last.stationID == song.stationID, last.song.raw == song.song.raw {
            return list
        }
        return Array(([song] + list).prefix(max))
    }
}
