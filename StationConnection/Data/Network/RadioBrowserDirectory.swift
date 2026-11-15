import Foundation

/// Implementación de ``StationDirectory`` con la API pública de
/// [Radio Browser](https://www.radio-browser.info).
///
/// - La API se sirve desde varios espejos: se prueban en orden aleatorio
///   (como mucho dos), con un tiempo de espera corto cada uno.
/// - Géneros y países cambian poco: se guardan en memoria una hora.
/// - Los errores técnicos se convierten en ``StationError/directoryUnavailable``.
final class RadioBrowserDirectory: StationDirectory, @unchecked Sendable {
    static let defaultServers = [
        URL(string: "https://de1.api.radio-browser.info")!,
        URL(string: "https://de2.api.radio-browser.info")!,
        URL(string: "https://fi1.api.radio-browser.info")!,
    ]

    private let session: URLSession
    private let servers: [URL]
    private let maxAttempts: Int
    private let timeout: TimeInterval
    private let shuffle: ([URL]) -> [URL]
    private let cache = Cache()

    /// - Parameters:
    ///   - shuffle: orden en que se prueban los espejos (las pruebas lo fijan).
    init(
        session: URLSession = .shared,
        servers: [URL] = RadioBrowserDirectory.defaultServers,
        maxAttempts: Int = 2,
        timeout: TimeInterval = 6,
        shuffle: @escaping ([URL]) -> [URL] = { $0.shuffled() }
    ) {
        self.session = session
        self.servers = servers
        self.maxAttempts = maxAttempts
        self.timeout = timeout
        self.shuffle = shuffle
    }

    func search(_ query: StationQuery) async throws -> [Station] {
        let dtos: [RadioBrowserStationDTO] = try await get(
            "/json/stations/search",
            RadioBrowserMapper.searchItems(for: query.normalized())
        )
        return RadioBrowserMapper.stations(from: dtos)
    }

    func stations(ids: [String]) async throws -> [Station] {
        guard !ids.isEmpty else { return [] }
        let dtos: [RadioBrowserStationDTO] = try await get(
            "/json/stations/byuuid",
            [URLQueryItem(name: "uuids", value: ids.joined(separator: ","))]
        )
        let byID = Dictionary(RadioBrowserMapper.stations(from: dtos).map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        return ids.compactMap { byID[$0] }
    }

    func topTags(limit: Int) async throws -> [Tag] {
        if let cached: [Tag] = cache.value(for: "tags-\(limit)") { return cached }
        let dtos: [RadioBrowserTagDTO] = try await get("/json/tags", [
            URLQueryItem(name: "order", value: "stationcount"),
            URLQueryItem(name: "reverse", value: "true"),
            URLQueryItem(name: "hidebroken", value: "true"),
            URLQueryItem(name: "limit", value: String(limit)),
        ])
        let tags = RadioBrowserMapper.tags(from: dtos)
        cache.store(tags, for: "tags-\(limit)")
        return tags
    }

    func countries() async throws -> [Country] {
        if let cached: [Country] = cache.value(for: "countries") { return cached }
        let dtos: [RadioBrowserCountryDTO] = try await get("/json/countries", [
            URLQueryItem(name: "order", value: "name"),
            URLQueryItem(name: "hidebroken", value: "true"),
        ])
        let countries = RadioBrowserMapper.countries(from: dtos)
        cache.store(countries, for: "countries")
        return countries
    }

    func registerPlay(stationID: String) async {
        let _: [String: AnyDecodable]? = try? await get("/json/url/\(stationID)", [])
    }

    // MARK: - Red

    private func get<T: Decodable>(_ path: String, _ items: [URLQueryItem]) async throws -> T {
        for server in shuffle(servers).prefix(maxAttempts) {
            guard var components = URLComponents(url: server.appendingPathComponent(path), resolvingAgainstBaseURL: false)
            else { continue }
            components.queryItems = items.isEmpty ? nil : items
            guard let url = components.url else { continue }

            var request = URLRequest(url: url, timeoutInterval: timeout)
            request.setValue("StationConnection-iOS/1.0 (+https://github.com/jhonjairo6230/StationConnection-ios)", forHTTPHeaderField: "User-Agent")
            request.setValue("application/json", forHTTPHeaderField: "Accept")

            do {
                let (data, response) = try await session.data(for: request)
                let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                if (400..<500).contains(status) { throw StationError.directoryUnavailable }
                guard (200..<300).contains(status) else { continue } // 5xx: probar otro espejo
                return try JSONDecoder().decode(T.self, from: data)
            } catch let error as StationError {
                throw error
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                continue // timeout, sin red, JSON inesperado: probar otro espejo
            }
        }
        throw StationError.directoryUnavailable
    }
}

/// Caché en memoria con caducidad.
private final class Cache: @unchecked Sendable {
    private var entries: [String: (value: Any, expires: Date)] = [:]
    private let lock = NSLock()
    private let lifetime: TimeInterval = 3600

    func value<T>(for key: String) -> T? {
        lock.lock(); defer { lock.unlock() }
        guard let entry = entries[key], entry.expires > Date() else { return nil }
        return entry.value as? T
    }

    func store(_ value: Any, for key: String) {
        lock.lock(); defer { lock.unlock() }
        entries[key] = (value, Date().addingTimeInterval(lifetime))
    }
}

/// Decodifica cualquier JSON y lo descarta (respuestas que no se usan).
private struct AnyDecodable: Decodable {
    init(from decoder: Decoder) throws {}
}
