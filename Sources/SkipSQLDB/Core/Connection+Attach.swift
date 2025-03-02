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
import Foundation
import SkipSQL
=======
import Foundation
#if SQLITE_SWIFT_STANDALONE
import sqlite3
#elseif SQLITE_SWIFT_SQLCIPHER
import SQLCipher
#elseif os(Linux) || os(Windows) || os(Android)
import CSQLite
#else
import SQLite3
#endif
>>>>>>> d0c842f (Add SkipSQLDB module)

extension Connection {
    #if SQLITE_SWIFT_SQLCIPHER
    /// See https://www.zetetic.net/sqlcipher/sqlcipher-api/#attach
    public func attach(_ location: Location, as schemaName: String, key: String? = nil) throws {
        if let key {
            try run("ATTACH DATABASE ? AS ? KEY ?", location.description, schemaName, key)
        } else {
            try run("ATTACH DATABASE ? AS ?", location.description, schemaName)
        }
    }
    #else
    /// See  https://www3.sqlite.org/lang_attach.html
    public func attach(_ location: Location, as schemaName: String) throws {
        try run("ATTACH DATABASE ? AS ?", location.description, schemaName)
    }
    #endif

    /// See https://www3.sqlite.org/lang_detach.html
    public func detach(_ schemaName: String) throws {
        try run("DETACH DATABASE ?", schemaName)
    }
}
