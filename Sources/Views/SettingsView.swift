import SwiftUI

struct SettingsView: View {
    @AppStorage("entryFontSize") private var fontSize: Double = 16

    var body: some View {
        Form {
            Section("okuma") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("yazı boyutu")
                        Spacer()
                        Text("\(Int(fontSize)) pt")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $fontSize, in: 12...26, step: 1)
                    Text("örnek satır")
                        .font(.system(size: fontSize))
                        .foregroundStyle(.secondary)
                }
            }

            Section("sürüm") {
                LabeledContent("uygulama", value: Self.versionString)
                LabeledContent("bundle id", value: Bundle.main.bundleIdentifier ?? "-")
            }
        }
        .navigationTitle("ayarlar")
    }

    /// Telefondaki build'in hangisi olduğunu doğrulamak için.
    private static var versionString: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(short) (\(build))"
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
