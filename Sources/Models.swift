import Foundation
import SukelaCore

/// Uygulamadaki akışlar. Model tipleri (Topic, Entry, TopicPage) SukelaCore'dan
/// geliyor; burada yalnızca uygulamaya özgü olanlar duruyor.
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

    var endpoint: EksiEndpoint {
        switch self {
        case .gundem: return .gundem()
        case .debe: return .debe
        }
    }
}

/// Akışları sağlayan kaynak. Gerçek uygulama ve mock bunu paylaşıyor.
protocol FeedProviding {
    func topics(for feed: Feed) async throws -> [Topic]
    /// `page` nil ise bağlantının kendi sorgusu korunuyor: Ekşi daha önce
    /// açtığın başlıkta nereden devam edeceğini orada söylüyor.
    func topicPage(link: String, page: Int?) async throws -> TopicPage
}
