// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "skip-sql",
    defaultLocalization: "en",
    platforms: [.iOS(.v16), .macOS(.v13), .tvOS(.v16), .watchOS(.v9), .macCatalyst(.v16)],
    products: [
        .library(name: "SkipSQL", targets: ["SkipSQL"]),
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "0.7.30"),
        .package(url: "https://source.skip.tools/skip-foundation.git", from: "0.3.7"),
        .package(url: "https://source.skip.tools/skip-ffi.git", from: "0.2.1"),
    ],
    targets: [
        .target(name: "SkipSQL", dependencies: [
            .product(name: "SkipFoundation", package: "skip-foundation"),
            .product(name: "SkipFFI", package: "skip-ffi")
        ], plugins: [.plugin(name: "skipstone", package: "skip")]),
        .testTarget(name: "SkipSQLTests", dependencies: [
            "SkipSQL",
            .product(name: "SkipTest", package: "skip")
        ], plugins: [.plugin(name: "skipstone", package: "skip")]),
    ]
)
