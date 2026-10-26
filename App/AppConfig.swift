import Foundation

enum AppConfig {
    /// Used only if Info.plist carries no usable NotesStartURL.
    private static let fallbackURL =
        "http://192.168.0.106:8092/notes-generation/dark-glass/index.html?start=panes"

    /// The page the app opens: the iOS counterpart of `startUrl` in the Android MainActivity.kt.
    static var startURL: URL? {
        let raw = (Bundle.main.object(forInfoDictionaryKey: "NotesStartURL") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        // An unexpanded "$(NOTES_START_URL)" means the build setting was missing.
        return URL(string: raw.isEmpty || raw.hasPrefix("$(") ? fallbackURL : raw)
    }
}
