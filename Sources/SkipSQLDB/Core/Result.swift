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
import SkipFFI

@available(*, deprecated, renamed: "SQLResult")
public typealias Result = SQLResult

public enum SQLResult: Error {

    fileprivate static let successCodes: Set<Int32> = [SQLITE_OK, SQLITE_ROW, SQLITE_DONE]

    /// Represents a SQLite specific [error code](https://sqlite.org/rescode.html)
    ///
    /// - message: English-language text that describes the error
    ///
    /// - code: SQLite [error code](https://sqlite.org/rescode.html#primary_result_code_list)
    ///
    /// - statement: the statement which produced the error
    case error(msg: String, code: Int32, statement: Statement?)

    /// Represents a SQLite specific [extended error code] (https://sqlite.org/rescode.html#primary_result_codes_versus_extended_result_codes)
    ///
    /// - message: English-language text that describes the error
    ///
    /// - extendedCode: SQLite [extended error code](https://sqlite.org/rescode.html#extended_result_code_list)
    ///
    /// - statement: the statement which produced the error
    case extendedError(msg: String, extendedCode: Int32, statement: Statement?)

    init?(errorCode: Int32, connection: Connection, statement: Statement? = nil) {
        guard !SQLResult.successCodes.contains(errorCode) else { return nil }

        guard let msgPtr = SQLite3.sqlite3_errmsg(connection.handle) else {
            return nil
        }

        let message = String(cString: msgPtr)

        if !connection.usesExtendedErrorCodes {
            self = .error(msg: message, code: errorCode, statement: statement)
        } else {
            let extendedErrorCode = SQLite3.sqlite3_extended_errcode(connection.handle)
            self = .extendedError(msg: message, extendedCode: extendedErrorCode, statement: statement)
        }
    }

}

extension SQLResult: CustomStringConvertible {

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
