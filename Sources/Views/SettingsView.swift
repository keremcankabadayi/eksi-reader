import SwiftUI

struct SettingsView: View {
    @AppStorage("entryFontSize") private var fontSize: Double = 16
    @AppStorage(AppTheme.storageKey) private var theme: AppTheme = .light

    var body: some View {
        Form {
            Section("görünüm") {
                Picker("tema", selection: $theme) {
                    ForEach(AppTheme.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }

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

            Section("teşhis") {
                NavigationLink {
                    LogsView()
                } label: {
                    Label("günlük", systemImage: "text.alignleft")
                }
            }

            Section("sürüm") {
                LabeledContent("uygulama", value: Self.versionString)
                LabeledContent("bundle id", value: Bundle.main.bundleIdentifier ?? "-")
                // Widget veriyi buradan okuyor; "yok" ise widget boş kalır.
                LabeledContent("app group", value: AppGroupContainer.identifier ?? "yok")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Palette.base)
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
