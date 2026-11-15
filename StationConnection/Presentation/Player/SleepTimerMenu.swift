import SwiftUI

/// Menú del temporizador para dormir, con la cuenta regresiva.
struct SleepTimerMenu: View {
    @Environment(PlayerViewModel.self) private var player
    var showsLabel = true

    var body: some View {
        Menu {
            Section("Apagar en") {
                ForEach(SleepTimer.options, id: \.self) { minutes in
                    Button(SleepTimer.label(minutes: minutes)) {
                        player.setSleepTimer(after: TimeInterval(minutes * 60))
                    }
                }
            }
            if player.sleepEndsAt != nil {
                Button("Cancelar temporizador", role: .destructive) {
                    player.setSleepTimer(after: nil)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "moon.zzz")
                if showsLabel, let remaining = player.sleepRemaining {
                    Text(SleepTimer.format(remaining: remaining)).monospacedDigit()
                }
            }
            .font(.body)
            .foregroundStyle(player.sleepEndsAt == nil ? Theme.muted : Theme.accent)
            .frame(minWidth: 40, minHeight: 40)
        }
        .disabled(!player.isActive)
        .accessibilityLabel(
            player.sleepRemaining.map { "Temporizador: se apaga en \(SleepTimer.format(remaining: $0))" }
                ?? "Temporizador para dormir"
        )
    }
}
