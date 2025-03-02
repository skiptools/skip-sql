<<<<<<< HEAD
// Copyright 2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception

// This code is adapted from the SQLite.swift project, with the following license:

// SQLite.swift
// https://github.com/stephencelis/SQLite.swift
// Copyright © 2014-2015 Stephen Celis.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
=======
>>>>>>> d0c842f (Add SkipSQLDB module)
import Foundation

public typealias UserVersion = Int32

public extension Connection {
    /// The user version of the database.
    /// See SQLite [PRAGMA user_version](https://sqlite.org/pragma.html#pragma_user_version)
    var userVersion: UserVersion? {
        get {
            (try? scalar("PRAGMA user_version") as? Int64)?.map(Int32.init)
        }
        set {
            _ = try? run("PRAGMA user_version = \(newValue ?? 0)")
        }
    }

    /// The version of SQLite.
    /// See SQLite [sqlite_version()](https://sqlite.org/lang_corefunc.html#sqlite_version)
    var sqliteVersion: SQLiteVersion {
        guard let version = (try? scalar("SELECT sqlite_version()")) as? String,
<<<<<<< HEAD
              let splits = Optional(version.split(separator: ".", maxSplits: 3)), splits.count == 3,
=======
              let splits = .some(version.split(separator: ".", maxSplits: 3)), splits.count == 3,
>>>>>>> d0c842f (Add SkipSQLDB module)
              let major = Int(splits[0]), let minor = Int(splits[1]), let point = Int(splits[2]) else {
            return .zero
        }
        return .init(major: major, minor: minor, point: point)
    }

    // Changing the foreign_keys setting affects the execution of all statements prepared using the database
    // connection, including those prepared before the setting was changed.
    //
    // https://sqlite.org/pragma.html#pragma_foreign_keys
    var foreignKeys: Bool {
        get { getBoolPragma("foreign_keys") }
        set { setBoolPragma("foreign_keys", newValue) }
    }

    var deferForeignKeys: Bool {
        get { getBoolPragma("defer_foreign_keys") }
        set { setBoolPragma("defer_foreign_keys", newValue) }
    }

    private func getBoolPragma(_ key: String) -> Bool {
        guard let binding = try? scalar("PRAGMA \(key)"),
              let intBinding = binding as? Int64 else { return false }
        return intBinding == 1
    }

    private func setBoolPragma(_ key: String, _ newValue: Bool) {
        _ = try? run("PRAGMA \(key) = \(newValue ? "1" : "0")")
    }
}
