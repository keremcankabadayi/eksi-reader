import SwiftUI
import UIKit

/// Ayarlar > günlük. Telefonda ne olup bittiğini görebilmek için.
@MainActor
struct LogsView: View {
    @ObservedObject private var log = AppLog.shared

    var body: some View {
        Group {
            if log.entries.isEmpty {
                ContentUnavailableFallback()
            } else {
                List {
                    ForEach(log.entries.reversed()) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(Self.formatter.string(from: entry.date))
                                Text(entry.level.rawValue)
                                    .foregroundStyle(color(for: entry.level))
                            }
                            .font(.system(size: 11, design: .monospaced))
                            .monospacedFont()
                            .foregroundStyle(.secondary)

                            Text(entry.message)
                                .font(.system(size: 12, design: .monospaced))
                                .monospacedFont()
                                .textSelection(.enabled)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("günlük")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    UIPasteboard.general.string = log.text
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .disabled(log.entries.isEmpty)

                Button {
                    log.clear()
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(log.entries.isEmpty)
            }
        }
    }

    private func color(for level: AppLog.Level) -> Color {
        switch level {
        case .info: return .secondary
        case .warn: return .orange
        case .error: return .red
        }
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}

/// iOS 17'nin ContentUnavailableView'ı 16'da yok; hedefimiz 16.
private struct ContentUnavailableFallback: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "text.alignleft")
                .font(.title2)
            Text("henüz kayıt yok")
                .font(.callout)
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
