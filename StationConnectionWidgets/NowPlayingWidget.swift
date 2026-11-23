import AppIntents
import SwiftUI
import WidgetKit

/// Widget "Sonando": la emisora y la canción.
///
/// - **Pequeño:** pantalla de inicio y, desde iOS 26, **CarPlay** (los
///   widgets `systemSmall` aparecen en el auto sin necesitar el permiso de
///   CarPlay).
/// - **Pantalla de bloqueo:** círculo (▶/■) y rectángulo (emisora y canción).
///
/// Con App Group sabe si la radio suena: un solo botón que cambia entre ▶ y ■.
/// Sin App Group no lo sabe: ▶ y ■ separados (ver docs/adr/0014-widget-con-estado.md).
struct NowPlayingWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "NowPlaying", provider: SnapshotProvider()) { entry in
            NowPlayingWidgetView(entry: entry)
        }
        .configurationDisplayName("Sonando")
        .description("La emisora que suena, con ▶/■. También en CarPlay.")
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
        return snapshot.current == nil ? "" : "Detenida"
    }

    // MARK: - Pequeño (inicio y CarPlay)

    private var small: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                if let item = snapshot.current {
                    WidgetArtwork(item: item).frame(width: 44)
                } else {
                    AppArtworkImage(size: 40)
                }
                Spacer(minLength: 0)
                if entry.hasSharedData {
                    PlaybackToggleButton(isPlaying: snapshot.isPlaying, size: 40)
                }
            }
            Spacer(minLength: 0)
            if entry.hasSharedData, let item = snapshot.current {
                Text(item.name)
                    .font(.headline)
                    .foregroundStyle(WidgetTheme.foreground)
                    .lineLimit(2)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(snapshot.isPlaying ? WidgetTheme.accent : WidgetTheme.muted)
                    .lineLimit(1)
            } else if entry.hasSharedData {
                Text("StationConnection")
                    .font(.headline)
                    .foregroundStyle(WidgetTheme.foreground)
                Text("Pon una emisora en la app")
                    .font(.caption)
                    .foregroundStyle(WidgetTheme.muted)
            } else {
                Text("StationConnection")
                    .font(.headline)
                    .foregroundStyle(WidgetTheme.foreground)
                    .lineLimit(1)
                DiagnosticText(entry.diagnostic)
                PlayStopButtons(size: 32)
            }
        }
        .containerBackground(for: .widget) { WidgetTheme.background }
    }

    // MARK: - Pantalla de bloqueo

    private var circular: some View {
        Button(intent: TogglePlaybackIntent()) {
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: entry.hasSharedData && snapshot.isPlaying ? "stop.fill" : "radio")
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
            if entry.hasSharedData {
                Button(intent: TogglePlaybackIntent()) {
                    Image(systemName: snapshot.isPlaying ? "stop.fill" : "play.fill")
                }
                .buttonStyle(.plain)
                .accessibilityLabel(snapshot.isPlaying ? "Detener la radio" : "Reproducir la radio")
            } else {
                VStack(spacing: 6) {
                    Button(intent: ResumePlaybackIntent()) { Image(systemName: "play.fill") }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Reproducir la radio")
                    Button(intent: StopPlaybackIntent()) { Image(systemName: "stop.fill") }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Detener la radio")
                }
            }
        }
        .containerBackground(for: .widget) { Color.clear }
    }
}
