import Foundation
import SwiftSoup

/// Entry oyu. Ham değerler Ekşi'nin `rate` alanıyla birebir.
public enum VoteDirection: Int, Sendable, Hashable, Codable {
    case up = 1
    case down = -1
}

/// Oy isteğinin sonucu. Ekşi düz JSON döndürüyor; alan adları PascalCase
/// ama tek bir uçta bile değişebiliyor, o yüzden anahtarları büyük/küçük
/// harf ayırmadan arıyoruz.
public struct VoteResult: Equatable, Sendable {
    public let success: Bool
    /// Sunucunun kendi metni: "zaten oy verdiniz", "giriş yapmalısınız" vb.
    public let message: String?

    public init(success: Bool, message: String?) {
        self.success = success
        self.message = message
    }
}

public enum VoteParseError: LocalizedError {
    case notJSON
    case noSuccessField

    public var errorDescription: String? {
        switch self {
        case .notJSON:
            return "Oy yanıtı JSON değil."
        case .noSuccessField:
            return "Oy yanıtında sonuç alanı yok."
        }
    }
}

public enum VoteParser {
    /// Ekşi'nin oy uçlarının yanıtı: `{"Success":true,"Message":null}`.
    ///
    /// `Success` yoksa yanıtı başarılı saymıyoruz: giriş düşmüşse Ekşi JSON
    /// yerine giriş sayfasının HTML'ini döndürüyor, onu "oldu" sanmayalım.
    public static func parse(json: String) throws -> VoteResult {
        guard let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              let dictionary = object as? [String: Any] else {
            throw VoteParseError.notJSON
        }

        guard let success = bool(in: dictionary, key: "success") else {
            throw VoteParseError.noSuccessField
        }
        return VoteResult(success: success, message: string(in: dictionary, key: "message"))
    }

    /// ASP.NET antiforgery anahtarı. Sayfada gizli input olarak duruyor;
    /// bazı şablonlarda meta etiketiyle de veriliyor.
    public static func verificationToken(html: String) -> String? {
        if let document = try? SwiftSoup.parse(html) {
            let selectors = [
                "input[name=\"__RequestVerificationToken\"]",
                "meta[name=\"__RequestVerificationToken\"]",
            ]
            for selector in selectors {
                guard let element = try? document.select(selector).first() else { continue }
                let value = (try? element.attr("value")) ?? ""
                let content = (try? element.attr("content")) ?? ""
                let token = value.isEmpty ? content : value
                if !token.isEmpty { return token }
            }
        }

        // SwiftSoup sayfayı beğenmediyse (parça HTML, bozuk etiket) ham
        // metinde arıyoruz; anahtar tek satırda ve tırnaklı duruyor.
        return regexToken(in: html)
    }

    private static func regexToken(in html: String) -> String? {
        let pattern = "__RequestVerificationToken[^>]*?(?:value|content)\\s*=\\s*\"([^\"]+)\""
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(
                in: html,
                range: NSRange(html.startIndex..., in: html)
              ),
              let range = Range(match.range(at: 1), in: html) else { return nil }
        let token = String(html[range])
        return token.isEmpty ? nil : token
    }

    private static func value(in dictionary: [String: Any], key: String) -> Any? {
        dictionary.first { $0.key.lowercased() == key }?.value
    }

    private static func bool(in dictionary: [String: Any], key: String) -> Bool? {
        guard let raw = value(in: dictionary, key: key) else { return nil }
        if let flag = raw as? Bool { return flag }
        if let number = raw as? NSNumber { return number.boolValue }
        if let text = raw as? String { return ["true", "1"].contains(text.lowercased()) }
        return nil
    }

    private static func string(in dictionary: [String: Any], key: String) -> String? {
        guard let raw = value(in: dictionary, key: key),
              let text = raw as? String,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return text
    }
}
