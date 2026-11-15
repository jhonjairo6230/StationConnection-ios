import AppIntents

/// "Oye Siri, pon mis favoritas en StationConnection".
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
struct StationShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: PlayFavoritesIntent(),
            phrases: [
                "Pon mis favoritas en \(.applicationName)",
                "Reproduce mis favoritas en \(.applicationName)",
                "Pon mis emisoras favoritas en \(.applicationName)",
                "Abre mis favoritas en \(.applicationName)",
            ],
            shortTitle: "Mis favoritas",
            systemImageName: "heart.fill"
        )
    }
}
