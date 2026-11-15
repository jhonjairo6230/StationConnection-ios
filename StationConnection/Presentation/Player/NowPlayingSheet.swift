import SwiftUI

/// Pantalla completa "Reproduciendo": botones grandes, cómodos en el auto.
struct NowPlayingSheet: View {
    @Environment(PlayerViewModel.self) private var player
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            if let station = player.station {
                ScrollView {
                    VStack(spacing: 24) {
                        StationArtworkView(station: station, cornerRadius: 24)
                            .frame(maxWidth: 320)
                            .shadow(color: .black.opacity(0.5), radius: 24, y: 10)
                            .padding(.top, 8)

                        VStack(spacing: 6) {
                            Text(station.name)
                                .font(.title.bold())
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Theme.foreground)
                            PlayerStatusLine(station: station)
                            if let song = player.nowPlaying {
                                VStack(spacing: 4) {
                                    Text(song.title).font(.headline).foregroundStyle(Theme.foreground)
                                    if let artist = song.artist {
                                        Text(artist).font(.subheadline).foregroundStyle(Theme.muted)
                                    }
                                }
                                .multilineTextAlignment(.center)
                                .padding(.top, 8)
                                SongLinksView(song: song)
                            }
                        }

                        transportControls

                        HStack(spacing: 28) {
                            FavoriteButton(station: station, size: 22)
                            AirPlayButton().frame(width: 44, height: 44)
                            SleepTimerMenu()
                            ShareLink(item: shareText(station)) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Theme.muted)
                                    .frame(width: 44, height: 44)
                            }
                            .accessibilityLabel("Compartir \(station.name)")
                        }

                        if player.queue.count > 1 {
                            Text("⏮ ⏭ recorren: \(player.queue.count) emisoras de esta lista")
                                .font(.footnote)
                                .foregroundStyle(Theme.muted)
                        }
                    }
                    .padding()
                }
                .screenBackground()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cerrar") { dismiss() }
                    }
                }
            } else {
                EmptyState(title: "Nada sonando", message: "Elige una emisora para empezar.").padding()
            }
        }
    }

    private var transportControls: some View {
        HStack(spacing: 36) {
            skipButton(.previous)
            if let station = player.station {
                PlayButton(station: station, size: 76)
            }
            skipButton(.next)
        }
    }

    private func skipButton(_ direction: SkipDirection) -> some View {
        let target = direction == .next ? player.nextStation : player.previousStation
        let label = direction == .next ? "Emisora siguiente" : "Emisora anterior"
        return Button { player.skip(direction) } label: {
            Image(systemName: direction == .next ? "forward.end.fill" : "backward.end.fill")
                .font(.system(size: 30))
                .frame(width: 60, height: 60)
        }
        .buttonStyle(.plain)
        .foregroundStyle(target == nil ? Theme.muted.opacity(0.4) : Theme.foreground)
        .disabled(target == nil)
        .accessibilityLabel(target.map { "\(label): \($0.name)" } ?? label)
    }

    private func shareText(_ station: Station) -> String {
        var text = "Escucha \(station.name) en StationConnection 📻"
        if let homepage = station.homepage { text += "\n\(homepage.absoluteString)" }
        return text
    }
}
