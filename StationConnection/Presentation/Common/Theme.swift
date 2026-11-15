import SwiftUI

/// Colores de la app: los mismos tokens que la versión web (tema oscuro).
enum Theme {
    static let background = Color(hex: 0x0B0B12)
    static let surface = Color(hex: 0x14141F)
    static let surface2 = Color(hex: 0x1C1C2B)
    static let border = Color(hex: 0x2A2A3D)
    static let foreground = Color(hex: 0xF2F2F7)
    static let muted = Color(hex: 0x9A9AB0)
    static let accent = Color(hex: 0xFF4F7B)
    static let accent2 = Color(hex: 0x8B5CF6)

    /// Degradados para las carátulas de emisoras sin logo (como en la web).
    static let artworkGradients: [[Color]] = [
        [Color(hex: 0xEC4899), Color(hex: 0x7C3AED)],
        [Color(hex: 0xFBBF24), Color(hex: 0xF43F5E)],
        [Color(hex: 0x34D399), Color(hex: 0x0891B2)],
        [Color(hex: 0x38BDF8), Color(hex: 0x4F46E5)],
        [Color(hex: 0xD946EF), Color(hex: 0x7E22CE)],
        [Color(hex: 0xFB923C), Color(hex: 0xDC2626)],
    ]
}

extension Color {
    /// `Color(hex: 0xFF4F7B)`.
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// Fondo oscuro de pantalla completa para listas y scrolls.
struct ScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
    }
}

extension View {
    func screenBackground() -> some View { modifier(ScreenBackground()) }
}
