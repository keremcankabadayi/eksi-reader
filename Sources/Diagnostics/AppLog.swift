import Foundation
import Combine

/// Uygulama içi günlük. Telefonda Xcode konsolu yok; ayarlar > günlük
/// ekranından bakılıyor, kopyalanıp dışarı çıkarılabiliyor.
@MainActor
final class AppLog: ObservableObject {
    static let shared = AppLog()

    enum Level: String {
        case info = "bilgi"
        case warn = "uyarı"
        case error = "hata"
    }

    struct Entry: Identifiable {
        let id = UUID()
        let date: Date
        let level: Level
        let message: String
    }

    /// Halka tampon: uzun oturumda bellek şişmesin.
    private static let limit = 400

    @Published private(set) var entries: [Entry] = []

    private init() {}

    func append(_ level: Level, _ message: String) {
        entries.append(Entry(date: Date(), level: level, message: message))
        if entries.count > Self.limit {
            entries.removeFirst(entries.count - Self.limit)
        }
    }

    func clear() {
        entries.removeAll()
    }

    /// Kopyalanabilir düz metin hâli.
    var text: String {
        entries.map { entry in
            "\(Self.formatter.string(from: entry.date)) [\(entry.level.rawValue)] \(entry.message)"
        }
        .joined(separator: "\n")
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    // Çağrı yerlerini kısaltmak için. Ana aktöre kendileri atlıyor.
    nonisolated static func info(_ message: String) { emit(.info, message) }
    nonisolated static func warn(_ message: String) { emit(.warn, message) }
    nonisolated static func error(_ message: String) { emit(.error, message) }

    nonisolated private static func emit(_ level: Level, _ message: String) {
        Task { @MainActor in shared.append(level, message) }
    }
}
