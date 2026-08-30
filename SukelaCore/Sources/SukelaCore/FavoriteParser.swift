import Foundation

/// Favorileme isteğinin sonucu.
public struct FavoriteResult: Equatable, Sendable {
    public let success: Bool
    /// Sunucunun döndüğü yeni favori sayısı. Yoksa nil, ekrandaki sayı durur.
    public let count: Int?
    /// Ekşi'nin kendi hata metni.
    public let message: String?

    public init(success: Bool, count: Int?, message: String? = nil) {
        self.success = success
        self.count = count
        self.message = message
    }
}

public enum FavoriteParseError: LocalizedError, Equatable {
    /// Oturum yoksa Ekşi JSON değil, düz "nologin" yazıyor.
    case notLoggedIn
    case notJSON
    case noSuccessField

    public var errorDescription: String? {
        switch self {
        case .notLoggedIn:
            return "Oturum düşmüş, yeniden giriş yapman gerekiyor."
        case .notJSON:
            return "Favori yanıtı JSON değil."
        case .noSuccessField:
            return "Favori yanıtında sonuç alanı yok."
        }
    }
}

/// `/entry/favla` ve `/entry/favlama` yanıtı.
///
/// Sitenin kendi JS'i `Success`, `Count` ve `ErrorMessage` okuyor; oy ucunun
/// aksine sarmalayan yok, alanlar kökte duruyor. Yine de sarmalanmış hâli de
/// kabul ediyoruz: oy ucu `SuccessData` kullanıyor, buranın da bir gün öyle
/// olması sürpriz olmaz.
///
/// `Success` hiç yoksa başarılı saymıyoruz: oturum düşünce JSON yerine sayfa
/// gelebiliyor, onu "oldu" sanmayalım.
public enum FavoriteParser {
    public static func parse(json: String) throws -> FavoriteResult {
        let trimmed = json.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.replacingOccurrences(of: "\"", with: "").lowercased() == "nologin" {
            throw FavoriteParseError.notLoggedIn
        }

        guard let data = trimmed.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              let root = object as? [String: Any] else {
            throw FavoriteParseError.notJSON
        }

        var payload = root
        if let nested = value(in: root, key: "successdata") as? [String: Any] {
            payload = nested
        }
        guard let success = bool(in: payload, key: "success") else {
            throw FavoriteParseError.noSuccessField
        }

        return FavoriteResult(
            success: success,
            // Sayı sarmalayanın dışında da durabiliyor, ikisine de bakıyoruz.
            count: int(in: payload, key: "count") ?? int(in: root, key: "count"),
            message: string(in: payload, key: "errormessage")
                ?? string(in: payload, key: "message")
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

    private static func int(in dictionary: [String: Any], key: String) -> Int? {
        guard let raw = value(in: dictionary, key: key) else { return nil }
        if let number = raw as? NSNumber { return number.intValue }
        if let text = raw as? String { return Int(text) }
        return nil
    }

    private static func string(in dictionary: [String: Any], key: String) -> String? {
        guard let text = value(in: dictionary, key: key) as? String,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return text
    }
}
