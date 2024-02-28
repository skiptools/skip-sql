// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "skip-sql",
    defaultLocalization: "en",
    platforms: [.iOS(.v16), .macOS(.v13), .tvOS(.v16), .watchOS(.v9), .macCatalyst(.v16)],
    products: [
        .library(name: "SkipSQL", targets: ["SkipSQL"]),
        .library(name: "SkipSQLPlus", type: .dynamic, targets: ["SkipSQLPlus"]),
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "0.8.14"),
        .package(url: "https://source.skip.tools/skip-foundation.git", from: "0.5.7"),
        .package(url: "https://source.skip.tools/skip-ffi.git", from: "0.3.1"),
        .package(url: "https://source.skip.tools/skip-unit.git", from: "0.5.0"),
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
        .target(name: "SkipSQLPlus", dependencies: [
            "SkipSQL",
            "SQLExt",
        ], plugins: [.plugin(name: "skipstone", package: "skip")]),
        .testTarget(name: "SkipSQLPlusTests", dependencies: [
            "SkipSQLPlus",
            .product(name: "SkipTest", package: "skip")
        ], plugins: [.plugin(name: "skipstone", package: "skip")]),
        .target(name: "SQLExt", dependencies: [
            .product(name: "SkipUnit", package: "skip-unit")
        ], sources: ["sqlcipher", "libtomcrypt"],
            publicHeadersPath: "sqlcipher",
            cSettings: [
                .headerSearchPath("sqlcipher"),
                .headerSearchPath("libtomcrypt/headers"),
                .define("SQLITE_ENABLE_SNAPSHOT"),
                .define("SQLITE_ENABLE_FTS5"),
                .define("SQLITE_HAS_CODEC"),
                .define("SQLITE_TEMP_STORE", to: "2"),
                .define("SQLCIPHER_CRYPTO_LIBTOMCRYPT"),
                .unsafeFlags(["-Wno-conversion", "-Wno-ambiguous-macro"]),
            ],
            plugins: [.plugin(name: "skipstone", package: "skip")]),
        
    ]
)
