import AppIntents
import SwiftUI
import WidgetKit

/// Widget "Sonando": la emisora y la canción, con ▶/■.
///
/// - **Pequeño:** pantalla de inicio y, desde iOS 26, **CarPlay** (los
///   widgets `systemSmall` aparecen en el auto sin necesitar el permiso de
///   CarPlay).
/// - **Pantalla de bloqueo:** círculo (▶/■) y rectángulo (emisora y canción).
struct NowPlayingWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "NowPlaying", provider: SnapshotProvider()) { entry in
            NowPlayingWidgetView(entry: entry)
        }
        .configurationDisplayName("Sonando")
        .description("La emisora que suena, con un botón para reproducir o detener. También en CarPlay.")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular])
    }
}

struct NowPlayingWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: StationEntry

    var body: some View {
        switch family {
        case .accessoryCircular: circular
        case .accessoryRectangular: rectangular
        default: small
        }
    }

    private var snapshot: WidgetSnapshot { entry.snapshot }

    /// Línea bajo el nombre: la canción, "En vivo" o el estado.
    private var detail: String {
        if let title = snapshot.songTitle {
            return snapshot.songArtist.map { "\($0) – \(title)" } ?? title
        }
        if snapshot.isPlaying { return "En vivo" }
        return snapshot.current == nil ? "" : "Toca ▶ para escuchar"
    }

    // MARK: - Pequeño (inicio y CarPlay)

    private var small: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                if let item = snapshot.current {
                    WidgetArtwork(item: item).frame(width: 44)
                } else {
                    Image("AppArtwork").resizable().scaledToFit().frame(width: 44).clipShape(RoundedRectangle(cornerRadius: 10))
                }
                Spacer()
                ToggleButton(isPlaying: snapshot.isPlaying, size: 40)
            }
            Spacer(minLength: 0)
            if let item = snapshot.current {
                Text(snapshot.isPlaying ? "SONANDO" : "ÚLTIMA")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(WidgetTheme.muted)
                Text(item.name)
                    .font(.headline)
                    .foregroundStyle(WidgetTheme.foreground)
                    .lineLimit(2)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(WidgetTheme.muted)
                    .lineLimit(1)
            } else {
                Text("StationConnection")
                    .font(.headline)
                    .foregroundStyle(WidgetTheme.foreground)
                Text(entry.hasSharedData ? "Pon una emisora en la app" : "▶ retoma tu última emisora")
                    .font(.caption)
                    .foregroundStyle(WidgetTheme.muted)
            }
        }
        .containerBackground(for: .widget) { WidgetTheme.background }
    }

    // MARK: - Pantalla de bloqueo

    private var circular: some View {
        Button(intent: TogglePlaybackIntent()) {
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: snapshot.isPlaying ? "stop.fill" : "radio")
                    .font(.title3)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(snapshot.isPlaying ? "Detener la radio" : "Reproducir la radio")
        .containerBackground(for: .widget) { Color.clear }
    }

    private var rectangular: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(snapshot.current?.name ?? "StationConnection")
                    .font(.headline)
                    .lineLimit(1)
                Text(detail.isEmpty ? "Radio en vivo" : detail)
                    .font(.caption)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            Button(intent: TogglePlaybackIntent()) {
                Image(systemName: snapshot.isPlaying ? "stop.fill" : "play.fill")
            }
            .buttonStyle(.plain)
        }
        .containerBackground(for: .widget) { Color.clear }
    }
}

/// Botón ▶/■ redondo de los widgets de inicio.
struct ToggleButton: View {
    let isPlaying: Bool
    let size: CGFloat

    var body: some View {
        Button(intent: TogglePlaybackIntent()) {
            Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(Circle().fill(WidgetTheme.accent))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isPlaying ? "Detener la radio" : "Reproducir la radio")
    }
}
