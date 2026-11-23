import AppIntents
import SwiftUI

/// Botones ▶ y ■ separados.
///
/// Sin App Group el widget no sabe si la radio suena; un solo botón ▶/■
/// mostraría siempre ▶. Con dos botones cada toque hace lo que dice.
struct PlayStopButtons: View {
    var size: CGFloat = 34

    var body: some View {
        HStack(spacing: 8) {
            Button(intent: ResumePlaybackIntent()) {
                RoundIcon(symbol: "play.fill", size: size, filled: true)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Reproducir la radio")

            Button(intent: StopPlaybackIntent()) {
                RoundIcon(symbol: "stop.fill", size: size, filled: false)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Detener la radio")
        }
    }
}

/// Botón ■ suelto (junto a los mosaicos de emisoras).
struct StopButton: View {
    var size: CGFloat = 34

    var body: some View {
        Button(intent: StopPlaybackIntent()) {
            RoundIcon(symbol: "stop.fill", size: size, filled: false)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Detener la radio")
    }
}

/// Círculo con un símbolo: relleno (acción principal) o con borde.
struct RoundIcon: View {
    let symbol: String
    let size: CGFloat
    let filled: Bool

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.4, weight: .bold))
            .foregroundStyle(filled ? Color.white : WidgetTheme.foreground)
            .frame(width: size, height: size)
            .background(Circle().fill(filled ? WidgetTheme.accent : WidgetTheme.surface))
            .overlay(Circle().stroke(WidgetTheme.muted.opacity(filled ? 0 : 0.4)))
    }
}

/// Mosaico de una emisora que la pone a sonar al tocarlo.
struct StationTile: View {
    let item: WidgetSnapshot.Item
    var isCurrent = false
    var artworkSize: CGFloat = 38

    var body: some View {
        Button(intent: PlayStationIntent(stationID: item.id)) {
            VStack(spacing: 2) {
                WidgetArtwork(item: item, cornerRadius: 8).frame(width: artworkSize)
                Text(item.name)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(isCurrent ? WidgetTheme.accent : WidgetTheme.foreground)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Reproducir \(item.name)")
    }
}

/// Rejilla 2×2 de emisoras (huecos vacíos si hay menos de cuatro).
struct StationGrid: View {
    let items: [WidgetSnapshot.Item]
    var currentID: String?

    var body: some View {
        Grid(horizontalSpacing: 8, verticalSpacing: 8) {
            GridRow { cell(0); cell(1) }
            GridRow { cell(2); cell(3) }
        }
    }

    @ViewBuilder
    private func cell(_ index: Int) -> some View {
        if items.indices.contains(index) {
            StationTile(item: items[index], isCurrent: items[index].id == currentID)
        } else {
            Color.clear.frame(width: 38, height: 50)
        }
    }
}

/// Un solo botón que cambia entre ▶ y ■ según lo que suena (solo con App Group).
struct PlaybackToggleButton: View {
    let isPlaying: Bool
    var size: CGFloat = 40

    var body: some View {
        if isPlaying {
            Button(intent: StopPlaybackIntent()) {
                RoundIcon(symbol: "stop.fill", size: size, filled: true)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Detener la radio")
        } else {
            Button(intent: ResumePlaybackIntent()) {
                RoundIcon(symbol: "play.fill", size: size, filled: true)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Reproducir la radio")
        }
    }
}

/// El ícono de la app como carátula cuando no hay emisora.
struct AppArtworkImage: View {
    var size: CGFloat = 40

    var body: some View {
        Image("AppArtwork")
            .resizable()
            .scaledToFit()
            .frame(width: size)
            .clipShape(RoundedRectangle(cornerRadius: size / 4, style: .continuous))
    }
}

/// Línea pequeña con el motivo del modo de respaldo ("La firma no trae App
/// Group"…): ayuda a saber qué pasa sin un Mac a mano.
struct DiagnosticText: View {
    let text: String?

    init(_ text: String?) { self.text = text }

    var body: some View {
        if let text {
            Text(text)
                .font(.system(size: 9))
                .foregroundStyle(WidgetTheme.muted)
                .lineLimit(2)
        }
    }
}
