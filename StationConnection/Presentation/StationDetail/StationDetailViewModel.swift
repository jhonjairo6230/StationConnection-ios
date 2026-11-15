import Foundation
import Observation

/// Detalle de una emisora: sus datos y otras del mismo género.
@MainActor
@Observable
final class StationDetailViewModel {
    let station: Station
    private(set) var related: LoadState<[Station]> = .idle

    private let search: SearchStationsUseCase

    init(station: Station, search: SearchStationsUseCase) {
        self.station = station
        self.search = search
    }

    func onAppear() async {
        guard case .idle = related, let tag = station.tags.first else { return }
        related = .loading
        do {
            let stations = try await search.execute(StationQuery(tag: tag, limit: 13))
            related = .loaded(Array(stations.filter { $0.id != station.id }.prefix(12)))
        } catch {
            related = .failed(error.userMessage)
        }
    }
}
