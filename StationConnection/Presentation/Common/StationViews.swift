import SwiftUI

/// Fila de una emisora para listas (resultados, favoritas).
struct StationRow: View {
    @Environment(PlayerViewModel.self) private var player
    let station: Station
    var index: Int?

    var body: some View {
        HStack(spacing: 12) {
            if let index {
                Group {
                    if player.isPlaying(station) {
                        EqualizerView()
                    } else {
                        Text("\(index + 1)").monospacedDigit()
                    }
                }
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
                .frame(width: 24)
            }
            NavigationLink(value: station) {
                HStack(spacing: 12) {
                    StationArtworkView(station: station, cornerRadius: 8)
                        .frame(width: 48)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(station.name)
                            .font(.body.weight(.medium))
                            .foregroundStyle(player.isCurrent(station) ? Theme.accent : Theme.foreground)
                            .lineLimit(1)
                        Text(station.bitrate > 0 ? "\(station.subtitle) · \(station.bitrate) kbps" : station.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(Theme.muted)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            FavoriteButton(station: station)
            PlayButton(station: station, size: 36)
        }
        .padding(.vertical, 4)
    }
}

/// Tarjeta vertical para carruseles.
struct StationCard: View {
    @Environment(PlayerViewModel.self) private var player
    let station: Station

    var body: some View {
        NavigationLink(value: station) {
            VStack(alignment: .leading, spacing: 8) {
                StationArtworkView(station: station)
                    .overlay(alignment: .bottomTrailing) {
                        PlayButton(station: station, size: 36).padding(6)
                    }
                HStack(spacing: 6) {
                    if player.isPlaying(station) { EqualizerView() }
                    Text(station.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.foreground)
                        .lineLimit(1)
                }
                Text(station.subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
                    .lineLimit(1)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(player.isCurrent(station) ? Theme.surface2 : Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(player.isCurrent(station) ? Theme.accent.opacity(0.5) : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .frame(width: 160)
    }
}

/// Carrusel horizontal con su título. Publica la lista como cola de ⏮/⏭.
struct StationCarousel: View {
    let title: String
    let state: LoadState<[Station]>
    var onRetry: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: title)
            switch state {
            case let .loaded(stations) where !stations.isEmpty:
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(stations) { StationCard(station: $0) }
                    }
                    .padding(.horizontal)
                }
                .stationQueue(stations)
            case .loaded:
                EmptyState(title: "Sin emisoras", message: "No hay nada que mostrar aquí.")
                    .padding(.horizontal)
            case let .failed(message):
                ErrorState(message: message, onRetry: onRetry)
                    .padding(.horizontal)
            case .idle, .loading:
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<5, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 16).fill(Theme.surface).frame(width: 160, height: 210)
                        }
                    }
                    .padding(.horizontal)
                }
                .redacted(reason: .placeholder)
                .accessibilityLabel("Cargando")
            }
        }
    }
}

/// Título de sección.
struct SectionHeader: View {
    let title: String
    var trailing: AnyView?

    var body: some View {
        HStack {
            Text(title).font(.title3.bold()).foregroundStyle(Theme.foreground)
            Spacer()
            trailing
        }
        .padding(.horizontal)
    }
}

/// Mensaje de error con botón para reintentar.
struct ErrorState: View {
    let message: String
    var onRetry: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(message).font(.subheadline).foregroundStyle(Theme.muted)
            if let onRetry {
                Button("Reintentar", action: onRetry)
                    .buttonStyle(.bordered)
                    .tint(Theme.foreground)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.surface))
    }
}

/// Estado vacío con título y explicación.
struct EmptyState: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 6) {
            Text(title).font(.headline).foregroundStyle(Theme.foreground)
            Text(message).font(.subheadline).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Theme.border, style: StrokeStyle(lineWidth: 1, dash: [5]))
        )
    }
}
