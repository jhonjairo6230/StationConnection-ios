import SwiftUI
import WidgetKit

/// Punto de entrada de la extensión de widgets.
///
/// La extensión es un programa aparte: no tiene reproductor ni red. Lee la
/// foto que publica la app (`SharedWidgetStore`) y sus botones son
/// `AudioPlaybackIntent` que iOS ejecuta dentro de la app.
@main
struct StationConnectionWidgets: WidgetBundle {
    var body: some Widget {
        NowPlayingWidget()
        FavoritesWidget()
    }
}
