import Foundation

/// Reglas del temporizador para dormir.
enum SleepTimer {
    /// Duraciones del menú, en minutos.
    static let options = [15, 30, 45, 60, 90]
    /// Segundos finales en los que el volumen baja hasta cero.
    static let fadeDuration: TimeInterval = 30

    /// Volumen a aplicar cuando faltan `remaining` segundos.
    static func fadedVolume(base: Float, remaining: TimeInterval, fade: TimeInterval = fadeDuration) -> Float {
        if remaining >= fade { return base }
        if remaining <= 0 { return 0 }
        return base * Float(remaining / fade)
    }

    /// 1:05:09 · 23:04 · 0:09
    static func format(remaining: TimeInterval) -> String {
        let total = max(0, Int(remaining.rounded(.up)))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, seconds)
            : String(format: "%d:%02d", minutes, seconds)
    }

    /// "15 minutos", "1 hora", "1.5 horas".
    static func label(minutes: Int) -> String {
        if minutes < 60 { return "\(minutes) minutos" }
        if minutes == 60 { return "1 hora" }
        let hours = Double(minutes) / 60
        return hours == hours.rounded() ? "\(Int(hours)) horas" : String(format: "%.1f horas", hours)
    }
}
