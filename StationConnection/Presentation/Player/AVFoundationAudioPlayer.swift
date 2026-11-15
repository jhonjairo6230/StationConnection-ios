import AVFoundation

/// Adaptador de ``AudioPlayer`` con `AVPlayer`.
///
/// - Reproduce MP3, AAC y HLS (las listas `.m3u8` son nativas en iOS).
/// - Configura la sesión de audio como `.playback`: sigue sonando con la
///   pantalla bloqueada (requiere `UIBackgroundModes: audio` en project.yml) y
///   permite AirPlay.
/// - Lee los metadatos de la canción con `AVPlayerItemMetadataOutput`: los
///   títulos ICY (`StreamTitle`) llegan como `.icyMetadataStreamTitle`, sin
///   necesidad de un servidor como en la versión web.
@MainActor
final class AVFoundationAudioPlayer: NSObject, AudioPlayer {
    var onStateChange: ((AudioPlayerState) -> Void)?
    var onMetadataTitle: ((String) -> Void)?

    var volume: Float {
        get { player.volume }
        set { player.volume = newValue }
    }

    private let player = AVPlayer()
    private var timeControlObservation: NSKeyValueObservation?
    private var itemStatusObservation: NSKeyValueObservation?
    private var metadataOutput: AVPlayerItemMetadataOutput?

    override init() {
        super.init()
        timeControlObservation = player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            let status = player.timeControlStatus
            Task { @MainActor in self?.timeControlStatusChanged(status) }
        }
    }

    func play(url: URL) {
        AudioSession.activate()
        let item = AVPlayerItem(url: url)

        let output = AVPlayerItemMetadataOutput(identifiers: nil)
        output.setDelegate(self, queue: .main)
        item.add(output)
        metadataOutput = output

        itemStatusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard item.status == .failed else { return }
            Task { @MainActor in self?.onStateChange?(.failed(StationError.playbackFailed.userMessage)) }
        }

        player.replaceCurrentItem(with: item)
        onStateChange?(.loading)
        player.play()
    }

    func stop() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        itemStatusObservation = nil
        metadataOutput = nil
    }

    private func timeControlStatusChanged(_ status: AVPlayer.TimeControlStatus) {
        guard player.currentItem != nil else { return } // detenido a propósito
        switch status {
        case .playing: onStateChange?(.playing)
        case .waitingToPlayAtSpecifiedRate: onStateChange?(.loading)
        case .paused: break
        @unknown default: break
        }
    }
}

extension AVFoundationAudioPlayer: AVPlayerItemMetadataOutputPushDelegate {
    nonisolated func metadataOutput(
        _ output: AVPlayerItemMetadataOutput,
        didOutputTimedMetadataGroups groups: [AVTimedMetadataGroup],
        from track: AVPlayerItemTrack?
    ) {
        let items = groups.flatMap(\.items)
        // ICY (Shoutcast/Icecast) o, en HLS, el título común.
        guard let item = items.first(where: { $0.identifier == .icyMetadataStreamTitle })
            ?? items.first(where: { $0.commonKey == .commonKeyTitle })
        else { return }
        Task { @MainActor [weak self] in
            guard let title = try? await item.load(.stringValue) else { return }
            self?.onMetadataTitle?(title)
        }
    }
}

/// Configuración compartida de la sesión de audio (radio y estática del dial).
enum AudioSession {
    static func activate() {
        let session = AVAudioSession.sharedInstance()
        // `.longFormAudio`: iOS la trata como música/podcast (AirPlay 2, CarPlay).
        try? session.setCategory(.playback, mode: .default, policy: .longFormAudio, options: [])
        try? session.setActive(true)
    }
}
