import Foundation

/// Cloudflare'ın "Just a moment..." ara sayfasını tanıyor.
///
/// Saf mantık olarak burada duruyor ki WebKit olmadan test edilebilsin;
/// çekme katmanı buna bakıp yeniden bootstrap kararı veriyor.
///
/// Sinyaller emreisik95/eksilik-os (MIT) projesindeki `WebBootstrapPolicy`
/// dosyasından alındı.
public enum CloudflareChallenge {
    private static let titleMarkers = [
        "lütfen bekleyiniz",
        "just a moment",
        "checking your browser",
        "attention required",
    ]

    private static let htmlMarkers = [
        "_cf_chl_opt",
        "/cdn-cgi/challenge-platform/",
        "cf-chl-",
    ]

    /// Yanıt bir challenge sayfası mı?
    public static func isChallenge(
        headers: [String: String] = [:],
        title: String = "",
        html: String = ""
    ) -> Bool {
        let normalizedHeaders = headers.reduce(into: [String: String]()) { result, pair in
            result[pair.key.lowercased()] = pair.value.lowercased()
        }
        if normalizedHeaders["cf-mitigated"] == "challenge" {
            return true
        }

        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if titleMarkers.contains(where: normalizedTitle.contains) {
            return true
        }

        let normalizedHTML = html.lowercased()
        return htmlMarkers.contains(where: normalizedHTML.contains)
    }

    /// Bootstrap tamamlandı sayılabilir mi? Challenge geçilmiş ve elimizde
    /// gerçek bir sayfa var mı diye bakıyor.
    public static func isReady(
        statusCode: Int?,
        headers: [String: String] = [:],
        title: String = "",
        html: String = ""
    ) -> Bool {
        guard let statusCode, (200...299).contains(statusCode) else { return false }
        guard !isChallenge(headers: headers, title: title, html: html) else { return false }

        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return !normalizedTitle.isEmpty && html.lowercased().contains("<html")
    }
}
