// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "skip-sql",
    defaultLocalization: "en",
    platforms: [.iOS(.v16), .macOS(.v13), .tvOS(.v16), .watchOS(.v9), .macCatalyst(.v16)],
    products: [
        .library(name: "SkipSQL", targets: ["SkipSQL"]),
        .library(name: "SkipSQLKt", targets: ["SkipSQLKt"]),
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "0.6.8"),
        .package(url: "https://source.skip.tools/skip-unit.git", from: "0.1.2"),
        .package(url: "https://source.skip.tools/skip-lib.git", from: "0.2.3"),
        .package(url: "https://source.skip.tools/skip-foundation.git", from: "0.0.16"),
    ],
    targets: [
        .target(name: "SkipSQL", plugins: [.plugin(name: "preflight", package: "skip")]),
        .target(name: "SkipSQLKt", dependencies: [
            "SkipSQL",
            .product(name: "SkipUnitKt", package: "skip-unit"),
            .product(name: "SkipLibKt", package: "skip-lib"),
            .product(name: "SkipFoundationKt", package: "skip-foundation"),
        ], resources: [.process("Skip")], plugins: [.plugin(name: "transpile", package: "skip")]),
        .testTarget(name: "SkipSQLTests", dependencies: [
            "SkipSQL"
        ], plugins: [.plugin(name: "preflight", package: "skip")]),
        .testTarget(name: "SkipSQLKtTests", dependencies: [
            "SkipSQLKt",
            .product(name: "SkipUnit", package: "skip-unit"),
        ], resources: [.process("Skip")], plugins: [.plugin(name: "transpile", package: "skip")]),
    ]
)
