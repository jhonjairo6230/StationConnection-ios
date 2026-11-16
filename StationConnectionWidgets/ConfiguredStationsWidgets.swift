import AppIntents
import SwiftUI
import WidgetKit

/// Una "foto" de un widget configurable: las emisoras que eligió el usuario.
struct ConfiguredEntry: TimelineEntry {
    let date: Date
    let items: [WidgetSnapshot.Item]
}

/// Widget pequeño "Mi emisora": la emisora elegida con ▶ y ■.
///
/// Funciona **sin App Group** (firma gratuita): la emisora la elige el usuario
/// en "Editar widget" y la busca la propia extensión. Al ser `systemSmall`,
/// aparece también en **CarPlay** (iOS 26+).
/// Ver docs/adr/0013-widgets-configurables.md
struct OneStationWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "OneStation", intent: OneStationIntent.self, provider: OneStationProvider()) { entry in
            OneStationWidgetView(entry: entry)
        }
        .configurationDisplayName("Mi emisora")
        .description("Elige una emisora para ponerla con un toque, también en CarPlay. Mantén pulsado → Editar widget.")
        .supportedFamilies([.systemSmall])
    }
}

/// Widget mediano "Mis emisoras": hasta cuatro emisoras elegidas y ■.
struct FourStationsWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "FourStations", intent: FourStationsIntent.self, provider: FourStationsProvider()) { entry in
            FourStationsWidgetView(entry: entry)
        }
        .configurationDisplayName("Mis emisoras")
        .description("Elige hasta cuatro emisoras. Mantén pulsado → Editar widget.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Proveedores

/// Las emisoras ya vienen en la configuración: no hace falta red para pintar.
struct OneStationProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> ConfiguredEntry {
        ConfiguredEntry(date: Date(), items: Array(StationEntry.preview.snapshot.favorites.prefix(1)))
    }

    func snapshot(for configuration: OneStationIntent, in context: Context) async -> ConfiguredEntry {
        let items = configuration.station.map { [$0.item] } ?? []
        return context.isPreview && items.isEmpty ? placeholder(in: context) : ConfiguredEntry(date: Date(), items: items)
    }

    func timeline(for configuration: OneStationIntent, in context: Context) async -> Timeline<ConfiguredEntry> {
        Timeline(entries: [ConfiguredEntry(date: Date(), items: configuration.station.map { [$0.item] } ?? [])], policy: .never)
    }
}

struct FourStationsProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> ConfiguredEntry {
        ConfiguredEntry(date: Date(), items: StationEntry.preview.snapshot.favorites)
    }

    func snapshot(for configuration: FourStationsIntent, in context: Context) async -> ConfiguredEntry {
        let items = configuration.stations.map(\.item)
        return context.isPreview && items.isEmpty ? placeholder(in: context) : ConfiguredEntry(date: Date(), items: items)
    }

    func timeline(for configuration: FourStationsIntent, in context: Context) async -> Timeline<ConfiguredEntry> {
        Timeline(entries: [ConfiguredEntry(date: Date(), items: configuration.stations.map(\.item))], policy: .never)
    }
}

// MARK: - Vistas

struct OneStationWidgetView: View {
    let entry: ConfiguredEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let item = entry.items.first {
                Button(intent: PlayStationIntent(stationID: item.id)) {
                    VStack(alignment: .leading, spacing: 6) {
                        WidgetArtwork(item: item).frame(width: 52)
                        Text(item.name)
                            .font(.headline)
                            .foregroundStyle(WidgetTheme.foreground)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Reproducir \(item.name)")
                Spacer(minLength: 0)
                HStack(spacing: 8) {
                    Button(intent: PlayStationIntent(stationID: item.id)) {
                        RoundIcon(symbol: "play.fill", size: 34, filled: true)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Reproducir \(item.name)")
                    StopButton()
                }
            } else {
                Image("AppArtwork").resizable().scaledToFit().frame(width: 40).clipShape(RoundedRectangle(cornerRadius: 10))
                Spacer(minLength: 0)
                Text("Elige una emisora")
                    .font(.headline)
                    .foregroundStyle(WidgetTheme.foreground)
                Text("Mantén pulsado → Editar widget")
                    .font(.caption)
                    .foregroundStyle(WidgetTheme.muted)
            }
        }
        .containerBackground(for: .widget) { WidgetTheme.background }
    }
}

struct FourStationsWidgetView: View {
    let entry: ConfiguredEntry

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Image("AppArtwork").resizable().scaledToFit().frame(width: 36).clipShape(RoundedRectangle(cornerRadius: 9))
                Spacer(minLength: 0)
                Text("Mis emisoras")
                    .font(.headline)
                    .foregroundStyle(WidgetTheme.foreground)
                StopButton(size: 32)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Group {
                if entry.items.isEmpty {
                    Text("Mantén pulsado → Editar widget para elegir emisoras")
                        .font(.caption)
                        .foregroundStyle(WidgetTheme.muted)
                        .multilineTextAlignment(.center)
                } else {
                    StationGrid(items: entry.items)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .containerBackground(for: .widget) { WidgetTheme.background }
    }
}
