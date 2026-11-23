import AppIntents
import SwiftUI
import WidgetKit

/// Widget "Favoritas" (mediano): lo que suena y cuatro favoritas que se ponen
/// a sonar con un toque.
struct FavoritesWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "Favorites", provider: SnapshotProvider()) { entry in
            FavoritesWidgetView(entry: entry)
        }
        .configurationDisplayName("Favoritas")
        .description("Tus primeras cuatro favoritas, a un toque.")
        .supportedFamilies([.systemMedium])
    }
}

struct FavoritesWidgetView: View {
    let entry: StationEntry

    var body: some View {
        HStack(spacing: 12) {
            nowPlaying
                .frame(maxWidth: .infinity, alignment: .leading)
            favorites
                .frame(maxWidth: .infinity)
        }
        .containerBackground(for: .widget) { WidgetTheme.background }
    }

    private var nowPlaying: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                if let item = entry.snapshot.current {
                    WidgetArtwork(item: item).frame(width: 40)
                } else {
                    AppArtworkImage(size: 40)
                }
                Spacer(minLength: 0)
                if entry.hasSharedData {
                    PlaybackToggleButton(isPlaying: entry.snapshot.isPlaying, size: 36)
                }
            }
            Spacer(minLength: 0)
            Text(entry.snapshot.current?.name ?? "StationConnection")
                .font(.headline)
                .foregroundStyle(WidgetTheme.foreground)
                .lineLimit(2)
            if let title = entry.snapshot.songTitle {
                Text(title).font(.caption).foregroundStyle(WidgetTheme.muted).lineLimit(1)
            }
            if !entry.hasSharedData {
                DiagnosticText(entry.diagnostic)
                PlayStopButtons(size: 30)
            }
        }
    }

    @ViewBuilder
    private var favorites: some View {
        let items = entry.snapshot.favorites
        if items.isEmpty {
            Text(entry.hasSharedData
                ? "Marca favoritas con ❤️ en la app"
                : "Sin acceso a tus favoritas. Añade el widget «Mis emisoras» y elígelas con Editar widget.")
                .font(.caption)
                .foregroundStyle(WidgetTheme.muted)
                .multilineTextAlignment(.center)
        } else {
            StationGrid(items: items, currentID: entry.snapshot.current?.id)
        }
    }
}
