import SwiftUI
import UniformTypeIdentifiers

/// Mis estaciones: favoritas (ordenables), respaldo e historial de canciones.
struct FavoritesScreen: View {
    @Environment(LibraryViewModel.self) private var library
    @State private var editMode: EditMode = .inactive
    @State private var exportFile: BackupFile?
    @State private var isExporting = false
    @State private var isImporting = false

    var body: some View {
        @Bindable var library = library
        List {
            Section {
                if library.favorites.isEmpty {
                    EmptyState(
                        title: "Aún no tienes favoritas",
                        message: "Toca el corazón en cualquier emisora para guardarla aquí."
                    )
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(Array(library.favorites.enumerated()), id: \.element.id) { index, station in
                        StationRow(station: station, index: index)
                            .stationQueue(library.favorites)
                            .listRowSeparator(.hidden)
                    }
                    .onMove { library.moveFavorites(from: $0, to: $1) }
                }
            } header: {
                if editMode.isEditing {
                    HStack {
                        Text("Arrastra ≡ para ordenar. ⏮ ⏭ y el auto siguen este orden.")
                        Spacer()
                        Button("A–Z") { library.sortFavoritesByName() }
                    }
                    .font(.footnote)
                    .textCase(nil)
                }
            }
            .listRowBackground(Theme.background)

            Section("Respaldo") {
                Text("Tus favoritas solo se guardan en este dispositivo. Guárdalas en Archivos o iCloud para no perderlas; el archivo también funciona en la versión web.")
                    .font(.footnote)
                    .foregroundStyle(Theme.muted)
                HStack {
                    Button("Exportar") {
                        exportFile = library.exportFavorites()
                        isExporting = exportFile != nil
                    }
                    .disabled(library.favorites.isEmpty)
                    Spacer()
                    Button("Importar") { isImporting = true }
                }
                .buttonStyle(.bordered)
                .tint(Theme.foreground)
            }
            .listRowBackground(Theme.surface)

            SongHistorySection()
        }
        .listStyle(.insetGrouped)
        .screenBackground()
        .navigationTitle("Mis estaciones")
        .toolbar {
            if library.favorites.count > 1 {
                EditButton()
            }
        }
        .environment(\.editMode, $editMode)
        .fileExporter(
            isPresented: $isExporting,
            document: exportFile.map { BackupDocument(data: $0.data) },
            contentType: .json,
            defaultFilename: exportFile?.fileName ?? "stationconnection-favoritas.json"
        ) { _ in }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json]) { result in
            guard case let .success(url) = result else { return }
            // Archivos de iCloud o de otras apps: hay que pedir acceso temporal.
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }
            if let data = try? Data(contentsOf: url) {
                library.importFavorites(data)
            } else {
                library.alert = AlertMessage(error: StationError.invalidBackup)
            }
        }
        .alert(item: $library.alert) { alert in
            Alert(title: Text(alert.title), message: Text(alert.message))
        }
    }
}

/// Historial de canciones detectadas, con enlaces de búsqueda.
private struct SongHistorySection: View {
    @Environment(LibraryViewModel.self) private var library

    var body: some View {
        Section {
            if library.songs.isEmpty {
                Text("Cuando una emisora informe qué está sonando, la verás aquí para buscarla después.")
                    .font(.footnote)
                    .foregroundStyle(Theme.muted)
            } else {
                ForEach(library.songs) { played in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(played.song.title).font(.body.weight(.medium)).foregroundStyle(Theme.foreground)
                        Text([played.song.artist, played.stationName, played.playedAt.formatted(date: .omitted, time: .shortened)]
                            .compactMap { $0 }
                            .joined(separator: " · "))
                            .font(.footnote)
                            .foregroundStyle(Theme.muted)
                        ScrollView(.horizontal, showsIndicators: false) {
                            SongLinksView(song: played.song)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        } header: {
            HStack {
                Text("Canciones que sonaron")
                Spacer()
                if !library.songs.isEmpty {
                    Button("Borrar") { library.clearSongs() }.textCase(nil)
                }
            }
        }
        .listRowBackground(Theme.surface)
    }
}
