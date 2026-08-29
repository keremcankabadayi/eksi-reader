import SwiftUI

/// Başlık listesinin en üstündeki arama kutusu.
///
/// Listenin ilk satırı olarak duruyor: aşağı kaydırınca başlıklarla birlikte
/// yukarı kayıp gözden kayboluyor, en üste dönünce kendiliğinden geri geliyor.
/// Ayrı bir kaydırma dinleyicisi yok, davranışı listenin kendisi veriyor.
struct TopicSearchField: View {
    @Binding var query: String
    /// Klavyedeki "ara" tuşu.
    var onSubmit: () -> Void

    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Palette.meta)

            TextField("başlık ara", text: $query)
                .focused($focused)
                .submitLabel(.search)
                .onSubmit(onSubmit)
                .foregroundStyle(Palette.text)
                // Ekşi başlıkları küçük harf; otomatik büyütme ve düzeltme
                // aramayı bozuyor.
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !query.isEmpty {
                Button {
                    query = ""
                    focused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Palette.meta)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("aramayı temizle")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Palette.surface)
        )
    }
}

#Preview {
    TopicSearchField(query: .constant(""), onSubmit: {})
        .padding()
        .background(Palette.base)
}
