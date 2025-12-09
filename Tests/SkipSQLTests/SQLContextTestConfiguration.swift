// Copyright 2023–2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
import SkipSQL
import SkipSQLCore
import XCTest

extension SQLiteConfiguration {
    /// The shared SQLContextTests uses thus local variable to determine the configuration to use
    public static let test = SQLiteConfiguration.platform
}

func SQLContextTest(path: String? = nil, flags: SQLContext.OpenFlags? = nil) throws -> SQLContext {
    #if !canImport(SQLite3)
    throw XCTSkip("SQLite is not available on platform")
    #endif
    if let path {
        return try SQLContext(path: path, flags: flags, configuration: .test)
    } else {
        return SQLContext(configuration: SQLiteConfiguration.test)
    }
}
