import SwiftUI

/// Inicio: lo que suena (o la última escuchada), favoritas, recientes,
/// populares, tendencias, géneros y más votadas.
struct HomeScreen: View {
    @Environment(PlayerViewModel.self) private var player
    @Environment(LibraryViewModel.self) private var library
    @Bindable var viewModel: HomeViewModel
    /// Abre Explorar filtrado por un género.
    let onSelectTag: (String) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HeroCard().padding(.horizontal)

                if !library.favorites.isEmpty {
                    StationCarousel(title: "Mis estaciones", state: .loaded(library.favorites))
                }
                if !library.recents.isEmpty {
                    StationCarousel(title: "Escuchadas recientemente", state: .loaded(library.recents))
                }
                StationCarousel(title: "Populares", state: viewModel.popular) { reload() }
                StationCarousel(title: "En tendencia", state: viewModel.trending) { reload() }
                genres
                StationCarousel(title: "Más votadas", state: viewModel.topVoted) { reload() }
            }
            .padding(.vertical)
        }
        .screenBackground()
        .navigationTitle("StationConnection")
        .refreshable { await viewModel.reload() }
        .task { await viewModel.onAppear() }
    }

    @ViewBuilder
    private var genres: some View {
        if let tags = viewModel.tags.value, !tags.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Géneros")
                FlowLayout(spacing: 8) {
                    ForEach(tags) { tag in
                        Button(tag.name.capitalized) { onSelectTag(tag.name) }
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .foregroundStyle(Theme.foreground)
                            .background(Capsule().fill(Theme.surface))
                            .overlay(Capsule().stroke(Theme.border))
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func reload() {
        Task { await viewModel.reload() }
    }
}

/// Tarjeta destacada: lo que suena, la última escuchada o una bienvenida.
private struct HeroCard: View {
    @Environment(PlayerViewModel.self) private var player
    @Environment(LibraryViewModel.self) private var library

    var body: some View {
        if let station = player.station ?? library.recents.first {
            HStack(spacing: 16) {
                StationArtworkView(station: station, cornerRadius: 16).frame(width: 96)
                VStack(alignment: .leading, spacing: 4) {
                    Text(player.station == nil ? "CONTINUAR ESCUCHANDO" : "SONANDO AHORA")
                        .font(.caption.weight(.semibold))
                        .tracking(1.5)
                        .foregroundStyle(Theme.muted)
                    Text(station.name)
                        .font(.title2.bold())
                        .foregroundStyle(Theme.foreground)
                        .lineLimit(2)
                    Text(station.subtitle).font(.subheadline).foregroundStyle(Theme.muted).lineLimit(1)
                }
                Spacer(minLength: 0)
                // "Continuar escuchando": ⏮/⏭ recorren las recientes.
                PlayButton(station: station, size: 56)
                    .stationQueue(player.station == nil ? library.recents : [])
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(LinearGradient(colors: [Theme.accent.opacity(0.3), Theme.accent2.opacity(0.2), Theme.surface], startPoint: .topLeading, endPoint: .bottomTrailing))
            )
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text("RADIO EN VIVO").font(.caption.weight(.semibold)).tracking(1.5).foregroundStyle(.white.opacity(0.8))
                Text("Miles de estaciones del mundo, a un toque.")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                Text("Busca por nombre, género o país, guarda tus favoritas y escucha con la pantalla bloqueada.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(LinearGradient(colors: [Theme.accent.opacity(0.85), Theme.accent2.opacity(0.75), Theme.surface], startPoint: .topLeading, endPoint: .bottomTrailing))
            )
        }
    }
}

/// Distribuye las etiquetas en filas que saltan de línea (como `flex-wrap`).
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(subviews, width: proposal.width ?? .infinity)
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(subviews, width: bounds.width) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(_ subviews: Subviews, width: CGFloat) -> [Row] {
        var rows: [Row] = [Row()]
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let extra = rows[rows.count - 1].indices.isEmpty ? size.width : size.width + spacing
            if rows[rows.count - 1].width + extra > width, !rows[rows.count - 1].indices.isEmpty {
                rows.append(Row())
            }
            let isFirst = rows[rows.count - 1].indices.isEmpty
            rows[rows.count - 1].indices.append(index)
            rows[rows.count - 1].width += isFirst ? size.width : size.width + spacing
            rows[rows.count - 1].height = max(rows[rows.count - 1].height, size.height)
        }
        return rows.filter { !$0.indices.isEmpty }
    }
}
