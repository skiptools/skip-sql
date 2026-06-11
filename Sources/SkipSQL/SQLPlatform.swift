// Copyright 2023–2026 Skip
// SPDX-License-Identifier: MPL-2.0
@_exported import SkipSQLCore

extension SQLiteConfiguration {
    /// The platform-provided SQLite library.
    ///
    /// This will use the the vendored sqlite libraries that are provided by the operating system.
    /// The version will vary depending on the OS version.
    nonisolated(unsafe) public static let platform: SQLiteConfiguration = {
        #if SKIP
        SQLiteConfiguration(library: SQLiteJNALibrary.shared)
        #elseif canImport(SQLite3)
        SQLiteConfiguration(library: SQLiteCLibrary.shared)
        #else
        // on Android you need to use SQLPlus
        fatalError("no platform SQLiteCLibrary available; use SkipSQLPlus instead")
        #endif
    }()
}
