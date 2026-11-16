import Foundation
import Observation

/// Datos de la pantalla de inicio: carruseles y géneros.
@MainActor
@Observable
final class HomeViewModel {
    private(set) var popular: LoadState<[Station]> = .idle
    private(set) var trending: LoadState<[Station]> = .idle
    private(set) var topVoted: LoadState<[Station]> = .idle
    private(set) var tags: LoadState<[Tag]> = .idle

    private let search: SearchStationsUseCase
    private let getTags: GetTagsUseCase
    @ObservationIgnored private var hasLoaded = false

    init(search: SearchStationsUseCase, getTags: GetTagsUseCase) {
        self.search = search
        self.getTags = getTags
    }

    /// Carga todo la primera vez que aparece la pantalla.
    func onAppear() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        await reload()
    }

    /// Vuelve a pedir todo (deslizar para actualizar o "Reintentar").
    /// Las cuatro peticiones van en paralelo.
    func reload() async {
        if popular.value == nil { popular = .loading }
        if trending.value == nil { trending = .loading }
        if topVoted.value == nil { topVoted = .loading }
        if tags.value == nil { tags = .loading }
        async let popularResult = fetch(.popular)
        async let trendingResult = fetch(.trending)
        async let votedResult = fetch(.votes)
        async let tagsResult = fetchTags()
        popular = await popularResult
        trending = await trendingResult
        topVoted = await votedResult
        tags = await tagsResult
    }

    private func fetch(_ order: StationOrder) async -> LoadState<[Station]> {
        do {
            return .loaded(try await search.execute(StationQuery(order: order, limit: 18)))
        } catch {
            return .failed(error.userMessage)
        }
    }

    private func fetchTags() async -> LoadState<[Tag]> {
        do {
            return .loaded(Array(try await getTags.execute().prefix(24)))
        } catch {
            return .failed(error.userMessage)
        }
    }
}
