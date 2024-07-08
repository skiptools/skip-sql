// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "skip-sql",
    defaultLocalization: "en",
    platforms: [.iOS(.v16), .macOS(.v13), .tvOS(.v16), .watchOS(.v9), .macCatalyst(.v16)],
    products: [
        .library(name: "SkipSQL", type: .dynamic, targets: ["SkipSQL"]),
        .library(name: "SkipSQLPlus", type: .dynamic, targets: ["SkipSQLPlus"]),
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "0.9.4"),
        .package(url: "https://source.skip.tools/skip-foundation.git", from: "0.7.0"),
        .package(url: "https://source.skip.tools/skip-ffi.git", from: "0.3.3"),
        .package(url: "https://source.skip.tools/skip-ltc.git", from: "0.0.3"),
        .package(url: "https://source.skip.tools/skip-unit.git", from: "0.8.1"),
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
            .product(name: "SkipLTC", package: "skip-ltc"),
            .product(name: "SkipUnit", package: "skip-unit")
        ], sources: ["sqlite"],
            publicHeadersPath: "sqlite",
            cSettings: [
                .headerSearchPath("sqlite"),
                .define("SQLITE_DQS", to: "0"),
                .define("SQLITE_ENABLE_API_ARMOR"),
                .define("SQLITE_ENABLE_COLUMN_METADATA"),
                .define("SQLITE_ENABLE_DBSTAT_VTAB"),
                .define("SQLITE_ENABLE_FTS3"),
                .define("SQLITE_ENABLE_FTS3_PARENTHESIS"),
                .define("SQLITE_ENABLE_FTS3_TOKENIZER"),
                .define("SQLITE_ENABLE_FTS4"),
                .define("SQLITE_ENABLE_FTS5"),
                .define("SQLITE_ENABLE_MEMORY_MANAGEMENT"),
                .define("SQLITE_ENABLE_PREUPDATE_HOOK"),
                .define("SQLITE_ENABLE_RTREE"),
                .define("SQLITE_ENABLE_SESSION"),
                .define("SQLITE_ENABLE_STMTVTAB"),
                .define("SQLITE_ENABLE_UNKNOWN_SQL_FUNCTION"),
                .define("SQLITE_ENABLE_UNLOCK_NOTIFY"),
                .define("SQLITE_MAX_VARIABLE_NUMBER", to: "250000"),
                .define("SQLITE_LIKE_DOESNT_MATCH_BLOBS"),
                .define("SQLITE_OMIT_DEPRECATED"),
                .define("SQLITE_OMIT_SHARED_CACHE"),
                .define("SQLITE_SECURE_DELETE"),
                .define("SQLITE_THREADSAFE", to: "2"),
                .define("SQLITE_USE_URI"),
                .define("SQLITE_ENABLE_SNAPSHOT"),
                .define("SQLITE_HAS_CODEC"),
                .define("SQLITE_TEMP_STORE", to: "2"),
                .define("HAVE_GETHOSTUUID", to: "0"),
                .define("SQLCIPHER_CRYPTO_LIBTOMCRYPT"),
                //.unsafeFlags(["-Wno-shorten-64-to-32", "-Wno-ambiguous-macro"]), // enabled manually in libs
            ],
            plugins: [.plugin(name: "skipstone", package: "skip")]),
        
    ]
)
