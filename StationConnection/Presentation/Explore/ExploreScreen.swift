import SwiftUI

/// Explorar: busca por nombre, filtra por género y país, y ordena.
struct ExploreScreen: View {
    @Bindable var viewModel: ExploreViewModel

    var body: some View {
        List {
            Section {
                filters
            }
            .listRowBackground(Theme.background)

            Section {
                results
            }
            .listRowBackground(Theme.background)
        }
        .listStyle(.plain)
        .screenBackground()
        .navigationTitle("Explorar")
        .searchable(text: $viewModel.text, prompt: "Buscar emisora por nombre")
        .task { await viewModel.onAppear() }
    }

    private var filters: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Menu {
                        Picker("Género", selection: $viewModel.tag) {
                            Text("Todos los géneros").tag("")
                            if !viewModel.tag.isEmpty, !viewModel.tags.contains(where: { $0.name == viewModel.tag }) {
                                Text(viewModel.tag.capitalized).tag(viewModel.tag)
                            }
                            ForEach(viewModel.tags) { Text($0.name.capitalized).tag($0.name) }
                        }
                    } label: {
                        FilterChip(title: viewModel.tag.isEmpty ? "Género" : viewModel.tag.capitalized, isActive: !viewModel.tag.isEmpty)
                    }
                    Menu {
                        Picker("País", selection: $viewModel.countryCode) {
                            Text("Todos los países").tag("")
                            ForEach(viewModel.countries) { Text($0.name).tag($0.code) }
                        }
                    } label: {
                        let name = viewModel.countries.first { $0.code == viewModel.countryCode }?.name ?? viewModel.countryCode
                        FilterChip(title: viewModel.countryCode.isEmpty ? "País" : name, isActive: !viewModel.countryCode.isEmpty)
                    }
                    Menu {
                        Picker("Ordenar por", selection: $viewModel.order) {
                            ForEach(StationOrder.allCases, id: \.self) { Text($0.title).tag($0) }
                        }
                    } label: {
                        FilterChip(title: viewModel.order.title, isActive: false, systemImage: "arrow.up.arrow.down")
                    }
                }
            }
            if viewModel.hasFilters {
                Button("Limpiar filtros") { viewModel.clearFilters() }
                    .font(.footnote)
                    .foregroundStyle(Theme.muted)
            }
        }
        .listRowSeparator(.hidden)
    }

    @ViewBuilder
    private var results: some View {
        switch viewModel.results {
        case .idle, .loading:
            ForEach(0..<8, id: \.self) { _ in
                HStack { RoundedRectangle(cornerRadius: 8).fill(Theme.surface).frame(width: 48, height: 48); Text("Cargando emisora") }
                    .redacted(reason: .placeholder)
                    .listRowSeparator(.hidden)
            }
        case let .failed(message):
            ErrorState(message: message) { viewModel.retry() }
                .listRowSeparator(.hidden)
        case let .loaded(stations) where stations.isEmpty:
            EmptyState(title: "No encontramos emisoras", message: "Prueba con otro nombre, género o país.")
                .listRowSeparator(.hidden)
        case let .loaded(stations):
            ForEach(stations) { station in
                StationRow(station: station)
                    .listRowSeparator(.hidden)
                    .stationQueue(stations)
            }
            if viewModel.canLoadMore {
                Button {
                    Task { await viewModel.loadMore() }
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isLoadingMore { ProgressView() } else { Text("Cargar más").fontWeight(.semibold) }
                        Spacer()
                    }
                }
                .foregroundStyle(Theme.foreground)
                .listRowSeparator(.hidden)
            }
        }
    }
}

/// Píldora de filtro.
private struct FilterChip: View {
    let title: String
    let isActive: Bool
    var systemImage = "chevron.down"

    var body: some View {
        HStack(spacing: 6) {
            Text(title).lineLimit(1)
            Image(systemName: systemImage).font(.caption2)
        }
        .font(.subheadline.weight(.medium))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .foregroundStyle(isActive ? .white : Theme.foreground)
        .background(Capsule().fill(isActive ? Theme.accent : Theme.surface))
        .overlay(Capsule().stroke(isActive ? .clear : Theme.border))
    }
}
