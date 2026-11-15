import Foundation
@testable import StationConnection

/// Directorio falso: devuelve lo que se le configure y recuerda lo que se pidió.
final class FakeStationDirectory: StationDirectory, @unchecked Sendable {
    var searchResult: Result<[Station], StationError> = .success([])
    /// Resultado por desplazamiento (para paginar); si no hay, usa `searchResult`.
    var pages: [Int: [Station]] = [:]
    var tags: [Tag] = []
    var countryList: [Country] = []
    private(set) var queries: [StationQuery] = []
    private(set) var registeredPlays: [String] = []

    func search(_ query: StationQuery) async throws -> [Station] {
        queries.append(query)
        if let page = pages[query.offset] { return page }
        return try searchResult.get()
    }

    func stations(ids: [String]) async throws -> [Station] {
        let all = (try? searchResult.get()) ?? []
        return ids.compactMap { id in all.first { $0.id == id } }
    }

    func topTags(limit: Int) async throws -> [Tag] { tags }
    func countries() async throws -> [Country] { countryList }
    func registerPlay(stationID: String) async { registeredPlays.append(stationID) }
}
