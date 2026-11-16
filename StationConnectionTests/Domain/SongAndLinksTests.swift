import XCTest
@testable import StationConnection

final class SongTests: XCTestCase {
    func testSplitsArtistAndTitle() {
        XCTAssertEqual(Song.parse("  Shakira -  Hips Don't Lie "), Song(raw: "Shakira - Hips Don't Lie", artist: "Shakira", title: "Hips Don't Lie"))
    }

    func testWithoutSeparatorEverythingIsTheTitle() {
        XCTAssertEqual(Song.parse("Noticias de las 8"), Song(raw: "Noticias de las 8", artist: nil, title: "Noticias de las 8"))
    }

    func testUsesTheFirstSpacedDash() {
        XCTAssertEqual(Song.parse("A-ha - Take On Me")?.artist, "A-ha")
    }

    func testIgnoresPlaceholders() {
        XCTAssertNil(Song.parse(" - "))
        XCTAssertNil(Song.parse("Unknown"))
        XCTAssertNil(Song.parse(""))
    }
}

final class MusicSearchLinksTests: XCTestCase {
    func testBuildsSearchLinksForTheThreeServices() {
        let links = MusicSearchLinks(song: Song(raw: "", artist: "Aterciopelados", title: "Bolero Falaz"))
        XCTAssertEqual(links.youtubeMusic.absoluteString, "https://music.youtube.com/search?q=Aterciopelados%20Bolero%20Falaz")
        XCTAssertEqual(links.youtube.absoluteString, "https://www.youtube.com/results?search_query=Aterciopelados%20Bolero%20Falaz")
        XCTAssertEqual(links.spotify.absoluteString, "https://open.spotify.com/search/Aterciopelados%20Bolero%20Falaz")
    }

    func testEscapesCharactersThatWouldBreakTheQuery() {
        let links = MusicSearchLinks(song: Song(raw: "", artist: nil, title: "Rock & Roll?"))
        XCTAssertEqual(links.youtubeMusic.absoluteString, "https://music.youtube.com/search?q=Rock%20%26%20Roll%3F")
    }
}

final class StationQueryTests: XCTestCase {
    func testNormalizesAndClampsValues() {
        let query = StationQuery(name: "  jazz ", tag: " Rock ", countryCode: "col", order: .votes, limit: 999, offset: -3).normalized()
        XCTAssertEqual(query, StationQuery(name: "jazz", tag: "rock", countryCode: "CO", order: .votes, limit: 100, offset: 0))
    }
}
