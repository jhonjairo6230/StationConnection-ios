import WidgetKit

/// Una "foto" en el tiempo para pintar un widget.
struct StationEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
    /// `false` si la firma no trae el App Group: el widget muestra su modo de respaldo.
    let hasSharedData: Bool

    static let preview = StationEntry(
        date: Date(),
        snapshot: WidgetSnapshot(
            current: .init(id: "preview", name: "La Mega", subtitle: "Colombia · pop", initials: "LM", gradientIndex: 0),
            isPlaying: true,
            songTitle: "Hips Don't Lie",
            songArtist: "Shakira",
            favorites: [
                .init(id: "1", name: "La Mega", subtitle: "", initials: "LM", gradientIndex: 0),
                .init(id: "2", name: "Jazz FM", subtitle: "", initials: "JF", gradientIndex: 4),
                .init(id: "3", name: "Tropicana", subtitle: "", initials: "TR", gradientIndex: 3),
                .init(id: "4", name: "Clásica 24", subtitle: "", initials: "C2", gradientIndex: 2),
            ]
        ),
        hasSharedData: true
    )
}

/// Lee la foto que guarda la app. No se programa ninguna actualización:
/// la app avisa a iOS (`WidgetCenter`) cada vez que algo cambia.
struct SnapshotProvider: TimelineProvider {
    private let store = SharedWidgetStore.live()

    func placeholder(in context: Context) -> StationEntry { .preview }

    func getSnapshot(in context: Context, completion: @escaping (StationEntry) -> Void) {
        completion(context.isPreview ? .preview : currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StationEntry>) -> Void) {
        completion(Timeline(entries: [currentEntry()], policy: .never))
    }

    private func currentEntry() -> StationEntry {
        StationEntry(date: Date(), snapshot: store.load() ?? .empty, hasSharedData: store.isAvailable)
    }
}
