import Foundation

/// Guarda la ``WidgetSnapshot`` donde la app y los widgets pueden leerla: un
/// **App Group** (un contenedor compartido entre la app y su extensión).
///
/// El App Group necesita estar en la firma. Con la firma gratuita de Sideloadly
/// puede no estarlo: en ese caso ``isAvailable`` es `false`, la app no guarda
/// nada y los widgets muestran un modo de respaldo (sus botones siguen
/// funcionando porque se ejecutan dentro de la app). Ver docs/adr/0010-widgets.md.
///
/// Este archivo se compila en la app **y** en la extensión de widgets.
struct SharedWidgetStore {
    static let appGroup = "group.com.jhonjairo6230.stationconnection"
    private static let key = "widgetSnapshot.v1"

    private let defaults: UserDefaults?
    /// El grupo que se abrió, o `nil`.
    let group: String?
    /// Por qué no hay datos compartidos (lo muestra el widget en su modo de respaldo).
    let diagnostic: String?

    /// - Parameter defaults: `nil` si el App Group no está disponible. Las pruebas pasan uno temporal.
    init(defaults: UserDefaults?, group: String? = nil, diagnostic: String? = nil) {
        self.defaults = defaults
        self.group = group
        self.diagnostic = defaults == nil ? (diagnostic ?? "Sin App Group") : nil
    }

    /// El almacén real: el primer App Group de la firma que iOS deja abrir.
    ///
    /// Sideloadly puede registrar el grupo con **otro nombre** (por ejemplo,
    /// añadiendo el identificador del equipo). Por eso, además del nombre de
    /// `project.yml`, se prueban los grupos del perfil de firma incrustado
    /// (`embedded.mobileprovision`). La app y la extensión llegan al mismo
    /// grupo porque los ordenan igual.
    static func live(fileManager: FileManager = .default, bundle: Bundle = .main) -> SharedWidgetStore {
        let profile = bundle.url(forResource: "embedded", withExtension: "mobileprovision")
            .flatMap { try? Data(contentsOf: $0) }
        let provisioned = profile.map { provisionedGroups(in: $0) } ?? []
        for group in candidateGroups(provisioned: provisioned)
        where fileManager.containerURL(forSecurityApplicationGroupIdentifier: group) != nil {
            return SharedWidgetStore(defaults: UserDefaults(suiteName: group), group: group)
        }
        let diagnostic: String
        if profile == nil {
            diagnostic = "Sin perfil de firma"
        } else if provisioned.isEmpty {
            diagnostic = "La firma no trae App Group"
        } else {
            diagnostic = "iOS no abre el App Group de la firma"
        }
        return SharedWidgetStore(defaults: nil, diagnostic: diagnostic)
    }

    /// Orden de prueba: el de `project.yml`, luego los que mencionan la app y
    /// luego el resto, cada bloque en orden alfabético.
    static func candidateGroups(provisioned: [String]) -> [String] {
        let others = Set(provisioned).subtracting([appGroup])
        let related = others.filter { $0.lowercased().contains("stationconnection") }.sorted()
        let rest = others.subtracting(related).sorted()
        return [appGroup] + related + rest
    }

    /// Los App Groups que declara un perfil de firma (`embedded.mobileprovision`).
    ///
    /// El perfil es un plist envuelto en una firma CMS; basta con recortar el
    /// XML de dentro.
    static func provisionedGroups(in profile: Data) -> [String] {
        guard let start = profile.range(of: Data("<?xml".utf8)),
              let end = profile.range(of: Data("</plist>".utf8), in: start.lowerBound..<profile.endIndex),
              let plist = try? PropertyListSerialization.propertyList(
                from: profile.subdata(in: start.lowerBound..<end.upperBound), format: nil
              ) as? [String: Any],
              let entitlements = plist["Entitlements"] as? [String: Any]
        else { return [] }
        return entitlements["com.apple.security.application-groups"] as? [String] ?? []
    }

    var isAvailable: Bool { defaults != nil }

    func load() -> WidgetSnapshot? {
        guard let data = defaults?.data(forKey: Self.key) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    func save(_ snapshot: WidgetSnapshot) {
        guard let defaults, let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: Self.key)
    }
}
