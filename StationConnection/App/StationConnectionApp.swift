import SwiftUI

/// Punto de entrada de la app.
///
/// Guarda el ``AppContainer`` (que al crearse no construye nada) y, cuando la
/// escena se muestra, le pide las dependencias y las inyecta: los ViewModels
/// compartidos (reproductor y biblioteca) van por el entorno.
@main
struct StationConnectionApp: App {
    private let container = AppContainer()

    var body: some Scene {
        WindowGroup {
            RootView(
                home: container.home,
                explore: container.explore,
                tuner: container.tuner,
                makeStationDetail: container.makeStationDetail
            )
            .environment(container.player)
            .environment(container.library)
            .preferredColorScheme(.dark)
        }
    }
}
