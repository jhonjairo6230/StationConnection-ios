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
            HStack {
                if let item = entry.snapshot.current {
                    WidgetArtwork(item: item).frame(width: 40)
                } else {
                    Image("AppArtwork").resizable().scaledToFit().frame(width: 40).clipShape(RoundedRectangle(cornerRadius: 10))
                }
                Spacer()
                ToggleButton(isPlaying: entry.snapshot.isPlaying, size: 36)
            }
            Spacer(minLength: 0)
            Text(entry.snapshot.current?.name ?? "StationConnection")
                .font(.headline)
                .foregroundStyle(WidgetTheme.foreground)
                .lineLimit(2)
            if let title = entry.snapshot.songTitle {
                Text(title).font(.caption).foregroundStyle(WidgetTheme.muted).lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private var favorites: some View {
        let items = entry.snapshot.favorites
        if items.isEmpty {
            Text(entry.hasSharedData ? "Marca favoritas con ❤️ en la app" : "Abre la app para ver tus favoritas")
                .font(.caption)
                .foregroundStyle(WidgetTheme.muted)
                .multilineTextAlignment(.center)
        } else {
            Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                GridRow {
                    tile(at: 0, in: items)
                    tile(at: 1, in: items)
                }
                GridRow {
                    tile(at: 2, in: items)
                    tile(at: 3, in: items)
                }
            }
        }
    }

    @ViewBuilder
    private func tile(at index: Int, in items: [WidgetSnapshot.Item]) -> some View {
        if items.indices.contains(index) {
            let item = items[index]
            Button(intent: PlayStationIntent(stationID: item.id)) {
                VStack(spacing: 2) {
                    WidgetArtwork(item: item, cornerRadius: 8).frame(width: 38)
                    Text(item.name)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(entry.snapshot.current?.id == item.id ? WidgetTheme.accent : WidgetTheme.foreground)
                        .lineLimit(1)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Reproducir \(item.name)")
        } else {
            Color.clear.frame(width: 38, height: 50)
        }
    }
}
