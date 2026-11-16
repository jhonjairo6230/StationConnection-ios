import SwiftUI

/// Botones para buscar una canción en YouTube Music, YouTube y Spotify.
struct SongLinksView: View {
    let song: Song

    var body: some View {
        let links = MusicSearchLinks(song: song)
        HStack(spacing: 8) {
            chip("YouTube Music", links.youtubeMusic)
            chip("YouTube", links.youtube)
            chip("Spotify", links.spotify)
        }
    }

    private func chip(_ title: String, _ url: URL) -> some View {
        Link(destination: url) {
            Text(title)
                .font(.caption.weight(.medium))
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .foregroundStyle(Theme.muted)
                .overlay(Capsule().stroke(Theme.border))
        }
    }
}
