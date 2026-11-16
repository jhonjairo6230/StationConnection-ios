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
        .description("La última emisora, con ▶ y ■. También en CarPlay.")
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
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                if let item = snapshot.current {
                    WidgetArtwork(item: item).frame(width: 40)
                } else {
                    Image("AppArtwork").resizable().scaledToFit().frame(width: 40).clipShape(RoundedRectangle(cornerRadius: 10))
                }
                Spacer()
            }
            Spacer(minLength: 0)
            if let item = snapshot.current {
                Text(item.name)
                    .font(.headline)
                    .foregroundStyle(WidgetTheme.foreground)
                    .lineLimit(1)
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
            PlayStopButtons(size: 32)
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
            VStack(spacing: 6) {
                Button(intent: ResumePlaybackIntent()) { Image(systemName: "play.fill") }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Reproducir la radio")
                Button(intent: StopPlaybackIntent()) { Image(systemName: "stop.fill") }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Detener la radio")
            }
        }
        .containerBackground(for: .widget) { Color.clear }
    }
}
