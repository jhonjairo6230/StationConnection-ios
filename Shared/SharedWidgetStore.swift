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

    /// - Parameter defaults: `nil` si el App Group no está disponible. Las pruebas pasan uno temporal.
    init(defaults: UserDefaults?) {
        self.defaults = defaults
    }

    /// El almacén real. Comprueba que la firma incluya el App Group antes de usarlo.
    static func live(fileManager: FileManager = .default) -> SharedWidgetStore {
        guard fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroup) != nil else {
            return SharedWidgetStore(defaults: nil)
        }
        return SharedWidgetStore(defaults: UserDefaults(suiteName: appGroup))
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
