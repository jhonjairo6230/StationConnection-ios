import Foundation

/// Formato del archivo de respaldo de favoritas.
///
/// Es **el mismo que usa la app web** (`{ app, version, exportedAt, favorites }`),
/// así que se puede pasar un respaldo de la web al iPhone y al revés.
enum FavoritesBackup {
    static let maxImport = 500

    /// Resultado de leer un respaldo.
    struct Contents: Equatable {
        let stations: [Station]
        /// Entradas descartadas por inválidas o repetidas.
        let skipped: Int
    }

    /// Nombre sugerido para el archivo exportado.
    static func fileName(now: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return "stationconnection-favoritas-\(formatter.string(from: now)).json"
    }

    static func encode(_ favorites: [Station], now: Date = Date()) throws -> Data {
        struct File: Encodable {
            let app = "StationConnection"
            let version = 1
            let exportedAt: String
            let favorites: [Station]
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let date = ISO8601DateFormatter().string(from: now)
        return try encoder.encode(File(exportedAt: date, favorites: favorites))
    }

    /// Lee un respaldo. Acepta también una lista simple de emisoras.
    ///
    /// Un archivo es un **dato no confiable**: cada emisora se vuelve a sanear
    /// con ``sanitize(_:)`` (URLs válidas, textos acotados).
    /// - Throws: ``StationError/invalidBackup``.
    static func decode(_ data: Data) throws -> Contents {
        guard let json = try? JSONSerialization.jsonObject(with: data) else { throw StationError.invalidBackup }
        let list: [Any]
        if let array = json as? [Any] {
            list = array
        } else if let object = json as? [String: Any], let favorites = object["favorites"] as? [Any] {
            list = favorites
        } else {
            throw StationError.invalidBackup
        }
        guard list.count <= maxImport else { throw StationError.invalidBackup }

        var seen = Set<String>()
        var stations: [Station] = []
        for item in list {
            guard let station = sanitize(item), seen.insert(station.id).inserted else { continue }
            stations.append(station)
        }
        return Contents(stations: stations, skipped: list.count - stations.count)
    }

    /// Valida y limpia una emisora de un archivo. `nil` si no sirve.
    static func sanitize(_ value: Any) -> Station? {
        guard let raw = value as? [String: Any],
              let id = text(raw["id"], max: 36)?.lowercased(), isStationID(id),
              let name = text(raw["name"], max: 200),
              let stream = webURL(raw["streamUrl"])
        else { return nil }
        let tags = (raw["tags"] as? [Any] ?? [])
            .compactMap { text($0, max: 50)?.lowercased() }
        return Station(
            id: id,
            name: name,
            streamURL: stream,
            homepage: webURL(raw["homepage"]),
            favicon: webURL(raw["favicon"], httpsOnly: true),
            tags: Array(NSOrderedSet(array: tags).array.compactMap { $0 as? String }.prefix(8)),
            country: text(raw["country"], max: 100),
            countryCode: text(raw["countryCode"], max: 2)?.uppercased(),
            state: text(raw["state"], max: 100),
            language: text(raw["language"], max: 100),
            codec: text(raw["codec"], max: 20),
            bitrate: count(raw["bitrate"]),
            isHLS: raw["hls"] as? Bool ?? false,
            votes: count(raw["votes"]),
            clicks: count(raw["clicks"])
        )
    }

    /// Los ids de Radio Browser son UUID.
    static func isStationID(_ value: String) -> Bool {
        value.range(of: "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", options: .regularExpression) != nil
    }

    private static func text(_ value: Any?, max: Int) -> String? {
        guard let string = value as? String else { return nil }
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : String(trimmed.prefix(max))
    }

    private static func count(_ value: Any?) -> Int {
        guard let number = value as? NSNumber, !(value is Bool) else { return 0 }
        return max(0, number.intValue)
    }

    /// URL http(s) válida: descarta esquemas como `javascript:`.
    private static func webURL(_ value: Any?, httpsOnly: Bool = false) -> URL? {
        guard let string = text(value, max: 2000), let url = URL(string: string),
              let scheme = url.scheme?.lowercased(), url.host != nil else { return nil }
        return scheme == "https" || (!httpsOnly && scheme == "http") ? url : nil
    }
}
