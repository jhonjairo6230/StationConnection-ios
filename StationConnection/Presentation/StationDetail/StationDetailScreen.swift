import SwiftUI

/// Pantalla de una emisora.
struct StationDetailScreen: View {
    @Environment(PlayerViewModel.self) private var player
    @State var viewModel: StationDetailViewModel

    var body: some View {
        let station = viewModel.station
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .bottom, spacing: 16) {
                    StationArtworkView(station: station, cornerRadius: 20)
                        .frame(width: 140)
                        .shadow(color: .black.opacity(0.4), radius: 16, y: 8)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            if player.isPlaying(station) { EqualizerView() }
                            Text(player.isPlaying(station) ? "SONANDO AHORA" : "ESTACIÓN DE RADIO")
                                .font(.caption.weight(.semibold))
                                .tracking(1.5)
                                .foregroundStyle(Theme.muted)
                        }
                        Text(station.name).font(.title.bold()).foregroundStyle(Theme.foreground)
                        if let location = station.location {
                            Text(location).foregroundStyle(Theme.muted)
                        }
                        if let details = station.technicalDetails {
                            Text(details).font(.footnote).foregroundStyle(Theme.muted)
                        }
                    }
                }
                .padding(.horizontal)

                HStack(spacing: 12) {
                    PlayButton(station: station, size: 56)
                    FavoriteButton(station: station, size: 22)
                    if let homepage = station.homepage {
                        Link(destination: homepage) {
                            Label("Sitio web", systemImage: "globe")
                                .font(.subheadline.weight(.medium))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .overlay(Capsule().stroke(Theme.border))
                        }
                        .foregroundStyle(Theme.foreground)
                    }
                }
                .padding(.horizontal)

                if player.isPlaying(station), let song = player.nowPlaying {
                    NowPlayingCard(song: song).padding(.horizontal)
                }

                if !station.tags.isEmpty {
                    FlowLayout(spacing: 8) {
                        ForEach(station.tags, id: \.self) { tag in
                            Text(tag.capitalized)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .foregroundStyle(Theme.muted)
                                .background(Capsule().fill(Theme.surface))
                        }
                    }
                    .padding(.horizontal)
                }

                if let tag = station.tags.first, viewModel.related.value?.isEmpty != true {
                    StationCarousel(title: "Más de \(tag)", state: viewModel.related) {
                        Task { await viewModel.onAppear() }
                    }
                }
            }
            .padding(.vertical)
        }
        .screenBackground()
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.onAppear() }
    }
}

/// Tarjeta "Sonando ahora" con los enlaces de búsqueda.
private struct NowPlayingCard: View {
    let song: Song

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Text("♪")
                    .font(.title2)
                    .foregroundStyle(Theme.accent)
                    .frame(width: 44, height: 44)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Theme.accent.opacity(0.15)))
                VStack(alignment: .leading, spacing: 2) {
                    Text("SONANDO AHORA").font(.caption.weight(.semibold)).tracking(1.5).foregroundStyle(Theme.muted)
                    Text(song.title).font(.headline).foregroundStyle(Theme.foreground)
                    if let artist = song.artist { Text(artist).foregroundStyle(Theme.muted) }
                }
            }
            SongLinksView(song: song)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.border))
    }
}
