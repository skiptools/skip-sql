// Copyright 2023–2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
@_exported import SkipSQLCore

extension SQLiteConfiguration {
    /// The platform-provided SQLite library.
    ///
    /// This will use the the vendored sqlite libraries that are provided by the operating system.
    /// The version will vary depending on the OS version.
    public static let platform: SQLiteConfiguration = {
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
