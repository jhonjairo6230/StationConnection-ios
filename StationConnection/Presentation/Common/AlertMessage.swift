import Foundation

/// Mensaje que una vista muestra en una alerta.
struct AlertMessage: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String

    init(title: String, message: String) {
        self.title = title
        self.message = message
    }

    /// Convierte cualquier error en un mensaje legible.
    init(error: Error) {
        self.init(title: "Algo salió mal", message: error.userMessage)
    }

    /// Dos mensajes son iguales si dicen lo mismo (el `id` no cuenta).
    static func == (lhs: AlertMessage, rhs: AlertMessage) -> Bool {
        lhs.title == rhs.title && lhs.message == rhs.message
    }
}
