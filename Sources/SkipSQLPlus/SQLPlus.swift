// Copyright 2023–2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
@_exported import SkipSQL

extension SQLiteConfiguration {
    /// The platform-provided SQLite library.
    ///
    /// This will use the the vendored sqlite libraries that are provided by the operating system.
    /// The version will vary.
    public static let plus: SQLiteConfiguration = {
        #if SKIP
        SQLiteConfiguration(library: SQLPlusJNALibrary.shared)
        #else
        SQLiteConfiguration(library: SQLPlusCLibrary.shared)
        #endif
    }()
}

public extension SQLContext {
    /// Set the key on this SQLCipher database using the `PRAGMA KEY =` statement.
    func key(_ key: String, rekey: Bool = false) throws {
        try exec(sql: "PRAGMA \(rekey ? "REKEY": "KEY") = \(quoteSingle(key))")
    }

    func export(_ location: String, key: String) throws {
        let schemaName = "cipher_export"

        try attach(location: location, as: schemaName, key: key)
        try exec(sql: "SELECT sqlcipher_export(?)", parameters: [SQLValue(schemaName)])
        try detach(schemaName)
    }

    func attach(location path: String, as schemaName: String, key: String? = nil) throws {
        if let key {
            try exec(sql: "ATTACH DATABASE ? AS ? KEY ?", parameters: [SQLValue(path), SQLValue(schemaName), SQLValue(key)])
        } else {
            try exec(sql: "ATTACH DATABASE ? AS ?", parameters: [SQLValue(path), SQLValue(schemaName)])
        }
    }

    func detach(_ schemaName: String) throws {
        try exec(sql: "DETACH DATABASE ?", parameters: [SQLValue(schemaName)])
    }
}
