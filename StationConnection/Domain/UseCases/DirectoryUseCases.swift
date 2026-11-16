import Foundation

/// Busca emisoras en el directorio (nombre, género, país y orden).
struct SearchStationsUseCase: Sendable {
    let directory: StationDirectory

    func execute(_ query: StationQuery) async throws -> [Station] {
        try await directory.search(query.normalized())
    }
}

/// Pide emisoras concretas por id (por ejemplo, para refrescar una favorita).
struct GetStationsUseCase: Sendable {
    let directory: StationDirectory

    func execute(ids: [String]) async throws -> [Station] {
        let valid = ids.map { $0.lowercased() }.filter(FavoritesBackup.isStationID)
        guard !valid.isEmpty else { return [] }
        return try await directory.stations(ids: Array(NSOrderedSet(array: valid).array.compactMap { $0 as? String }.prefix(100)))
    }
}

/// Los géneros más usados, para los filtros y la sección "Géneros".
struct GetTagsUseCase: Sendable {
    let directory: StationDirectory

    func execute(limit: Int = 40) async throws -> [Tag] {
        try await directory.topTags(limit: limit)
    }
}

/// Países con al menos unas cuantas emisoras.
struct GetCountriesUseCase: Sendable {
    let directory: StationDirectory
    /// Se ocultan los países casi vacíos para que la lista sea manejable.
    let minimumStations = 5

    func execute() async throws -> [Country] {
        try await directory.countries().filter { $0.stationCount >= minimumStations }
    }
}

/// Registra que se escuchó una emisora (Radio Browser lo pide en su guía de uso).
struct RegisterPlayUseCase: Sendable {
    let directory: StationDirectory

    func execute(_ station: Station) async {
        await directory.registerPlay(stationID: station.id)
    }
}
