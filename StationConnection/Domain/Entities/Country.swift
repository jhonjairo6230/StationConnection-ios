import Foundation

/// Un país con emisoras en el directorio.
struct Country: Identifiable, Hashable, Sendable {
    let name: String
    /// Código ISO 3166-1 de dos letras, en mayúsculas ("CO").
    let code: String
    let stationCount: Int

    var id: String { code }
}
