// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

import SkipSQL

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
