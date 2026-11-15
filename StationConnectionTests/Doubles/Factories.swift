import Foundation
import XCTest
@testable import StationConnection

/// Biblioteca con repositorios en memoria.
@MainActor
func makeLibrary(
    favorites: [Station] = [],
    favoritesRepository: InMemoryListRepository<Station> = InMemoryListRepository<Station>()
) -> LibraryViewModel {
    try? favoritesRepository.save(favorites)
    let recents = InMemoryListRepository<Station>()
    let songs = InMemoryListRepository<PlayedSong>()
    return LibraryViewModel(
        loadFavorites: LoadFavoritesUseCase(repository: favoritesRepository),
        toggleFavorite: ToggleFavoriteUseCase(repository: favoritesRepository),
        reorderFavorites: ReorderFavoritesUseCase(repository: favoritesRepository),
        exportFavorites: ExportFavoritesUseCase(repository: favoritesRepository),
        importFavorites: ImportFavoritesUseCase(repository: favoritesRepository),
        recents: RecentsUseCase(repository: recents),
        songHistory: SongHistoryUseCase(repository: songs)
    )
}

/// Espera (como máximo 2 s) a que se cumpla una condición.
@MainActor
func waitUntil(
    _ condition: @escaping () -> Bool,
    file: StaticString = #filePath,
    line: UInt = #line
) async throws {
    for _ in 0..<200 {
        if condition() { return }
        try await Task.sleep(for: .milliseconds(10))
    }
    XCTFail("La condición no se cumplió a tiempo", file: file, line: line)
}
