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
import SkipSQL
=======
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

public enum Result: Error {

    fileprivate static let successCodes: Set = [SQLITE_OK, SQLITE_ROW, SQLITE_DONE]

    /// Represents a SQLite specific [error code](https://sqlite.org/rescode.html)
    ///
    /// - message: English-language text that describes the error
    ///
    /// - code: SQLite [error code](https://sqlite.org/rescode.html#primary_result_code_list)
    ///
    /// - statement: the statement which produced the error
    case error(message: String, code: Int32, statement: Statement?)

    /// Represents a SQLite specific [extended error code] (https://sqlite.org/rescode.html#primary_result_codes_versus_extended_result_codes)
    ///
    /// - message: English-language text that describes the error
    ///
    /// - extendedCode: SQLite [extended error code](https://sqlite.org/rescode.html#extended_result_code_list)
    ///
    /// - statement: the statement which produced the error
    case extendedError(message: String, extendedCode: Int32, statement: Statement?)

    init?(errorCode: Int32, connection: Connection, statement: Statement? = nil) {
        guard !Result.successCodes.contains(errorCode) else { return nil }

<<<<<<< HEAD
        let message = String(cString: SQLite3.sqlite3_errmsg(connection.handle)!)
=======
        let message = String(cString: sqlite3_errmsg(connection.handle))
>>>>>>> d0c842f (Add SkipSQLDB module)

        guard connection.usesExtendedErrorCodes else {
            self = .error(message: message, code: errorCode, statement: statement)
            return
        }

<<<<<<< HEAD
        let extendedErrorCode = SQLite3.sqlite3_extended_errcode(connection.handle)
=======
        let extendedErrorCode = sqlite3_extended_errcode(connection.handle)
>>>>>>> d0c842f (Add SkipSQLDB module)
        self = .extendedError(message: message, extendedCode: extendedErrorCode, statement: statement)
    }

}

extension Result: CustomStringConvertible {

    public var description: String {
        switch self {
        case let .error(message, errorCode, statement):
            if let statement {
                return "\(message) (\(statement)) (code: \(errorCode))"
            } else {
                return "\(message) (code: \(errorCode))"
            }
        case let .extendedError(message, extendedCode, statement):
            if let statement {
                return "\(message) (\(statement)) (extended code: \(extendedCode))"
            } else {
                return "\(message) (extended code: \(extendedCode))"
            }
        }
    }
}
