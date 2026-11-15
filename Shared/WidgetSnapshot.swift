import Foundation

/// Lo que los widgets necesitan saber de la app: qué suena (o qué sonó por
/// última vez) y las primeras favoritas.
///
/// La app lo escribe cada vez que algo cambia (``SharedWidgetStore``) y los
/// widgets solo lo leen: un widget no puede pedir datos a la red ni al
/// reproductor por su cuenta.
///
/// Este archivo se compila en la app **y** en la extensión de widgets.
struct WidgetSnapshot: Codable, Equatable {
    /// Una emisora reducida a lo que pinta un widget.
    struct Item: Codable, Equatable, Identifiable {
        let id: String
        let name: String
        let subtitle: String
        /// Iniciales y degradado para la carátula (los widgets no descargan logos).
        let initials: String
        let gradientIndex: Int
    }

    /// Lo que suena o, si no suena nada, la última emisora escuchada.
    var current: Item?
    var isPlaying: Bool
    var songTitle: String?
    var songArtist: String?
    /// Las primeras favoritas, en el orden del usuario.
    var favorites: [Item]

    static let maxFavorites = 4

    static let empty = WidgetSnapshot(current: nil, isPlaying: false, songTitle: nil, songArtist: nil, favorites: [])
}
