import SwiftUI

/// Colores de los widgets: los mismos que la app (y que la versión web).
enum WidgetTheme {
    static let background = Color(red: 0x0B / 255, green: 0x0B / 255, blue: 0x12 / 255)
    static let surface = Color(red: 0x14 / 255, green: 0x14 / 255, blue: 0x1F / 255)
    static let foreground = Color(red: 0xF2 / 255, green: 0xF2 / 255, blue: 0xF7 / 255)
    static let muted = Color(red: 0x9A / 255, green: 0x9A / 255, blue: 0xB0 / 255)
    static let accent = Color(red: 0xFF / 255, green: 0x4F / 255, blue: 0x7B / 255)

    /// Mismo orden que `Theme.artworkGradients` de la app (el índice viaja en la foto).
    static let gradients: [[Color]] = [
        [rgb(0xEC4899), rgb(0x7C3AED)],
        [rgb(0xFBBF24), rgb(0xF43F5E)],
        [rgb(0x34D399), rgb(0x0891B2)],
        [rgb(0x38BDF8), rgb(0x4F46E5)],
        [rgb(0xD946EF), rgb(0x7E22CE)],
        [rgb(0xFB923C), rgb(0xDC2626)],
    ]

    private static func rgb(_ hex: UInt32) -> Color {
        Color(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}

/// Carátula de una emisora en un widget: iniciales sobre su degradado
/// (los widgets no pueden descargar logos).
struct WidgetArtwork: View {
    let item: WidgetSnapshot.Item
    var cornerRadius: CGFloat = 10

    var body: some View {
        let colors = WidgetTheme.gradients[abs(item.gradientIndex) % WidgetTheme.gradients.count]
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay {
                GeometryReader { proxy in
                    Text(item.initials)
                        .font(.system(size: proxy.size.width * 0.36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.92))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .aspectRatio(1, contentMode: .fit)
    }
}
