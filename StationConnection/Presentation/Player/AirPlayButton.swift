import AVKit
import SwiftUI

/// Botón del sistema para elegir dónde suena el audio: AirPlay (HomePod,
/// Apple TV, parlantes compatibles), Bluetooth o el propio teléfono.
///
/// Es la única forma "oficial" de mostrar el selector de AirPlay; por eso se
/// envuelve la vista de UIKit `AVRoutePickerView`.
struct AirPlayButton: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView()
        view.tintColor = UIColor(Theme.muted)
        view.activeTintColor = UIColor(Theme.accent)
        view.prioritizesVideoDevices = false
        view.accessibilityLabel = "Enviar a un parlante"
        return view
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}
