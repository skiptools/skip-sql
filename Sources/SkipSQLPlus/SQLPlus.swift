// Copyright 2023 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception

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
