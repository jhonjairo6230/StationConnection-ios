import Foundation
import Observation

/// Estado visible del reproductor.
enum PlayerStatus: Equatable {
    case idle
    case loading
    case playing
    case stopped
    case failed(String)
}

/// Estado y acciones del reproductor (patrón MVVM). Hay una sola instancia en
/// toda la app: la barra inferior, la pantalla "Reproduciendo", el Dial y
/// CarPlay muestran lo mismo.
///
/// - Habla con el audio a través de ``AudioPlayer`` y con la pantalla de
///   bloqueo / CarPlay a través de ``SystemMediaControls``; nunca con
///   AVFoundation ni MediaPlayer.
/// - **Cola:** al reproducir, recuerda la lista de donde salió la emisora
///   (``PlaybackQueue``). ⏮/⏭, los auriculares y el volante del auto se
///   mueven por ella.
/// - **Sonando ahora:** convierte los títulos de la emisora en ``Song`` y los
///   guarda en el historial.
/// - **Temporizador:** baja el volumen en los últimos segundos y detiene.
@MainActor
@Observable
final class PlayerViewModel {
    private(set) var station: Station?
    private(set) var status: PlayerStatus = .idle
    private(set) var nowPlaying: Song?
    private(set) var queue: [Station] = []
    /// Momento en que se apagará la radio, o `nil` sin temporizador.
    private(set) var sleepEndsAt: Date?
    /// Hora del último "tic" del temporizador (para la cuenta regresiva).
    private(set) var clockTick = Date()

    private let audio: AudioPlayer
    private let controls: SystemMediaControls
    private let library: LibraryViewModel
    private let registerPlay: RegisterPlayUseCase
    private let clock: () -> Date
    private let tickInterval: Duration

    @ObservationIgnored private var sleepTask: Task<Void, Never>?
    /// Emisora de la que ya se registró la reproducción (una vez por sesión de escucha).
    @ObservationIgnored private var registeredStationID: String?

    init(
        audio: AudioPlayer,
        controls: SystemMediaControls,
        library: LibraryViewModel,
        registerPlay: RegisterPlayUseCase,
        clock: @escaping () -> Date = Date.init,
        tickInterval: Duration = .milliseconds(500)
    ) {
        self.audio = audio
        self.controls = controls
        self.library = library
        self.registerPlay = registerPlay
        self.clock = clock
        self.tickInterval = tickInterval

        audio.onStateChange = { [weak self] state in self?.audioStateChanged(state) }
        audio.onMetadataTitle = { [weak self] title in self?.metadataChanged(title) }
        controls.onCommand = { [weak self] command in self?.handle(command) }
        library.onFavoritesChanged = { [weak self] favorites in self?.favoritesChanged(favorites) }
    }

    // MARK: - Consultas para la interfaz

    var isActive: Bool { status == .loading || status == .playing }

    var previousStation: Station? {
        PlaybackQueue.neighbor(in: queue, of: station?.id, direction: .previous)
    }

    var nextStation: Station? {
        PlaybackQueue.neighbor(in: queue, of: station?.id, direction: .next)
    }

    /// Segundos que faltan para que se apague, o `nil`.
    var sleepRemaining: TimeInterval? {
        sleepEndsAt.map { max(0, $0.timeIntervalSince(clockTick)) }
    }

    func isCurrent(_ station: Station) -> Bool { self.station?.id == station.id }
    func isPlaying(_ station: Station) -> Bool { isCurrent(station) && status == .playing }
    func isLoading(_ station: Station) -> Bool { isCurrent(station) && status == .loading }

    // MARK: - Acciones

    /// Reproduce `station`. `source` es la lista de donde se eligió (la cola de ⏮/⏭).
    func play(_ station: Station, from source: [Station]? = nil) {
        queue = PlaybackQueue.resolve(
            for: station,
            source: source,
            current: queue,
            favorites: library.favorites
        )
        start(station)
    }

    /// Botón ▶/■: en radio en vivo "pausar" es detener; al reanudar se vuelve al directo.
    func toggle(_ target: Station? = nil, from source: [Station]? = nil) {
        guard let target = target ?? station else { return }
        if isCurrent(target), isActive {
            stop()
        } else {
            play(target, from: source)
        }
    }

    func stop() {
        audio.stop()
        if station != nil { status = .stopped }
        cancelSleepTimer()
        updateSystemControls()
    }

    /// ⏮/⏭: se mueve por la cola sin cambiarla y siempre empieza a sonar.
    func skip(_ direction: SkipDirection) {
        guard let next = PlaybackQueue.neighbor(in: queue, of: station?.id, direction: direction) else { return }
        start(next)
    }

    /// Programa el apagado; `nil` lo cancela.
    func setSleepTimer(after duration: TimeInterval?) {
        cancelSleepTimer()
        guard let duration, isActive else { return }
        let endsAt = clock().addingTimeInterval(duration)
        sleepEndsAt = endsAt
        clockTick = clock()
        let interval = tickInterval
        sleepTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let now = self.clock()
                self.clockTick = now
                let remaining = endsAt.timeIntervalSince(now)
                self.audio.volume = SleepTimer.fadedVolume(base: 1, remaining: remaining)
                if remaining <= 0 {
                    self.stop()
                    return
                }
                try? await Task.sleep(for: interval)
            }
        }
    }

    // MARK: - Eventos

    private func start(_ station: Station) {
        self.station = station
        status = .loading
        nowPlaying = nil
        registeredStationID = nil
        audio.play(url: station.streamURL)
        updateSystemControls()
    }

    private func audioStateChanged(_ state: AudioPlayerState) {
        guard let station else { return }
        switch state {
        case .loading:
            if status != .stopped { status = .loading }
        case .playing:
            status = .playing
            if registeredStationID != station.id {
                registeredStationID = station.id
                library.addRecent(station)
                let register = registerPlay
                Task { await register.execute(station) }
            }
        case let .failed(message):
            status = .failed(message)
            cancelSleepTimer()
        }
        updateSystemControls()
    }

    private func metadataChanged(_ title: String) {
        guard let station, let song = Song.parse(title), song != nowPlaying else { return }
        nowPlaying = song
        library.recordSong(song, on: station)
        updateSystemControls()
    }

    private func handle(_ command: MediaCommand) {
        switch command {
        case .play:
            if let station, !isActive { start(station) }
        case .pause:
            if isActive { stop() }
        case .togglePlayPause:
            toggle()
        case .next:
            skip(.next)
        case .previous:
            skip(.previous)
        }
    }

    /// Si la cola son las favoritas y el usuario las reordena, ⏮/⏭ siguen el orden nuevo.
    private func favoritesChanged(_ favorites: [Station]) {
        guard queue != favorites, ListOperations.sameStations(queue, favorites) else { return }
        queue = favorites
        updateSystemControls()
    }

    private func cancelSleepTimer() {
        sleepTask?.cancel()
        sleepTask = nil
        sleepEndsAt = nil
        audio.volume = 1
    }

    private func updateSystemControls() {
        guard let station else {
            controls.update(nil, canSkip: false)
            return
        }
        controls.update(
            NowPlayingInfo(
                title: nowPlaying?.title ?? station.name,
                artist: nowPlaying.map { $0.artist ?? station.name } ?? station.subtitle,
                album: nowPlaying == nil ? "StationConnection" : station.name,
                artworkURL: station.favicon,
                isPlaying: status == .playing
            ),
            canSkip: queue.count > 1
        )
    }
}
