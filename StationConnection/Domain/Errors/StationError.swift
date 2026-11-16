import Foundation

/// Errores de negocio que la interfaz sabe mostrar al usuario.
///
/// Las capas externas traducen sus errores técnicos (`URLError`, `FileManager`,
/// `AVPlayer`…) a estos casos, para que la presentación nunca dependa de ellos.
enum StationError: Error, Equatable {
    /// El directorio de radios no respondió (sin red o servidores caídos).
    case directoryUnavailable
    /// No se pudieron leer o guardar los datos locales (favoritas, historial).
    case storageFailed
    /// El archivo de respaldo no es válido.
    case invalidBackup
    /// La emisora no se pudo reproducir.
    case playbackFailed
}

extension StationError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .directoryUnavailable:
            return "No se pudo contactar el directorio de radios. Revisa tu conexión e inténtalo de nuevo."
        case .storageFailed:
            return "No se pudieron guardar o leer tus datos en el dispositivo."
        case .invalidBackup:
            return "El archivo no parece un respaldo de StationConnection."
        case .playbackFailed:
            return "No se pudo reproducir esta emisora."
        }
    }
}
