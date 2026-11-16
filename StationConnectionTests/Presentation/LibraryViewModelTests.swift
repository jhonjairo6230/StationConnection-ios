import XCTest
@testable import StationConnection

@MainActor
final class LibraryViewModelTests: XCTestCase {
    func testToggleFavoriteAndNotify() {
        let library = makeLibrary()
        var notified: [[Station]] = []
        library.onFavoritesChanged = { notified.append($0) }

        library.toggleFavorite(.fixture(1))

        XCTAssertTrue(library.isFavorite(.fixture(1)))
        XCTAssertEqual(notified, [[.fixture(1)]])
    }

    func testMoveAndSortFavorites() {
        let library = makeLibrary(favorites: [.fixture(1, name: "Zeta"), .fixture(2, name: "Alfa"), .fixture(3, name: "Beta")])

        library.moveFavorites(from: IndexSet(integer: 0), to: 3)
        XCTAssertEqual(library.favorites.map(\.name), ["Alfa", "Beta", "Zeta"])

        library.moveFavorites(from: IndexSet(integer: 2), to: 0)
        library.sortFavoritesByName()
        XCTAssertEqual(library.favorites.map(\.name), ["Alfa", "Beta", "Zeta"])
    }

    func testExportAndImportBetweenDevices() throws {
        let source = makeLibrary(favorites: makeStations([1, 2]))
        let file = try XCTUnwrap(source.exportFavorites())
        XCTAssertTrue(file.fileName.hasPrefix("stationconnection-favoritas-"))

        let target = makeLibrary(favorites: [.fixture(2)])
        target.importFavorites(file.data)

        XCTAssertEqual(target.favorites.map(\.name), ["Radio 2", "Radio 1"])
        XCTAssertEqual(target.alert?.message, "Se añadió 1 emisora, 1 ya estaba en tu lista.")
    }

    func testInvalidImportShowsAnAlert() {
        let library = makeLibrary()
        library.importFavorites(Data("nada".utf8))
        XCTAssertEqual(library.alert, AlertMessage(error: StationError.invalidBackup))
    }

    func testRecentsAndSongs() {
        let library = makeLibrary()
        library.addRecent(.fixture(1))
        library.recordSong(Song.parse("A - B")!, on: .fixture(1))
        XCTAssertEqual(library.recents, [.fixture(1)])
        XCTAssertEqual(library.songs.count, 1)
        library.clearRecents()
        library.clearSongs()
        XCTAssertTrue(library.recents.isEmpty)
        XCTAssertTrue(library.songs.isEmpty)
    }
}
