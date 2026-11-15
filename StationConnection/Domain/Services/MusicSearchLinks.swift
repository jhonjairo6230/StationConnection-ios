import Foundation

/// Enlaces para buscar una canción en servicios de música.
///
/// En el iPhone, si la app del servicio está instalada, iOS abre la app
/// directamente (enlaces universales).
struct MusicSearchLinks: Equatable {
    let youtubeMusic: URL
    let youtube: URL
    let spotify: URL

    init(song: Song) {
        let text = song.artist.map { "\($0) \(song.title)" } ?? song.title
        // urlQueryAllowed deja pasar "&" y "?", que romperían la consulta.
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&?=+#/")
        let query = text.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
        youtubeMusic = URL(string: "https://music.youtube.com/search?q=\(query)")!
        youtube = URL(string: "https://www.youtube.com/results?search_query=\(query)")!
        spotify = URL(string: "https://open.spotify.com/search/\(query)")!
    }
}
