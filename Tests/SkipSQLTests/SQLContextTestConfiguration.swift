// Copyright 2023–2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
import SkipSQL
import XCTest

extension SQLiteConfiguration {
    /// The shared SQLContextTests uses thus local variable to determine the configuration to use
    public static let test = SQLiteConfiguration.platform
}

func SQLContextTest() throws -> SQLContext {
    #if !canImport(SQLite3)
    throw XCTSkip("SQLite is not available on platform")
    #else
    return SQLContext(configuration: .test)
    #endif
}
