import Foundation

/// Cómo ordenar los resultados de una búsqueda.
enum StationOrder: String, CaseIterable, Sendable {
    case popular
    case trending
    case votes
    case name

    /// Texto para el selector de la interfaz.
    var title: String {
        switch self {
        case .popular: return "Más escuchadas"
        case .trending: return "En tendencia"
        case .votes: return "Más votadas"
        case .name: return "Nombre (A-Z)"
        }
    }
}

/// Parámetros de una búsqueda de emisoras. Los valores vacíos significan "sin filtro".
struct StationQuery: Equatable, Sendable {
    var name: String = ""
    var tag: String = ""
    var countryCode: String = ""
    var order: StationOrder = .popular
    var limit: Int = 24
    var offset: Int = 0

    /// Límites que protegen al directorio de peticiones absurdas.
    static let maxLimit = 100

    /// Copia con los valores recortados y acotados.
    func normalized() -> StationQuery {
        StationQuery(
            name: String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(100)),
            tag: String(tag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().prefix(50)),
            countryCode: String(countryCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased().prefix(2)),
            order: order,
            limit: min(max(limit, 1), Self.maxLimit),
            offset: min(max(offset, 0), 10_000)
        )
    }
}
