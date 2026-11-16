import Foundation

/// Matemática del sintonizador retro: el dial va de 0 a ``maxValue`` y las N
/// emisoras de la banda se reparten a lo ancho, cada una en el centro de su
/// "carril".
enum TunerDial {
    static let maxValue = 1000.0
    static let fmMin = 88.0
    static let fmMax = 108.0
    /// Fracción del carril alrededor de cada emisora donde se considera sintonizada.
    static let lockRatio = 0.3

    /// Dónde está la emisora más cercana y si está sintonizada.
    struct State: Equatable {
        let index: Int
        /// 0 = justo encima; 1 = a mitad de camino hacia la siguiente.
        let offset: Double
        let isLocked: Bool
    }

    static func position(of index: Int, count: Int) -> Double {
        (Double(index) + 0.5) / Double(count) * maxValue
    }

    static func tune(_ value: Double, count: Int) -> State? {
        guard count > 0 else { return nil }
        let lane = maxValue / Double(count)
        let clamped = min(max(value, 0), maxValue)
        let index = min(count - 1, max(0, Int((clamped / lane - 0.5).rounded())))
        let offset = min(1, abs(clamped - position(of: index, count: count)) / (lane / 2))
        return State(index: index, offset: offset, isLocked: offset <= lockRatio)
    }

    /// Frecuencia ficticia (MHz, un decimal) para la pantalla.
    static func frequency(at value: Double) -> Double {
        let mhz = fmMin + min(max(value, 0), maxValue) / maxValue * (fmMax - fmMin)
        return (mhz * 10).rounded() / 10
    }

    /// Volumen de la estática (0–1): silencio al sintonizar, más fuerte cuanto más lejos.
    static func staticLevel(_ state: State?) -> Double {
        guard let state else { return 1 }
        if state.isLocked { return 0 }
        return min(1, (state.offset - lockRatio) / (1 - lockRatio) + 0.25)
    }

    /// Posición de la emisora siguiente o anterior a `value`, dando la vuelta.
    static func seek(from value: Double, count: Int, direction: SkipDirection) -> Double? {
        guard count > 0 else { return nil }
        let positions = (0..<count).map { position(of: $0, count: count) }
        switch direction {
        case .next: return positions.first { $0 > value + 1 } ?? positions.first
        case .previous: return positions.last { $0 < value - 1 } ?? positions.last
        }
    }
}
