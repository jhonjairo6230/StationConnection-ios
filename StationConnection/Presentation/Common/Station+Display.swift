import Foundation

/// Textos de una emisora para la interfaz.
extension Station {
    /// "Colombia · pop", o "Radio en línea" si no hay datos.
    var subtitle: String {
        let parts = [country, tags.first].compactMap { $0 }
        return parts.isEmpty ? "Radio en línea" : parts.joined(separator: " · ")
    }

    /// "Antioquia, Colombia".
    var location: String? {
        let parts = [state, country].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    /// "MP3 · 128 kbps · spanish · HLS".
    var technicalDetails: String? {
        var parts: [String] = []
        if let codec, codec.uppercased() != "UNKNOWN" { parts.append(codec) }
        if bitrate > 0 { parts.append("\(bitrate) kbps") }
        if let language { parts.append(language) }
        if isHLS { parts.append("HLS") }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// Iniciales para la carátula sin logo ("La Mega" → "LM").
    var initials: String { StationArtworkText.initials(for: name) }

    /// Índice estable del degradado según el id.
    var gradientIndex: Int { StationArtworkText.gradientIndex(for: id) }
}
