import Foundation
import Observation

/// Búsqueda de emisoras: texto (con espera mientras se escribe), género,
/// país, orden y paginación.
@MainActor
@Observable
final class ExploreViewModel {
    static let pageSize = 30

    var text = "" { didSet { if text != oldValue { textChanged() } } }
    var tag = "" { didSet { if tag != oldValue { filtersChanged() } } }
    var countryCode = "" { didSet { if countryCode != oldValue { filtersChanged() } } }
    var order: StationOrder = .popular { didSet { if order != oldValue { filtersChanged() } } }

    private(set) var results: LoadState<[Station]> = .idle
    private(set) var canLoadMore = false
    private(set) var isLoadingMore = false
    private(set) var tags: [Tag] = []
    private(set) var countries: [Country] = []

    var hasFilters: Bool { !text.isEmpty || !tag.isEmpty || !countryCode.isEmpty }

    private let search: SearchStationsUseCase
    private let getTags: GetTagsUseCase
    private let getCountries: GetCountriesUseCase
    private let debounce: Duration

    @ObservationIgnored private var searchTask: Task<Void, Never>?
    @ObservationIgnored private var hasLoaded = false

    init(
        search: SearchStationsUseCase,
        getTags: GetTagsUseCase,
        getCountries: GetCountriesUseCase,
        debounce: Duration = .milliseconds(350)
    ) {
        self.search = search
        self.getTags = getTags
        self.getCountries = getCountries
        self.debounce = debounce
    }

    func onAppear() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        runSearch(after: .zero)
        async let tags = try? getTags.execute()
        async let countries = try? getCountries.execute()
        self.tags = await tags ?? []
        self.countries = await countries ?? []
    }

    /// Aplica un género desde otra pantalla (por ejemplo, Inicio).
    func show(tag: String) {
        text = ""
        countryCode = ""
        self.tag = tag
    }

    func clearFilters() {
        text = ""
        tag = ""
        countryCode = ""
    }

    func retry() { runSearch(after: .zero) }

    /// Siguiente página de resultados.
    func loadMore() async {
        guard canLoadMore, !isLoadingMore, let current = results.value else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let page = try await search.execute(query(offset: current.count))
            let ids = Set(current.map(\.id))
            results = .loaded(current + page.filter { !ids.contains($0.id) })
            canLoadMore = page.count == Self.pageSize
        } catch {
            canLoadMore = false
        }
    }

    // MARK: - Privado

    private func textChanged() { runSearch(after: debounce) }
    private func filtersChanged() { runSearch(after: .zero) }

    private func runSearch(after delay: Duration) {
        searchTask?.cancel()
        let query = query(offset: 0)
        searchTask = Task { [weak self] in
            if delay > .zero {
                do { try await Task.sleep(for: delay) } catch { return }
            }
            await self?.perform(query)
        }
    }

    private func perform(_ query: StationQuery) async {
        if results.value == nil { results = .loading }
        canLoadMore = false
        do {
            let stations = try await search.execute(query)
            guard !Task.isCancelled else { return }
            results = .loaded(stations)
            canLoadMore = stations.count == Self.pageSize
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            results = .failed(error.userMessage)
        }
    }

    private func query(offset: Int) -> StationQuery {
        StationQuery(name: text, tag: tag, countryCode: countryCode, order: order, limit: Self.pageSize, offset: offset)
    }
}
