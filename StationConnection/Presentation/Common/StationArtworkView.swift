import SwiftUI

/// Logo de la emisora o, si no tiene o no carga, sus iniciales sobre un
/// degradado (como en la versión web).
struct StationArtworkView: View {
    let station: Station
    var cornerRadius: CGFloat = 12

    var body: some View {
        ZStack {
            LinearGradient(
                colors: Theme.artworkGradients[station.gradientIndex],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            GeometryReader { proxy in
                Text(station.initials)
                    .font(.system(size: proxy.size.width * 0.34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            if let favicon = station.favicon {
                AsyncImage(url: favicon) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(.white)
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .accessibilityHidden(true)
    }
}
