import Foundation
@testable import StationConnection

/// Reproductor falso: recuerda lo que se pidió y permite simular estados y títulos.
@MainActor
final class FakeAudioPlayer: AudioPlayer {
    var onStateChange: ((AudioPlayerState) -> Void)?
    var onMetadataTitle: ((String) -> Void)?
    var volume: Float = 1 { didSet { volumeHistory.append(volume) } }
    private(set) var playedURLs: [URL] = []
    private(set) var stopCount = 0
    /// Volúmenes aplicados (para comprobar el fundido del temporizador).
    private(set) var volumeHistory: [Float] = []

    func play(url: URL) {
        playedURLs.append(url)
        onStateChange?(.loading)
    }

    func stop() { stopCount += 1 }

    func simulate(_ state: AudioPlayerState) { onStateChange?(state) }
    func simulateTitle(_ title: String) { onMetadataTitle?(title) }
}

/// Controles del sistema falsos: guardan la última información y simulan órdenes.
@MainActor
final class FakeMediaControls: SystemMediaControls {
    var onCommand: ((MediaCommand) -> Void)?
    private(set) var lastInfo: NowPlayingInfo?
    private(set) var lastCanSkip = false

    func update(_ info: NowPlayingInfo?, canSkip: Bool) {
        lastInfo = info
        lastCanSkip = canSkip
    }

    func simulate(_ command: MediaCommand) { onCommand?(command) }
}

/// Estática falsa: recuerda el último nivel.
@MainActor
final class FakeNoiseGenerator: NoiseGenerator {
    private(set) var isRunning = false
    private(set) var level: Double = 0

    func start() { isRunning = true }
    func setLevel(_ level: Double) { self.level = level }
    func stop() { isRunning = false }
}
