import SwiftUI

/// Pestañas de la app.
enum AppTab: Hashable {
    case home, explore, tuner, favorites
}

/// Crea el ViewModel del detalle de una emisora. La inyecta `AppContainer`,
/// así la presentación no sabe cómo se construyen los casos de uso.
typealias StationDetailFactory = @MainActor (Station) -> StationDetailViewModel

/// Raíz: cuatro pestañas, la barra del reproductor encima y la pantalla
/// "Reproduciendo" como hoja.
struct RootView: View {
    let home: HomeViewModel
    let explore: ExploreViewModel
    let tuner: TunerViewModel
    let makeStationDetail: StationDetailFactory

    @State private var selection: AppTab = .home
    @State private var isShowingPlayer = false

    var body: some View {
        TabView(selection: $selection) {
            tab(.home, title: "Inicio", systemImage: "house") {
                HomeScreen(viewModel: home) { tag in
                    explore.show(tag: tag)
                    selection = .explore
                }
            }
            tab(.explore, title: "Explorar", systemImage: "magnifyingglass") {
                ExploreScreen(viewModel: explore)
            }
            tab(.tuner, title: "Dial", systemImage: "radio") {
                TunerScreen(viewModel: tuner)
            }
            tab(.favorites, title: "Mis estaciones", systemImage: "heart") {
                FavoritesScreen()
            }
        }
        .tint(Theme.accent)
        .sheet(isPresented: $isShowingPlayer) {
            NowPlayingSheet()
                .presentationDragIndicator(.visible)
        }
    }

    /// Cada pestaña tiene su pila de navegación y la barra del reproductor encima.
    private func tab<Content: View>(
        _ value: AppTab,
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        NavigationStack {
            content()
                .navigationDestination(for: Station.self) { station in
                    StationDetailScreen(viewModel: makeStationDetail(station))
                }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            MiniPlayerBar { isShowingPlayer = true }
        }
        .tabItem { Label(title, systemImage: systemImage) }
        .tag(value)
    }
}
