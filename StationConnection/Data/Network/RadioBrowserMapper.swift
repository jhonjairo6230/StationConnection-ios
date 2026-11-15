import Foundation

/// Convierte las respuestas de Radio Browser en entidades del dominio y arma
/// los parámetros de búsqueda.
///
/// Es puro (sin red) para poder probarlo con JSON de ejemplo.
enum RadioBrowserMapper {
    static func station(from dto: RadioBrowserStationDTO) -> Station? {
        guard let id = dto.stationuuid?.trimmed.lowercased(), !id.isEmpty,
              let stream = webURL(dto.url_resolved) ?? webURL(dto.url)
        else { return nil }

        var seenTags = Set<String>()
        let tags = (dto.tags ?? "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            .filter { !$0.isEmpty && seenTags.insert($0).inserted }

        return Station(
            id: id,
            name: dto.name?.trimmed.nonEmpty ?? "Emisora sin nombre",
            streamURL: stream,
            homepage: webURL(dto.homepage),
            // Las imágenes no tienen la excepción de transporte del audio: solo https.
            favicon: webURL(dto.favicon, httpsOnly: true),
            tags: Array(tags.prefix(8)),
            country: dto.country?.trimmed.nonEmpty,
            countryCode: dto.countrycode?.trimmed.nonEmpty?.uppercased(),
            state: dto.state?.trimmed.nonEmpty,
            language: dto.language?.trimmed.nonEmpty,
            codec: dto.codec?.trimmed.nonEmpty,
            bitrate: max(0, dto.bitrate ?? 0),
            isHLS: dto.hls == 1,
            votes: max(0, dto.votes ?? 0),
            clicks: max(0, dto.clickcount ?? 0)
        )
    }

    /// Normaliza y quita duplicados por id.
    static func stations(from dtos: [RadioBrowserStationDTO]) -> [Station] {
        var seen = Set<String>()
        return dtos.compactMap(station(from:)).filter { seen.insert($0.id).inserted }
    }

    static func tags(from dtos: [RadioBrowserTagDTO]) -> [Tag] {
        dtos.compactMap { dto in
            guard let name = dto.name?.trimmed.lowercased(), !name.isEmpty else { return nil }
            return Tag(name: name, stationCount: dto.stationcount ?? 0)
        }
    }

    static func countries(from dtos: [RadioBrowserCountryDTO]) -> [Country] {
        dtos.compactMap { dto in
            guard let code = dto.iso_3166_1?.trimmed.uppercased(), code.count == 2,
                  let name = dto.name?.trimmed.nonEmpty else { return nil }
            return Country(name: name, code: code, stationCount: dto.stationcount ?? 0)
        }
    }

    /// Parámetros para `/json/stations/search`.
    static func searchItems(for query: StationQuery) -> [URLQueryItem] {
        let order: String
        switch query.order {
        case .popular: order = "clickcount"
        case .trending: order = "clicktrend"
        case .votes: order = "votes"
        case .name: order = "name"
        }
        var items = [
            URLQueryItem(name: "order", value: order),
            URLQueryItem(name: "reverse", value: query.order == .name ? "false" : "true"),
            URLQueryItem(name: "limit", value: String(query.limit)),
            URLQueryItem(name: "offset", value: String(query.offset)),
            URLQueryItem(name: "hidebroken", value: "true"),
        ]
        if !query.name.isEmpty { items.append(URLQueryItem(name: "name", value: query.name)) }
        if !query.tag.isEmpty {
            items.append(URLQueryItem(name: "tag", value: query.tag))
            items.append(URLQueryItem(name: "tagExact", value: "true"))
        }
        if !query.countryCode.isEmpty { items.append(URLQueryItem(name: "countrycode", value: query.countryCode)) }
        return items
    }

    /// URL http(s) con host. Descarta esquemas como `javascript:`.
    static func webURL(_ value: String?, httpsOnly: Bool = false) -> URL? {
        guard let text = value?.trimmed, !text.isEmpty, let url = URL(string: text),
              let scheme = url.scheme?.lowercased(), url.host != nil else { return nil }
        return scheme == "https" || (!httpsOnly && scheme == "http") ? url : nil
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
    var nonEmpty: String? { isEmpty ? nil : self }
}
