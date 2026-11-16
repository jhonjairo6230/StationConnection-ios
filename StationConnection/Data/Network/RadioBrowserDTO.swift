import Foundation

/// Una emisora tal como la devuelve la API de Radio Browser.
///
/// Todo es opcional y se decodifica con tolerancia: la API es comunitaria y
/// los datos vienen incompletos o con tipos inesperados.
struct RadioBrowserStationDTO: Decodable {
    let stationuuid: String?
    let name: String?
    let url: String?
    let url_resolved: String?
    let homepage: String?
    let favicon: String?
    let tags: String?
    let country: String?
    let countrycode: String?
    let state: String?
    let language: String?
    let codec: String?
    let bitrate: Int?
    let hls: Int?
    let votes: Int?
    let clickcount: Int?

    private enum CodingKeys: String, CodingKey {
        case stationuuid, name, url, url_resolved, homepage, favicon, tags, country, countrycode
        case state, language, codec, bitrate, hls, votes, clickcount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        func string(_ key: CodingKeys) -> String? { try? container.decodeIfPresent(String.self, forKey: key) }
        func int(_ key: CodingKeys) -> Int? {
            if let value = try? container.decodeIfPresent(Int.self, forKey: key) { return value }
            if let value = try? container.decodeIfPresent(Double.self, forKey: key) { return Int(value) }
            return nil
        }
        stationuuid = string(.stationuuid)
        name = string(.name)
        url = string(.url)
        url_resolved = string(.url_resolved)
        homepage = string(.homepage)
        favicon = string(.favicon)
        tags = string(.tags)
        country = string(.country)
        countrycode = string(.countrycode)
        state = string(.state)
        language = string(.language)
        codec = string(.codec)
        bitrate = int(.bitrate)
        hls = int(.hls)
        votes = int(.votes)
        clickcount = int(.clickcount)
    }
}

/// Un género de Radio Browser.
struct RadioBrowserTagDTO: Decodable {
    let name: String?
    let stationcount: Int?
}

/// Un país de Radio Browser.
struct RadioBrowserCountryDTO: Decodable {
    let name: String?
    let iso_3166_1: String?
    let stationcount: Int?
}
