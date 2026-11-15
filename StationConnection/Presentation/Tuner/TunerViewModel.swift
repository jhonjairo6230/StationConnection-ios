import Foundation
import Observation

/// Una banda del dial: las emisoras de un género o de un país.
enum TunerBand: Hashable {
    case tag(String)
    case country(code: String, name: String)

    var title: String {
        switch self {
        case let .tag(name): return name.capitalized
        case let .country(_, name): return name
        }
    }

    var query: StationQuery {
        switch self {
        case let .tag(name): return StationQuery(tag: name, order: .popular, limit: TunerViewModel.bandSize)
        case let .country(code, _): return StationQuery(countryCode: code, order: .popular, limit: TunerViewModel.bandSize)
        }
    }
}

/// El sintonizador retro: mover el dial, sintonizar y perder la señal.
///
/// - Quedarse quieto ``settleDelay`` sobre una emisora la pone a sonar, con la
///   banda como cola de ⏮/⏭.
/// - Alejarse de una emisora de la banda la detiene ("se pierde la señal").
/// - Si la emisora cambia desde fuera (⏮/⏭, el auto), la aguja la sigue
///   (``syncToPlayingStation()``).
@MainActor
@Observable
final class TunerViewModel {
    static let bandSize = 30

    private(set) var band: TunerBand = .tag("pop")
    private(set) var stations: [Station] = []
    private(set) var loadState: LoadState<Void> = .idle
    private(set) var tags: [Tag] = []
    private(set) var countries: [Country] = []
    private(set) var hasTouched = false
    private(set) var value: Double = 0

    private let search: SearchStationsUseCase
    private let getTags: GetTagsUseCase
    private let getCountries: GetCountriesUseCase
    private let player: PlayerViewModel
    private let noise: NoiseGenerator
    private let settleDelay: Duration

    @ObservationIgnored private var settleTask: Task<Void, Never>?
    @ObservationIgnored private var hasLoaded = false

    init(
        search: SearchStationsUseCase,
        getTags: GetTagsUseCase,
        getCountries: GetCountriesUseCase,
        player: PlayerViewModel,
        noise: NoiseGenerator,
        settleDelay: Duration = .milliseconds(350)
    ) {
        self.search = search
        self.getTags = getTags
        self.getCountries = getCountries
        self.player = player
        self.noise = noise
        self.settleDelay = settleDelay
    }

    // MARK: - Consultas

    var dialState: TunerDial.State? { TunerDial.tune(value, count: stations.count) }

    var lockedStation: Station? {
        guard let state = dialState, state.isLocked else { return nil }
        return stations[state.index]
    }

    var frequency: Double { TunerDial.frequency(at: value) }

    var isOnAir: Bool {
        guard let locked = lockedStation else { return false }
        return player.isPlaying(locked)
    }

    /// Texto de estado de la pantalla LCD.
    var statusText: String {
        if isOnAir { return "● EN EL AIRE" }
        if lockedStation != nil { return "SINTONIZANDO…" }
        return hasTouched ? "BUSCANDO…" : "GIRA EL DIAL"
    }

    // MARK: - Ciclo de vida

    func onAppear() async {
        if !hasLoaded {
            hasLoaded = true
            async let tags = try? getTags.execute()
            async let countries = try? getCountries.execute()
            await loadBand()
            self.tags = await tags ?? []
            self.countries = await countries ?? []
        }
        syncToPlayingStation()
    }

    func onDisappear() {
        settleTask?.cancel()
        noise.stop()
    }

    // MARK: - Acciones

    func select(_ band: TunerBand) async {
        guard band != self.band else { return }
        self.band = band
        value = 0
        await loadBand()
    }

    /// El usuario tocó el dial: arranca la estática (necesita un gesto).
    func touch() {
        guard !hasTouched else { return }
        hasTouched = true
        noise.start()
        updateNoise()
    }

    /// Mueve la aguja (arrastre, perilla, teclado).
    func move(to newValue: Double) {
        touch()
        value = min(max(newValue, 0), TunerDial.maxValue)
        dialMoved()
    }

    func seek(_ direction: SkipDirection) {
        guard let target = TunerDial.seek(from: value, count: stations.count, direction: direction) else { return }
        move(to: target)
    }

    /// Si suena una emisora de la banda que no es la sintonizada, mueve la aguja a ella.
    func syncToPlayingStation() {
        guard let playing = player.station,
              let index = stations.firstIndex(where: { $0.id == playing.id }),
              lockedStation?.id != playing.id
        else { updateNoise(); return }
        value = TunerDial.position(of: index, count: stations.count)
        updateNoise()
    }

    /// Recalcula el volumen de la estática (también cuando cambia el estado del reproductor).
    func updateNoise() {
        guard hasTouched else { return }
        let level: Double
        if let locked = lockedStation {
            level = player.isPlaying(locked) ? 0 : 0.12 // sintonizando: un poco de ruido
        } else {
            level = TunerDial.staticLevel(dialState)
        }
        noise.setLevel(level)
    }

    // MARK: - Privado

    private func dialMoved() {
        settleTask?.cancel()
        updateNoise()
        guard let locked = lockedStation else {
            // Se perdió la señal de una emisora de la banda.
            if let playing = player.station, player.isActive, stations.contains(where: { $0.id == playing.id }) {
                player.stop()
            }
            return
        }
        guard player.station?.id != locked.id || !player.isActive else { return }
        let band = stations
        let delay = settleDelay
        settleTask = Task { [weak self] in
            do { try await Task.sleep(for: delay) } catch { return }
            guard let self, self.lockedStation?.id == locked.id else { return }
            self.player.play(locked, from: band)
            self.updateNoise()
        }
    }

    private func loadBand() async {
        loadState = .loading
        do {
            stations = try await search.execute(band.query)
            loadState = .loaded(())
        } catch {
            stations = []
            loadState = .failed(error.userMessage)
        }
        syncToPlayingStation()
    }
}
