import XCTest
@testable import StationConnection

final class RadioBrowserMapperTests: XCTestCase {
    private func dto(_ json: String) throws -> RadioBrowserStationDTO {
        try JSONDecoder().decode(RadioBrowserStationDTO.self, from: Data(json.utf8))
    }

    func testMapsAStation() throws {
        let station = RadioBrowserMapper.station(from: try dto("""
        {"stationuuid":"960E57C5-0601-11E8-AE97-52543BE04C81","name":"  Radio Prueba ","url":"http://s.example.com/live",
         "url_resolved":"https://s.example.com/live.mp3","homepage":"https://radio.example.com","favicon":"https://radio.example.com/logo.png",
         "tags":"Rock, pop,rock, ,Indie","country":"Colombia","countrycode":"co","codec":"MP3","bitrate":128,"hls":0,"votes":10,"clickcount":42}
        """))
        XCTAssertEqual(station?.id, "960e57c5-0601-11e8-ae97-52543be04c81")
        XCTAssertEqual(station?.name, "Radio Prueba")
        XCTAssertEqual(station?.streamURL.absoluteString, "https://s.example.com/live.mp3")
        XCTAssertEqual(station?.tags, ["rock", "pop", "indie"])
        XCTAssertEqual(station?.countryCode, "CO")
        XCTAssertEqual(station?.clicks, 42)
        XCTAssertEqual(station?.isHLS, false)
    }

    func testAcceptsHttpStreamsButOnlyHttpsLogos() throws {
        let station = RadioBrowserMapper.station(from: try dto("""
        {"stationuuid":"a","name":"R","url":"http://s.example.com/live","url_resolved":"","favicon":"http://x.com/logo.png"}
        """))
        XCTAssertEqual(station?.streamURL.absoluteString, "http://s.example.com/live")
        XCTAssertNil(station?.favicon)
    }

    func testDiscardsStationsWithoutAValidStream() throws {
        XCTAssertNil(RadioBrowserMapper.station(from: try dto(#"{"stationuuid":"a","name":"R","url":"javascript:alert(1)"}"#)))
        XCTAssertNil(RadioBrowserMapper.station(from: try dto(#"{"name":"R","url":"https://x.com"}"#)))
    }

    func testToleratesUnexpectedTypes() throws {
        let station = RadioBrowserMapper.station(from: try dto("""
        {"stationuuid":"a","name":null,"url":"https://x.com","bitrate":"oops","votes":12.0,"hls":1}
        """))
        XCTAssertEqual(station?.name, "Emisora sin nombre")
        XCTAssertEqual(station?.bitrate, 0)
        XCTAssertEqual(station?.votes, 12)
        XCTAssertEqual(station?.isHLS, true)
    }

    func testRemovesDuplicates() throws {
        let one = try dto(#"{"stationuuid":"a","url":"https://x.com"}"#)
        XCTAssertEqual(RadioBrowserMapper.stations(from: [one, one]).count, 1)
    }

    func testBuildsSearchParameters() {
        let items = RadioBrowserMapper.searchItems(for: StationQuery(name: "jazz fm", tag: "jazz", countryCode: "CO", order: .trending))
        let values = Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value ?? "") })
        XCTAssertEqual(values["name"], "jazz fm")
        XCTAssertEqual(values["tag"], "jazz")
        XCTAssertEqual(values["tagExact"], "true")
        XCTAssertEqual(values["countrycode"], "CO")
        XCTAssertEqual(values["order"], "clicktrend")
        XCTAssertEqual(values["reverse"], "true")
        XCTAssertEqual(values["hidebroken"], "true")
        XCTAssertNil(values["is_https"], "en iOS el audio por http está permitido")
    }

    func testNameOrderIsAscending() {
        let items = RadioBrowserMapper.searchItems(for: StationQuery(order: .name))
        XCTAssertEqual(items.first { $0.name == "reverse" }?.value, "false")
    }
}
