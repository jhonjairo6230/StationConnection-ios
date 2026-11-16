import Foundation

/// Lo que el reproductor de audio le cuenta al ViewModel.
enum AudioPlayerState: Equatable {
    case loading
    case playing
    case failed(String)
}

/// Puerto: lo que ``PlayerViewModel`` necesita de un reproductor de audio.
///
/// El ViewModel nunca toca AVFoundation: habla con este protocolo. La
/// implementación real es ``AVFoundationAudioPlayer``; en las pruebas se usa
/// un doble que simula estados y metadatos.
@MainActor
protocol AudioPlayer: AnyObject {
    /// Cambios de estado (conectando, sonando, error).
    var onStateChange: ((AudioPlayerState) -> Void)? { get set }
    /// Título que envía la emisora (ICY `StreamTitle` o título HLS).
    var onMetadataTitle: ((String) -> Void)? { get set }
    /// Volumen propio de la app (0–1); lo usa el fundido del temporizador.
    var volume: Float { get set }

    func play(url: URL)
    func stop()
}

/// Órdenes que llegan del sistema: pantalla de bloqueo, auriculares, CarPlay,
/// volante del auto, Centro de control.
enum MediaCommand: Equatable {
    case play
    case pause
    case togglePlayPause
    case next
    case previous
}

/// Lo que se muestra en "Reproduciendo" (pantalla de bloqueo, CarPlay).
struct NowPlayingInfo: Equatable {
    let title: String
    let artist: String
    let album: String
    let artworkURL: URL?
    let isPlaying: Bool
}

/// Puerto: controles y pantalla "Reproduciendo" del sistema.
///
/// La implementación real es ``MediaPlayerControls`` (framework MediaPlayer).
@MainActor
protocol SystemMediaControls: AnyObject {
    var onCommand: ((MediaCommand) -> Void)? { get set }
    /// `nil` borra la información (no hay nada sonando).
    func update(_ info: NowPlayingInfo?, canSkip: Bool)
}
