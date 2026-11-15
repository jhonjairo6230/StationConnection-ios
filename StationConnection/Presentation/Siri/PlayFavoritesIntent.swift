import AppIntents

/// "Oye Siri, mis favoritas de StationConnection".
///
/// Es un `AudioPlaybackIntent`: suena sin abrir la app en pantalla, también
/// desde CarPlay. Empieza por la primera favorita y ⏮/⏭ recorren las demás.
/// No necesita permisos especiales, así que funciona con la firma gratuita.
/// Ver docs/adr/0011-siri-favoritas.md
struct PlayFavoritesIntent: AudioPlaybackIntent {
    static let title: LocalizedStringResource = "Reproducir mis favoritas"
    static let description = IntentDescription("Pone a sonar tus emisoras favoritas en orden.")

    init() {}

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let started = await WidgetPlaybackBridge.playFavorites()
        let dialog: IntentDialog = started
            ? "Poniendo tus favoritas."
            : "Todavía no tienes favoritas. Márcalas con el corazón en la app."
        return .result(dialog: dialog)
    }
}

/// Frases de Siri y Atajos. Cada frase debe nombrar la app.
///
/// No empiezan por "Pon/Reproduce … en StationConnection": esa forma la
/// reserva iOS para su búsqueda de música (SiriKit, que pide un permiso que
/// la firma gratuita no tiene) y responde "No pude encontrar una lista…".
/// Ver docs/adr/0012-frases-de-siri.md
struct StationShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: PlayFavoritesIntent(),
            phrases: [
                "Mis favoritas de \(.applicationName)",
                "Mis favoritas en \(.applicationName)",
                "\(.applicationName) mis favoritas",
                "Favoritas de \(.applicationName)",
                "Radio favorita de \(.applicationName)",
            ],
            shortTitle: "Mis favoritas",
            systemImageName: "heart.fill"
        )
    }
}
