import SwiftUI
import WidgetKit
import SukelaCore

/// Gündem widget'ı: uygulamanın son çektiği başlıklar, sağlarında entry
/// sayısı. Bir başlığa dokununca uygulama o başlığı açıyor.
@main
struct GundemWidget: Widget {
    private let kind = "GundemWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GundemProvider()) { entry in
            GundemWidgetView(entry: entry)
        }
        .configurationDisplayName("gündem")
        .description("Şükela Lite'ın son çektiği gündem başlıkları.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct GundemEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?

    static let placeholder = GundemEntry(
        date: Date(timeIntervalSince1970: 1_756_000_000),
        snapshot: WidgetSnapshot(
            topics: [
                WidgetTopic(title: "kendi ekşi istemcini yazmak", entryCount: "142", link: "/a--1"),
                WidgetTopic(title: "sideloading", entryCount: "37", link: "/b--2"),
                WidgetTopic(title: "swiftui", entryCount: "89", link: "/c--3"),
                WidgetTopic(title: "7 günde bir uygulama yenilemek", entryCount: "64", link: "/d--4"),
            ],
            updatedAt: Date(timeIntervalSince1970: 1_756_000_000)
        )
    )
}

struct GundemProvider: TimelineProvider {
    func placeholder(in context: Context) -> GundemEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (GundemEntry) -> Void) {
        completion(context.isPreview ? .placeholder : current())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GundemEntry>) -> Void) {
        // Veriyi uygulama yazıyor; burada yalnızca dosyayı yeniden okuyoruz.
        // Uygulama gündemi çektiğinde zaten yenileme isteği gönderiyor.
        let next = Date().addingTimeInterval(30 * 60)
        completion(Timeline(entries: [current()], policy: .after(next)))
    }

    private func current() -> GundemEntry {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: WidgetStore.appGroup
        ) else {
            return GundemEntry(date: Date(), snapshot: nil)
        }
        return GundemEntry(date: Date(), snapshot: try? WidgetStore.read(from: container))
    }
}

struct GundemWidgetView: View {
    let entry: GundemEntry

    @Environment(\.widgetFamily) private var family

    /// Widget yüksekliğine sığan başlık sayısı.
    private var rowCount: Int {
        switch family {
        case .systemSmall: return 4
        case .systemMedium: return 5
        case .systemLarge: return 11
        default: return 5
        }
    }

    private var topics: [WidgetTopic] {
        Array((entry.snapshot?.topics ?? []).prefix(rowCount))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            if topics.isEmpty {
                empty
            } else {
                ForEach(Array(topics.enumerated()), id: \.element.id) { index, topic in
                    Link(destination: url(for: topic)) {
                        row(topic, isEven: index % 2 == 0)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(10)
        .widgetBackground()
    }

    private var header: some View {
        HStack {
            Text("gündem")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.green)
            Spacer(minLength: 0)
            if let updatedAt = entry.snapshot?.updatedAt {
                Text(updatedAt, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.bottom, 6)
    }

    private var empty: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("gündem yok")
                .font(.caption.weight(.semibold))
            Text("uygulamayı bir kez açınca başlıklar buraya düşüyor.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
    }

    private func row(_ topic: WidgetTopic, isEven: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(topic.title)
                .font(.caption)
                .foregroundStyle(.primary)
                .lineLimit(family == .systemSmall ? 1 : 2)

            Spacer(minLength: 0)

            if !topic.entryCount.isEmpty {
                Text(topic.entryCount)
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Palette.green)
            }
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 4)
        .background(isEven ? Color.clear : Color.primary.opacity(0.05))
    }

    private func url(for topic: WidgetTopic) -> URL {
        DeepLink.topic(link: topic.link, title: topic.title).url
            ?? URL(string: "\(DeepLink.scheme)://topic")!
    }
}

private extension View {
    /// iOS 17 widget zeminini istiyor; 16'da eski davranış geçerli.
    @ViewBuilder
    func widgetBackground() -> some View {
        if #available(iOS 17.0, *) {
            containerBackground(.fill.tertiary, for: .widget)
        } else {
            self
        }
    }
}
