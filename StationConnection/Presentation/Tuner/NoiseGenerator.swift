import AVFoundation

/// Puerto: la estática de radio del dial. El ViewModel solo pide arrancar,
/// cambiar el volumen y parar.
@MainActor
protocol NoiseGenerator: AnyObject {
    func start()
    /// 0 = silencio, 1 = estática fuerte.
    func setLevel(_ level: Double)
    func stop()
}

/// Estática generada en tiempo real con `AVAudioEngine`: ruido blanco pasado
/// por un filtro de banda, que suena más a radio que el ruido puro.
@MainActor
final class StaticNoiseGenerator: NoiseGenerator {
    private let engine = AVAudioEngine()
    private let filter = AVAudioUnitEQ(numberOfBands: 1)
    private var source: AVAudioSourceNode?

    func start() {
        guard source == nil else {
            if !engine.isRunning { try? engine.start() }
            return
        }
        AudioSession.activate()

        let node = Self.makeWhiteNoiseNode()

        let band = filter.bands[0]
        band.filterType = .bandPass
        band.frequency = 1800
        band.bandwidth = 1.5
        band.bypass = false

        let format = AVAudioFormat(standardFormatWithSampleRate: engine.outputNode.outputFormat(forBus: 0).sampleRate, channels: 1)
        engine.attach(node)
        engine.attach(filter)
        engine.connect(node, to: filter, format: format)
        engine.connect(filter, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0
        source = node
        try? engine.start()
    }

    /// Nodo que genera ruido blanco. `nonisolated`: el bloque se ejecuta en el
    /// hilo de audio de tiempo real, nunca en el principal.
    private nonisolated static func makeWhiteNoiseNode() -> AVAudioSourceNode {
        let random = LinearCongruentialGenerator()
        return AVAudioSourceNode { _, _, frameCount, bufferList -> OSStatus in
            for buffer in UnsafeMutableAudioBufferListPointer(bufferList) {
                guard let samples = buffer.mData?.assumingMemoryBound(to: Float.self) else { continue }
                for frame in 0..<Int(frameCount) {
                    samples[frame] = random.next()
                }
            }
            return noErr
        }
    }

    func setLevel(_ level: Double) {
        // La estática pura es muy fuerte: se limita al 35 %.
        engine.mainMixerNode.outputVolume = Float(min(max(level, 0), 1)) * 0.35
    }

    func stop() {
        engine.mainMixerNode.outputVolume = 0
        engine.pause()
    }
}

/// Números pseudoaleatorios entre -1 y 1, baratos y sin reservar memoria:
/// aptos para el hilo de audio. Solo lo usa ese hilo.
private final class LinearCongruentialGenerator: @unchecked Sendable {
    private var seed: UInt32 = 22_222

    func next() -> Float {
        seed = seed &* 1_664_525 &+ 1_013_904_223
        return Float(seed) / Float(UInt32.max) * 2 - 1
    }
}
