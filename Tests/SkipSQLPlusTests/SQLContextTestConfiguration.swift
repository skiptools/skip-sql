// Copyright 2023–2026 Skip
// SPDX-License-Identifier: MPL-2.0
import SkipSQLPlus

extension SQLiteConfiguration {
    /// The shared SQLContextTests uses thus local variable to determine the configuration to use
    public static let test = SQLiteConfiguration.plus
}

func SQLContextTest(path: String? = nil, flags: SQLContext.OpenFlags? = nil) throws -> SQLContext {
    if let path {
        return try SQLContext(path: path, flags: flags, configuration: .test)
    } else {
        return SQLContext(configuration: SQLiteConfiguration.test)
    }
}
