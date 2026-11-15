import SwiftUI

/// Botón ▶/■ de una emisora. Usa la cola del entorno (``stationQueue(_:)``).
struct PlayButton: View {
    @Environment(PlayerViewModel.self) private var player
    @Environment(\.stationQueue) private var queue
    let station: Station
    var size: CGFloat = 40

    var body: some View {
        let active = player.isPlaying(station) || player.isLoading(station)
        Button {
            player.toggle(station, from: queue.isEmpty ? nil : queue)
        } label: {
            ZStack {
                Circle().fill(Theme.accent)
                if player.isLoading(station) {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: active ? "stop.fill" : "play.fill")
                        .font(.system(size: size * 0.4, weight: .bold))
                        .foregroundStyle(.white)
                        .offset(x: active ? 0 : size * 0.03)
                }
            }
            .frame(width: size, height: size)
            .shadow(color: Theme.accent.opacity(0.35), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(active ? "Detener \(station.name)" : "Reproducir \(station.name)")
    }
}

/// Corazón para añadir o quitar de favoritas.
struct FavoriteButton: View {
    @Environment(LibraryViewModel.self) private var library
    let station: Station
    var size: CGFloat = 20

    var body: some View {
        let isFavorite = library.isFavorite(station)
        Button {
            library.toggleFavorite(station)
        } label: {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.system(size: size))
                .foregroundStyle(isFavorite ? Theme.accent : Theme.muted)
                .frame(width: size * 2, height: size * 2)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isFavorite)
        .accessibilityLabel(isFavorite ? "Quitar \(station.name) de favoritas" : "Añadir \(station.name) a favoritas")
    }
}

/// Ecualizador animado para la emisora que suena.
struct EqualizerView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Theme.accent)
                    .frame(width: 3, height: 14)
                    .scaleEffect(y: reduceMotion ? 0.6 : (animate ? 1 : 0.3), anchor: .bottom)
                    .animation(
                        reduceMotion ? nil : .easeInOut(duration: 0.45).repeatForever().delay(Double(index) * 0.15),
                        value: animate
                    )
            }
        }
        .frame(height: 14)
        .onAppear { animate = true }
        .accessibilityHidden(true)
    }
}
