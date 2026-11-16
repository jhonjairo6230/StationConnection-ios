import Foundation

/// Un género musical del directorio y cuántas emisoras lo usan.
struct Tag: Identifiable, Hashable, Sendable {
    let name: String
    let stationCount: Int

    var id: String { name }
}
