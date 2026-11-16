import SwiftUI

/// Barra del reproductor sobre las pestañas. Tocarla abre "Reproduciendo".
struct MiniPlayerBar: View {
    @Environment(PlayerViewModel.self) private var player
    let onOpen: () -> Void

    var body: some View {
        if let station = player.station {
            HStack(spacing: 10) {
                Button(action: onOpen) {
                    HStack(spacing: 10) {
                        StationArtworkView(station: station, cornerRadius: 8).frame(width: 44)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(station.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.foreground)
                                .lineLimit(1)
                            PlayerStatusLine(station: station)
                        }
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Abrir reproductor, \(station.name)")
                .accessibilityIdentifier("miniPlayer")

                PlayButton(station: station, size: 40)
                Button { player.skip(.next) } label: {
                    Image(systemName: "forward.end.fill")
                        .font(.title3)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
                .foregroundStyle(player.nextStation == nil ? Theme.muted.opacity(0.4) : Theme.foreground)
                .disabled(player.nextStation == nil)
                .accessibilityLabel(player.nextStation.map { "Emisora siguiente: \($0.name)" } ?? "Emisora siguiente")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .background(Theme.surface.opacity(0.85))
            .overlay(alignment: .top) { Divider().overlay(Theme.border) }
        }
    }
}

/// "EN VIVO · ♪ Artista – Canción" (o el estado / el error).
struct PlayerStatusLine: View {
    @Environment(PlayerViewModel.self) private var player
    let station: Station

    var body: some View {
        HStack(spacing: 6) {
            switch player.status {
            case .playing:
                EqualizerView()
                if let song = player.nowPlaying {
                    Text("♪ " + (song.artist.map { "\($0) – " } ?? "") + song.title)
                } else {
                    Text("EN VIVO").fontWeight(.semibold).foregroundStyle(Theme.accent)
                    Text(station.subtitle)
                }
            case .loading:
                Text("Conectando…")
            case .stopped, .idle:
                Text("Detenida")
            case let .failed(message):
                Text(message).foregroundStyle(.red)
            }
        }
        .font(.caption)
        .foregroundStyle(Theme.muted)
        .lineLimit(1)
    }
}
