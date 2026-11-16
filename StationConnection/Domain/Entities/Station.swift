import Foundation

/// Una emisora de radio, tal como la entiende la app.
///
/// Es independiente del proveedor: hoy los datos vienen de Radio Browser, pero
/// la capa Data los convierte a este tipo, así que cambiar de directorio no
/// tocaría nada de aquí.
///
/// Los nombres de los campos en JSON (`streamUrl`, `hls`…) son **los mismos que
/// usa la app web**: un respaldo de favoritas exportado en la web se puede
/// importar aquí y al revés.
struct Station: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let name: String
    /// Dirección del audio en vivo (http o https; ver ADR 0008).
    let streamURL: URL
    /// Página web de la emisora.
    let homepage: URL?
    /// Logo (solo https: las imágenes no tienen la excepción de transporte del audio).
    let favicon: URL?
    /// Géneros en minúsculas, sin repetir.
    let tags: [String]
    let country: String?
    let countryCode: String?
    let state: String?
    let language: String?
    let codec: String?
    /// kbps; 0 si no se conoce.
    let bitrate: Int
    /// `true` si el stream es HLS (lista `.m3u8`).
    let isHLS: Bool
    let votes: Int
    let clicks: Int

    init(
        id: String,
        name: String,
        streamURL: URL,
        homepage: URL? = nil,
        favicon: URL? = nil,
        tags: [String] = [],
        country: String? = nil,
        countryCode: String? = nil,
        state: String? = nil,
        language: String? = nil,
        codec: String? = nil,
        bitrate: Int = 0,
        isHLS: Bool = false,
        votes: Int = 0,
        clicks: Int = 0
    ) {
        self.id = id
        self.name = name
        self.streamURL = streamURL
        self.homepage = homepage
        self.favicon = favicon
        self.tags = tags
        self.country = country
        self.countryCode = countryCode
        self.state = state
        self.language = language
        self.codec = codec
        self.bitrate = bitrate
        self.isHLS = isHLS
        self.votes = votes
        self.clicks = clicks
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, homepage, favicon, tags, country, countryCode, state, language, codec, bitrate, votes, clicks
        case streamURL = "streamUrl"
        case isHLS = "hls"
    }
}
