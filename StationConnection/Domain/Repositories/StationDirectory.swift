import Foundation

/// Puerto del directorio de emisoras.
///
/// El dominio define **qué** necesita (buscar, pedir por id, géneros, países);
/// la capa Data decide **cómo** (hoy, la API pública de Radio Browser).
protocol StationDirectory: Sendable {
    /// - Throws: ``StationError/directoryUnavailable``.
    func search(_ query: StationQuery) async throws -> [Station]

    /// Emisoras por id, en el mismo orden pedido (las que no existan se omiten).
    /// - Throws: ``StationError/directoryUnavailable``.
    func stations(ids: [String]) async throws -> [Station]

    /// Los géneros con más emisoras.
    func topTags(limit: Int) async throws -> [Tag]

    /// Países con emisoras, ordenados por nombre.
    func countries() async throws -> [Country]

    /// Avisa al directorio de que se escuchó una emisora (estadística de uso).
    /// Si falla no importa: no lanza errores.
    func registerPlay(stationID: String) async
}
