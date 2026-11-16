import Foundation

/// Búsqueda mínima en Radio Browser **desde la extensión de widgets**.
///
/// Con la firma gratuita no hay App Group: el widget no puede leer las
/// favoritas de la app. Para que el usuario elija emisoras al configurar el
/// widget, la extensión consulta la API por su cuenta y guarda en su propia
/// caché lo que ya encontró (para pintar sin red). Solo lee nombre, país y
/// género; reproducir lo hace la app con su propio cliente.
/// Ver docs/adr/0013-widgets-configurables.md
struct RadioBrowserLookup {
    /// Una emisora reducida a lo que muestra el selector y el widget.
    struct Result: Codable, Equatable {
        let id: String
        let name: String
        let detail: String
    }

    private static let mirrors = [
        "https://de1.api.radio-browser.info",
        "https://de2.api.radio-browser.info",
        "https://fi1.api.radio-browser.info",
    ]
    private static let cacheKey = "radioBrowserLookup.cache.v1"

    var session: URLSession = .shared
    var cache: UserDefaults = .standard

    /// Emisoras más escuchadas: lo que se sugiere antes de escribir.
    func popular() async throws -> [Result] {
        try await request("/json/stations/topclick/30", query: [URLQueryItem(name: "hidebroken", value: "true")])
    }

    /// Emisoras cuyo nombre contiene `text`, las más escuchadas primero.
    func search(_ text: String) async throws -> [Result] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return try await popular() }
        return try await request("/json/stations/search", query: [
            URLQueryItem(name: "name", value: trimmed),
            URLQueryItem(name: "limit", value: "30"),
            URLQueryItem(name: "hidebroken", value: "true"),
            URLQueryItem(name: "order", value: "clickcount"),
            URLQueryItem(name: "reverse", value: "true"),
        ])
    }

    /// Emisoras por id: primero la caché; lo que falte, de la red.
    func stations(ids: [String]) async -> [Result] {
        let cached = loadCache()
        let missing = ids.filter { cached[$0] == nil }
        var found = cached
        if !missing.isEmpty, let fetched = try? await request("/json/stations/byuuid", query: [
            URLQueryItem(name: "uuids", value: missing.joined(separator: ",")),
        ]) {
            for item in fetched { found[item.id] = item }
        }
        return ids.compactMap { found[$0] }
    }

    // MARK: - Privado

    private struct DTO: Decodable {
        let stationuuid: String?
        let name: String?
        let country: String?
        let tags: String?
    }

    private func request(_ path: String, query: [URLQueryItem]) async throws -> [Result] {
        var lastError: Error = URLError(.cannotFindHost)
        for mirror in Self.mirrors {
            var components = URLComponents(string: mirror + path)!
            components.queryItems = query
            var request = URLRequest(url: components.url!, timeoutInterval: 8)
            request.setValue("StationConnection-iOS-Widget/1.0 (+https://github.com/jhonjairo6230/StationConnection-ios)", forHTTPHeaderField: "User-Agent")
            do {
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { continue }
                let results = try JSONDecoder().decode([DTO].self, from: data).compactMap(Self.result)
                saveToCache(results)
                return results
            } catch {
                lastError = error
            }
        }
        throw lastError
    }

    private static func result(_ dto: DTO) -> Result? {
        guard let id = dto.stationuuid?.lowercased(), !id.isEmpty,
              let name = dto.name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty
        else { return nil }
        let genre = dto.tags?.split(separator: ",").first.map { String($0).trimmingCharacters(in: .whitespaces) }
        let parts = [dto.country, genre].compactMap { $0 }.filter { !$0.isEmpty }
        return Result(id: id, name: name, detail: parts.isEmpty ? "Radio en línea" : parts.joined(separator: " · "))
    }

    private func loadCache() -> [String: Result] {
        guard let data = cache.data(forKey: Self.cacheKey),
              let items = try? JSONDecoder().decode([String: Result].self, from: data)
        else { return [:] }
        return items
    }

    private func saveToCache(_ results: [Result]) {
        var items = loadCache()
        for item in results { items[item.id] = item }
        // Solo lo necesario: la caché no debe crecer sin límite.
        if items.count > 300 { items = Dictionary(uniqueKeysWithValues: results.map { ($0.id, $0) }) }
        if let data = try? JSONEncoder().encode(items) { cache.set(data, forKey: Self.cacheKey) }
    }
}
