import Foundation

/// Entry oyu. Ham değerler Ekşi'nin `rate` alanıyla birebir.
public enum VoteDirection: Int, Sendable, Hashable, Codable {
    case up = 1
    case down = -1
}

/// Oy isteğinin sonucu.
public struct VoteResult: Equatable, Sendable {
    public let success: Bool
    /// Sunucunun kendi metni: "zaten oy verdiniz", "kendi entry'ne oy
    /// veremezsin" vb.
    public let message: String?
    /// Anonim oy verilmiş; Ekşi kayıt olmayı öneriyor.
    public let alreadyVotedAnonymously: Bool

    public init(success: Bool, message: String?, alreadyVotedAnonymously: Bool = false) {
        self.success = success
        self.message = message
        self.alreadyVotedAnonymously = alreadyVotedAnonymously
    }
}

public enum VoteParseError: LocalizedError, Equatable {
    /// Ekşi oturum yoksa JSON değil, düz "nologin" yazıyor.
    case notLoggedIn
    case notJSON
    case noSuccessField

    public var errorDescription: String? {
        switch self {
        case .notLoggedIn:
            return "Oturum düşmüş, yeniden giriş yapman gerekiyor."
        case .notJSON:
            return "Oy yanıtı JSON değil."
        case .noSuccessField:
            return "Oy yanıtında sonuç alanı yok."
        }
    }
}

public enum VoteParser {
    /// `/entry/vote` ve `/entry/removevote` yanıtı.
    ///
    /// Sitenin kendi JS'i `SuccessData.Success` / `SuccessData.Message`
    /// okuyor; sarmalayanın dışında `LikeCount` duruyor. Eski istemcilerde
    /// alanların düz hâli de görülüyor, ikisini de kabul ediyoruz.
    ///
    /// `Success` hiç yoksa yanıtı başarılı saymıyoruz: oturum düşünce Ekşi
    /// JSON yerine sayfa döndürüyor, onu "oldu" sanmayalım.
    public static func parse(json: String) throws -> VoteResult {
        let trimmed = json.trimmingCharacters(in: .whitespacesAndNewlines)
        // Oturumsuz istekte gövde tırnaksız `nologin`; JSON bile değil.
        if trimmed.replacingOccurrences(of: "\"", with: "").lowercased() == "nologin" {
            throw VoteParseError.notLoggedIn
        }

        guard let data = trimmed.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              let root = object as? [String: Any] else {
            throw VoteParseError.notJSON
        }

        var payload = root
        if let nested = value(in: root, key: "successdata"),
           let wrapped = nested as? [String: Any] {
            payload = wrapped
        }
        guard let success = bool(in: payload, key: "success") else {
            throw VoteParseError.noSuccessField
        }

        return VoteResult(
            success: success,
            message: string(in: payload, key: "message")
                ?? string(in: payload, key: "errormessage"),
            alreadyVotedAnonymously: bool(in: payload, key: "alreadyvotedanonymously") ?? false
        )
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
