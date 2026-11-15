import Foundation
@testable import StationConnection

extension Station {
    /// Emisora de prueba con un id válido (UUID) a partir de un número.
    static func fixture(_ number: Int, name: String? = nil, tags: [String] = ["pop"], favicon: URL? = nil) -> Station {
        Station(
            id: String(format: "00000000-0000-4000-8000-%012d", number),
            name: name ?? "Radio \(number)",
            streamURL: URL(string: "https://example.com/\(number)")!,
            favicon: favicon,
            tags: tags,
            country: "Colombia",
            countryCode: "CO"
        )
    }
}

/// `[0, 1, 2]` → tres emisoras de prueba.
func makeStations(_ numbers: [Int]) -> [Station] { numbers.map { Station.fixture($0) } }
