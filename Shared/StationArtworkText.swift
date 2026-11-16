import Foundation

/// Iniciales y degradado de la carátula de una emisora sin logo.
///
/// Lo usan la app (`Station+Display`) y los widgets configurables, que solo
/// tienen el id y el nombre de la emisora: así la carátula es la misma en todas
/// partes.
///
/// Este archivo se compila en la app **y** en la extensión de widgets.
enum StationArtworkText {
    /// Cantidad de degradados (`Theme.artworkGradients` y `WidgetTheme.gradients`).
    static let gradientCount = 6

    /// "La Mega" → "LM"; "Tropicana" → "TR".
    static func initials(for name: String) -> String {
        let words = name
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        if words.count > 1 { return (String(words[0].prefix(1)) + String(words[1].prefix(1))).uppercased() }
        return String((words.first ?? "?").prefix(2)).uppercased()
    }

    /// Índice estable del degradado según el id.
    static func gradientIndex(for id: String) -> Int {
        var hash: UInt32 = 0
        for scalar in id.unicodeScalars { hash = hash &* 31 &+ scalar.value }
        return Int(hash % UInt32(gradientCount))
    }
}
