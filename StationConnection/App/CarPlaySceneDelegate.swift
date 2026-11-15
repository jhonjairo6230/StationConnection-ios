import CarPlay
import UIKit

/// Punto de entrada de CarPlay: iOS crea esta escena cuando el teléfono se
/// conecta a un auto compatible (declarada en `project.yml` →
/// `UIApplicationSceneManifest`).
///
/// UIKit la instancia sin pasarle nada, así que toma las dependencias del
/// mismo ``AppContainer`` que usa la app (``AppContainer/shared``).
final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    private var interface: CarPlayInterface?

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        MainActor.assumeIsolated {
            let container = AppContainer.shared
            let interface = CarPlayInterface(
                interfaceController: interfaceController,
                player: container.player,
                library: container.library,
                search: container.searchStations
            )
            interface.start()
            self.interface = interface
        }
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        interface = nil
    }
}
