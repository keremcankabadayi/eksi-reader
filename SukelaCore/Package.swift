// swift-tools-version: 5.9
import PackageDescription

// Platformdan bagimsiz cekirdek: modeller ve HTML parse mantigi.
// WebKit/UIKit ice girmiyor, boylece Linux'ta `swift test` ile Mac olmadan
// kosturulabiliyor. Cekme katmani (WKWebView) iOS hedefinde kaliyor.
let package = Package(
    name: "SukelaCore",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(name: "SukelaCore", targets: ["SukelaCore"]),
    ],
    dependencies: [
        // Saf Swift HTML parser. Kanna yerine bu: libxml2 sistem bagimliligi
        // yok, Linux'ta da iOS'ta da ayni calisiyor.
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.7.0"),
    ],
    targets: [
        .target(
            name: "SukelaCore",
            dependencies: ["SwiftSoup"]
        ),
        .testTarget(
            name: "SukelaCoreTests",
            dependencies: ["SukelaCore"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
