import MediaPlayer
import UIKit

/// Adaptador de ``SystemMediaControls`` con el framework MediaPlayer.
///
/// - `MPNowPlayingInfoCenter`: título, artista y carátula en la pantalla de
///   bloqueo, el Centro de control, el reloj y "Reproduciendo" de **CarPlay**.
/// - `MPRemoteCommandCenter`: los botones de esos lugares, de los auriculares
///   y del **volante del auto** (⏮/⏭ cambian de emisora).
///
/// Si la emisora no tiene logo, la carátula es el ícono de la app (`AppArtwork`).
@MainActor
final class MediaPlayerControls: SystemMediaControls {
    var onCommand: ((MediaCommand) -> Void)?

    private let commandCenter = MPRemoteCommandCenter.shared()
    private var lastInfo: NowPlayingInfo?
    private var lastCanSkip = false
    private var artworkCache: [URL: UIImage] = [:]
    private var artworkTask: Task<Void, Never>?
    private lazy var appArtwork = UIImage(named: "AppArtwork")

    init() {
        register(commandCenter.playCommand, .play)
        register(commandCenter.pauseCommand, .pause)
        register(commandCenter.stopCommand, .pause)
        register(commandCenter.togglePlayPauseCommand, .togglePlayPause)
        register(commandCenter.nextTrackCommand, .next)
        register(commandCenter.previousTrackCommand, .previous)
        // En radio en vivo no hay adelantar/retroceder 15 s.
        commandCenter.skipForwardCommand.isEnabled = false
        commandCenter.skipBackwardCommand.isEnabled = false
        commandCenter.changePlaybackPositionCommand.isEnabled = false
    }

    func update(_ info: NowPlayingInfo?, canSkip: Bool) {
        lastInfo = info
        lastCanSkip = canSkip
        commandCenter.nextTrackCommand.isEnabled = canSkip
        commandCenter.previousTrackCommand.isEnabled = canSkip

        guard let info else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }

        var values: [String: Any] = [
            MPMediaItemPropertyTitle: info.title,
            MPMediaItemPropertyArtist: info.artist,
            MPMediaItemPropertyAlbumTitle: info.album,
            MPNowPlayingInfoPropertyIsLiveStream: true,
            MPNowPlayingInfoPropertyPlaybackRate: info.isPlaying ? 1.0 : 0.0,
        ]
        let image = info.artworkURL.flatMap { artworkCache[$0] } ?? appArtwork
        if let image { values[MPMediaItemPropertyArtwork] = Self.artwork(for: image) }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = values

        if let url = info.artworkURL, artworkCache[url] == nil { downloadArtwork(url) }
    }

    // MARK: - Privado

    private func register(_ command: MPRemoteCommand, _ action: MediaCommand) {
        command.isEnabled = true
        command.addTarget { [weak self] _ in
            Task { @MainActor in self?.onCommand?(action) }
            return .success
        }
    }

    private func downloadArtwork(_ url: URL) {
        artworkTask?.cancel()
        artworkTask = Task { [weak self] in
            guard let response = try? await URLSession.shared.data(from: url),
                  let image = UIImage(data: response.0), !Task.isCancelled, let self
            else { return }
            self.artworkCache[url] = image
            // Si sigue siendo la misma emisora, se vuelve a pintar con su logo.
            if self.lastInfo?.artworkURL == url { self.update(self.lastInfo, canSkip: self.lastCanSkip) }
        }
    }

    /// `nonisolated`: el sistema pide la imagen desde otro hilo.
    private nonisolated static func artwork(for image: UIImage) -> MPMediaItemArtwork {
        MPMediaItemArtwork(boundsSize: image.size) { _ in image }
    }
}
