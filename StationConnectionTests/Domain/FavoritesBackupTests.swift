import XCTest
@testable import StationConnection

final class FavoritesBackupTests: XCTestCase {
    func testRoundTripKeepsTheStations() throws {
        let favorites = [Station.fixture(1), Station.fixture(2, favicon: URL(string: "https://x.com/logo.png"))]
        let data = try FavoritesBackup.encode(favorites, now: Date(timeIntervalSince1970: 0))
        let contents = try FavoritesBackup.decode(data)
        XCTAssertEqual(contents, FavoritesBackup.Contents(stations: favorites, skipped: 0))
    }

    func testUsesTheSameFormatAsTheWebApp() throws {
        let data = try FavoritesBackup.encode([.fixture(1)])
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(json["app"] as? String, "StationConnection")
        XCTAssertEqual(json["version"] as? Int, 1)
        let station = try XCTUnwrap((json["favorites"] as? [[String: Any]])?.first)
        XCTAssertEqual(station["streamUrl"] as? String, "https://example.com/1")
        XCTAssertEqual(station["hls"] as? Bool, false)
    }

    func testReadsABackupExportedByTheWebApp() throws {
        let web = """
        {"app":"StationConnection","version":1,"exportedAt":"2026-11-07T10:00:00.000Z","favorites":[
          {"id":"960e57c5-0601-11e8-ae97-52543be04c81","name":"Radio Web","streamUrl":"https://stream.example.com/live",
           "homepage":null,"favicon":null,"tags":["rock"],"country":"Colombia","countryCode":"CO","state":null,
           "language":null,"codec":"MP3","bitrate":128,"hls":false,"votes":3,"clicks":10}
        ]}
        """
        let contents = try FavoritesBackup.decode(Data(web.utf8))
        XCTAssertEqual(contents.stations.map(\.name), ["Radio Web"])
        XCTAssertEqual(contents.stations.first?.bitrate, 128)
    }

    func testAcceptsAPlainListAndSkipsInvalidAndRepeatedEntries() throws {
        let station = try JSONSerialization.jsonObject(with: JSONEncoder().encode(Station.fixture(1)))
        let data = try JSONSerialization.data(withJSONObject: [station, station, ["name": "sin id"], 42] as [Any])
        XCTAssertEqual(try FavoritesBackup.decode(data).skipped, 3)
    }

    func testRejectsInvalidFiles() {
        XCTAssertThrowsError(try FavoritesBackup.decode(Data("{no json".utf8)))
        XCTAssertThrowsError(try FavoritesBackup.decode(Data(#"{"hola":1}"#.utf8)))
    }

    func testSanitizesDangerousOrInvalidURLs() {
        var raw: [String: Any] = ["id": Station.fixture(1).id, "name": "R", "streamUrl": "javascript:alert(1)"]
        XCTAssertNil(FavoritesBackup.sanitize(raw))
        raw["streamUrl"] = "http://stream.example.com/live" // el audio por http está permitido
        raw["homepage"] = "javascript:alert(1)"
        raw["favicon"] = "http://x.com/logo.png" // los logos solo por https
        let station = FavoritesBackup.sanitize(raw)
        XCTAssertNotNil(station)
        XCTAssertNil(station?.homepage)
        XCTAssertNil(station?.favicon)
    }

    func testClampsAndNormalizesFields() {
        let raw: [String: Any] = [
            "id": Station.fixture(1).id.uppercased(), "name": String(repeating: "A", count: 500),
            "streamUrl": "https://x.com", "bitrate": -5, "tags": ["Rock", 3, ""], "hls": "yes",
        ]
        let station = FavoritesBackup.sanitize(raw)
        XCTAssertEqual(station?.id, Station.fixture(1).id)
        XCTAssertEqual(station?.name.count, 200)
        XCTAssertEqual(station?.bitrate, 0)
        XCTAssertEqual(station?.tags, ["rock"])
        XCTAssertEqual(station?.isHLS, false)
    }
}
