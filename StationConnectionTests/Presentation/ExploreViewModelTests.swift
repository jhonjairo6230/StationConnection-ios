import XCTest
@testable import StationConnection

@MainActor
final class ExploreViewModelTests: XCTestCase {
    private var directory: FakeStationDirectory!

    override func setUp() async throws {
        directory = FakeStationDirectory()
        directory.searchResult = .success(makeStations([1, 2]))
    }

    private func makeViewModel() -> ExploreViewModel {
        ExploreViewModel(
            search: SearchStationsUseCase(directory: directory),
            getTags: GetTagsUseCase(directory: directory),
            getCountries: GetCountriesUseCase(directory: directory),
            debounce: .milliseconds(50)
        )
    }

    func testLoadsResultsOnAppear() async throws {
        let viewModel = makeViewModel()
        await viewModel.onAppear()
        try await waitUntil { viewModel.results.value != nil }
        XCTAssertEqual(viewModel.results.value?.count, 2)
    }

    func testTypingQuicklySearchesOnlyOnceWithTheLastText() async throws {
        let viewModel = makeViewModel()
        await viewModel.onAppear()
        try await waitUntil { self.directory.queries.count == 1 }

        viewModel.text = "ja"
        viewModel.text = "jaz"
        viewModel.text = "jazz"
        try await waitUntil { self.directory.queries.count == 2 }
        try await Task.sleep(for: .milliseconds(120))

        XCTAssertEqual(directory.queries.count, 2)
        XCTAssertEqual(directory.queries.last?.name, "jazz")
    }

    func testFiltersSearchImmediately() async throws {
        let viewModel = makeViewModel()
        viewModel.show(tag: "rock")
        try await waitUntil { self.directory.queries.last?.tag == "rock" }
        XCTAssertTrue(viewModel.hasFilters)
    }

    func testLoadMoreAppendsTheNextPage() async throws {
        directory.pages = [0: (0..<30).map { Station.fixture($0) }, 30: [.fixture(30)]]
        let viewModel = makeViewModel()
        await viewModel.onAppear()
        try await waitUntil { viewModel.results.value?.count == 30 }
        XCTAssertTrue(viewModel.canLoadMore)

        await viewModel.loadMore()

        XCTAssertEqual(viewModel.results.value?.count, 31)
        XCTAssertFalse(viewModel.canLoadMore)
        XCTAssertEqual(directory.queries.last?.offset, 30)
    }

    func testShowsErrors() async throws {
        directory.searchResult = .failure(.directoryUnavailable)
        let viewModel = makeViewModel()
        await viewModel.onAppear()
        try await waitUntil { viewModel.results.errorMessage != nil }
        XCTAssertEqual(viewModel.results.errorMessage, StationError.directoryUnavailable.userMessage)
    }
}
