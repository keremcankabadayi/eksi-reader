import Foundation
import XCTest

enum Fixture {
    static func html(_ name: String) throws -> String {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: "Fixtures/\(name)", withExtension: "html"),
            "Fixture bulunamadı: \(name).html"
        )
        return try String(contentsOf: url, encoding: .utf8)
    }
}
