import SwiftUI

/// La lista en la que está un botón ▶ (carrusel, resultados, favoritas…).
///
/// Al reproducir, el reproductor la usa como cola para ⏮/⏭ y para los botones
/// del auto. Cada lista la publica con `.stationQueue(stations)`.
private struct StationQueueKey: EnvironmentKey {
    static let defaultValue: [Station] = []
}

extension EnvironmentValues {
    var stationQueue: [Station] {
        get { self[StationQueueKey.self] }
        set { self[StationQueueKey.self] = newValue }
    }
}

extension View {
    func stationQueue(_ stations: [Station]) -> some View {
        environment(\.stationQueue, stations)
    }
}
