import Foundation

/// Dirección de ⏮/⏭.
enum SkipDirection: Int, Sendable {
    case previous = -1
    case next = 1
}

/// Reglas de la cola de reproducción: en qué lista se mueven ⏮/⏭.
///
/// Es lógica pura (sin estado ni frameworks) para poder probarla sola.
enum PlaybackQueue {
    /// Máximo de emisoras en una cola.
    static let maxSize = 200

    /// Decide la cola al reproducir `station`:
    /// 1. La lista de donde se eligió (carrusel, resultados, banda del dial…).
    /// 2. Si no hay, la cola actual si ya contiene la emisora.
    /// 3. Si no, las favoritas si la emisora está entre ellas.
    /// 4. Si no, solo esa emisora.
    static func resolve(
        for station: Station,
        source: [Station]?,
        current: [Station],
        favorites: [Station]
    ) -> [Station] {
        func contains(_ list: [Station]) -> Bool { list.contains { $0.id == station.id } }
        if let source, contains(source) { return Array(ListOperations.uniqued(source).prefix(maxSize)) }
        if contains(current) { return current }
        if contains(favorites) { return Array(favorites.prefix(maxSize)) }
        return [station]
    }

    /// La emisora siguiente o anterior, dando la vuelta en los extremos.
    /// `nil` si la cola tiene menos de dos emisoras.
    static func neighbor(in queue: [Station], of currentID: String?, direction: SkipDirection) -> Station? {
        guard queue.count > 1 else { return nil }
        guard let index = queue.firstIndex(where: { $0.id == currentID }) else {
            return direction == .next ? queue.first : queue.last
        }
        let next = (index + direction.rawValue + queue.count) % queue.count
        return queue[next]
    }
}
