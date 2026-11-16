import SwiftUI

/// El sintonizador retro: una radio de madera con pantalla LCD, escala de FM,
/// aguja y perilla.
struct TunerScreen: View {
    @Environment(PlayerViewModel.self) private var player
    @Bindable var viewModel: TunerViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Gira el dial como en la radio de siempre.")
                    .foregroundStyle(Theme.muted)
                bandPicker
                if let message = viewModel.loadState.errorMessage {
                    ErrorState(message: message) {
                        Task { await viewModel.onAppear() }
                    }
                }
                radio
                Text("Consejo: arrastra la escala o la perilla, o usa ◀◀ ▶▶ para saltar de emisora.")
                    .font(.footnote)
                    .foregroundStyle(Theme.muted)
            }
            .padding()
        }
        .screenBackground()
        .navigationTitle("Dial")
        .task { await viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
        .onChange(of: player.station?.id) { viewModel.syncToPlayingStation() }
        .onChange(of: player.status) { viewModel.updateNoise() }
    }

    // MARK: - Banda

    private var bandPicker: some View {
        HStack(spacing: 10) {
            Text("Banda").foregroundStyle(Theme.muted)
            Menu {
                Section("Géneros") {
                    ForEach(viewModel.tags.isEmpty ? [Tag(name: "pop", stationCount: 0)] : viewModel.tags) { tag in
                        Button(tag.name.capitalized) { select(.tag(tag.name)) }
                    }
                }
                Section("Países") {
                    ForEach(viewModel.countries) { country in
                        Button(country.name) { select(.country(code: country.code, name: country.name)) }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(viewModel.band.title)
                    Image(systemName: "chevron.down").font(.caption2)
                }
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundStyle(Theme.foreground)
                .background(Capsule().fill(Theme.surface))
                .overlay(Capsule().stroke(Theme.border))
            }
            if viewModel.loadState.value != nil {
                Text("\(viewModel.stations.count) emisoras en el dial")
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
            } else if viewModel.loadState.isLoading {
                ProgressView()
            }
        }
    }

    private func select(_ band: TunerBand) {
        Task { await viewModel.select(band) }
    }

    // MARK: - Radio

    private var radio: some View {
        VStack(spacing: 16) {
            lcd
            scale
            HStack {
                seekButton(.previous, symbol: "backward.fill", label: "Emisora anterior del dial")
                seekButton(.next, symbol: "forward.fill", label: "Emisora siguiente del dial")
                Spacer()
                KnobView(value: viewModel.value) { viewModel.move(to: $0) }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(hex: 0x1D140D).opacity(0.6))
        )
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: 0x7A4E2D), Color(hex: 0x5E3B20), Color(hex: 0x3F2614)], startPoint: .top, endPoint: .bottom))
        )
        .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Radio")
    }

    private var lcd: some View {
        let green = Color(hex: 0x9DFFB0)
        return VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(String(format: "%.1f", viewModel.frequency))
                    .font(.system(size: 40, weight: .regular, design: .monospaced))
                Text("FM").font(.system(.body, design: .monospaced))
                Spacer()
                Text(viewModel.statusText)
                    .font(.system(.caption, design: .monospaced))
                    .opacity(0.85)
            }
            Text(viewModel.lockedStation?.name ?? "~ ~ ~ estática ~ ~ ~")
                .font(.system(.subheadline, design: .monospaced))
                .lineLimit(1)
            Text(songText)
                .font(.system(.caption, design: .monospaced))
                .opacity(0.75)
                .lineLimit(1)
        }
        .foregroundStyle(green)
        .shadow(color: green.opacity(0.6), radius: 6)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: 0x0F1A12)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.black.opacity(0.6)))
    }

    private var songText: String {
        guard viewModel.isOnAir, let song = player.nowPlaying else { return " " }
        return "♪ " + (song.artist.map { "\($0) – " } ?? "") + song.title
    }

    private var scale: some View {
        GeometryReader { proxy in
            let width = proxy.size.width - 24
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 10).fill(Color(hex: 0xEFE3C8))
                // Números de la escala: 88, 92, … 108.
                ForEach(Array(stride(from: TunerDial.fmMin, through: TunerDial.fmMax, by: 4)), id: \.self) { mhz in
                    let x = 12 + width * (mhz - TunerDial.fmMin) / (TunerDial.fmMax - TunerDial.fmMin)
                    Text(String(Int(mhz)))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color(hex: 0x3B2A1A))
                        .position(x: x, y: 14)
                    Rectangle().fill(Color(hex: 0x3B2A1A).opacity(0.6)).frame(width: 1, height: 12).position(x: x, y: 32)
                }
                // Una marca por emisora.
                ForEach(Array(viewModel.stations.indices), id: \.self) { index in
                    Circle()
                        .fill(Color(hex: 0xB5462E))
                        .frame(width: 6, height: 6)
                        .position(x: 12 + width * TunerDial.position(of: index, count: viewModel.stations.count) / TunerDial.maxValue, y: 52)
                }
                // Aguja.
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 2)
                    .shadow(color: .red.opacity(0.8), radius: 4)
                    .position(x: 12 + width * viewModel.value / TunerDial.maxValue, y: proxy.size.height / 2)
                    .frame(height: proxy.size.height - 8)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0).onChanged { drag in
                    viewModel.move(to: (drag.location.x - 12) / width * TunerDial.maxValue)
                }
            )
        }
        .frame(height: 72)
        .accessibilityElement()
        .accessibilityLabel("Dial de frecuencia")
        .accessibilityValue("\(String(format: "%.1f", viewModel.frequency)) FM, \(viewModel.lockedStation?.name ?? "sin señal")")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: viewModel.seek(.next)
            case .decrement: viewModel.seek(.previous)
            @unknown default: break
            }
        }
    }

    private func seekButton(_ direction: SkipDirection, symbol: String, label: String) -> some View {
        Button { viewModel.seek(direction) } label: {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(Color(hex: 0xEFE3C8))
                .frame(width: 56, height: 44)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: 0x2B1C11)))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.stations.isEmpty)
        .accessibilityLabel(label)
    }
}

/// Perilla metálica: arrastrar a la derecha o hacia arriba sube la frecuencia.
private struct KnobView: View {
    let value: Double
    let onChange: (Double) -> Void
    @State private var startValue: Double?

    var body: some View {
        let angle = value / TunerDial.maxValue * 300 - 150
        Circle()
            .fill(
                LinearGradient(colors: [Color(hex: 0xD9D4CC), Color(hex: 0x9B968E), Color(hex: 0x5D5952)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .overlay(alignment: .top) {
                Capsule().fill(Color(hex: 0x2B1C11)).frame(width: 4, height: 16).padding(.top, 6)
            }
            .rotationEffect(.degrees(angle))
            .frame(width: 72, height: 72)
            .shadow(color: .black.opacity(0.6), radius: 6, y: 4)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        let start = startValue ?? value
                        if startValue == nil { startValue = start }
                        let delta = drag.translation.width - drag.translation.height
                        onChange(start + delta * 2)
                    }
                    .onEnded { _ in startValue = nil }
            )
            .accessibilityHidden(true)
    }
}
