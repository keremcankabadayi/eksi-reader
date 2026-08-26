import Foundation

/// Bir başlık. Şu an mock veriden geliyor; gerçek veri katmanı geldiğinde
/// alanlar aynı kalacak şekilde doldurulacak.
struct Topic: Identifiable, Hashable {
    let id: Int
    let title: String
    let entryCount: Int
}

/// Bir entry.
struct Entry: Identifiable, Hashable {
    let id: Int
    let body: String
    let author: String
    let date: String
    let favCount: Int
}

/// Uygulamadaki akışlar.
enum Feed: String, CaseIterable, Identifiable {
    case gundem
    case debe

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gundem: return "gündem"
        case .debe: return "debe"
        }
    }

    var systemImage: String {
        switch self {
        case .gundem: return "flame"
        case .debe: return "star"
        }
    }
}

/// Akışları sağlayan kaynak. Mock ve gerçek uygulama bunu paylaşacak.
protocol FeedProviding {
    func topics(for feed: Feed) -> [Topic]
    func entries(for topic: Topic) -> [Entry]
}
