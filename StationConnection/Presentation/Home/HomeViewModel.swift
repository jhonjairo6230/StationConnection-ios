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
    func reload() async {
        async let popular: Void = load(.popular, into: \.popular)
        async let trending: Void = load(.trending, into: \.trending)
        async let voted: Void = load(.votes, into: \.topVoted)
        async let tags: Void = loadTags()
        _ = await (popular, trending, voted, tags)
    }

    private func load(_ order: StationOrder, into keyPath: ReferenceWritableKeyPath<HomeViewModel, LoadState<[Station]>>) async {
        if self[keyPath: keyPath].value == nil { self[keyPath: keyPath] = .loading }
        do {
            self[keyPath: keyPath] = .loaded(try await search.execute(StationQuery(order: order, limit: 18)))
        } catch {
            self[keyPath: keyPath] = .failed(error.userMessage)
        }
    }

    private func loadTags() async {
        if tags.value == nil { tags = .loading }
        do {
            tags = .loaded(Array(try await getTags.execute().prefix(24)))
        } catch {
            tags = .failed(error.userMessage)
        }
    }
}
