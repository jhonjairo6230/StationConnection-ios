import AppIntents
import WidgetKit

/// Una emisora que el usuario elige al configurar un widget ("Editar widget").
struct RadioStationEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Emisora"
    static let defaultQuery = RadioStationQuery()

    let id: String
    let name: String
    let detail: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(detail)")
    }

    init(_ result: RadioBrowserLookup.Result) {
        id = result.id
        name = result.name
        detail = result.detail
    }

    /// Lo que pinta el widget (iniciales y degradado como en la app).
    var item: WidgetSnapshot.Item {
        WidgetSnapshot.Item(
            id: id,
            name: name,
            subtitle: detail,
            initials: StationArtworkText.initials(for: name),
            gradientIndex: StationArtworkText.gradientIndex(for: id)
        )
    }
}

/// Busca emisoras para el selector del widget: populares al abrirlo y por
/// nombre al escribir.
struct RadioStationQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [RadioStationEntity] {
        await RadioBrowserLookup().stations(ids: identifiers).map(RadioStationEntity.init)
    }

    func entities(matching string: String) async throws -> [RadioStationEntity] {
        try await RadioBrowserLookup().search(string).map(RadioStationEntity.init)
    }

    func suggestedEntities() async throws -> [RadioStationEntity] {
        try await RadioBrowserLookup().popular().map(RadioStationEntity.init)
    }
}

/// Configuración del widget pequeño "Mi emisora" (inicio y CarPlay).
struct OneStationIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Elegir emisora"
    static let description = IntentDescription("Elige la emisora del widget.")

    @Parameter(title: "Emisora")
    var station: RadioStationEntity?

    init() {}
}

/// Configuración del widget mediano "Mis emisoras".
struct FourStationsIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Elegir emisoras"
    static let description = IntentDescription("Elige hasta cuatro emisoras para el widget.")

    @Parameter(title: "Emisora 1") var first: RadioStationEntity?
    @Parameter(title: "Emisora 2") var second: RadioStationEntity?
    @Parameter(title: "Emisora 3") var third: RadioStationEntity?
    @Parameter(title: "Emisora 4") var fourth: RadioStationEntity?

    init() {}

    var stations: [RadioStationEntity] { [first, second, third, fourth].compactMap { $0 } }
}
