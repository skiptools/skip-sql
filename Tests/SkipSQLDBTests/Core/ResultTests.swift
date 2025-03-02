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
import XCTest
import Foundation
@testable import SkipSQLDB
import SkipSQL

class ResultTests: XCTestCase {
    var connection: Connection!

    // SKIP DECLARE: override fun setUp()
    override func setUpWithError() throws {
        connection = try Connection(.inMemory)
    }

    func test_init_with_ok_code_returns_nil() {
        XCTAssertNil(SQLResult(errorCode: SQLITE_OK, connection: connection, statement: nil) as SQLResult?)
    }

    func test_init_with_row_code_returns_nil() {
        XCTAssertNil(SQLResult(errorCode: SQLITE_ROW, connection: connection, statement: nil) as SQLResult?)
    }

    func test_init_with_done_code_returns_nil() {
        XCTAssertNil(SQLResult(errorCode: SQLITE_DONE, connection: connection, statement: nil) as SQLResult?)
    }

    #if !SKIP // SkipSQLDB TODO
    func test_init_with_other_code_returns_error() {
        if case .some(.error(let message, let code, let statement)) =
            SQLResult(errorCode: SQLITE_MISUSE, connection: connection, statement: nil) {
            XCTAssertEqual("not an error", message)
            XCTAssertEqual(SQLITE_MISUSE, code)
            XCTAssertNil(statement)
            XCTAssert(connection === connection)
        } else {
            XCTFail("no error")
        }
    }
    #endif

    func test_description_contains_error_code() {
        XCTAssertEqual("not an error (code: 21)",
            SQLResult(errorCode: SQLITE_MISUSE, connection: connection, statement: nil)?.description)
    }

    func test_description_contains_statement_and_error_code() throws {
        let statement = try Statement(connection, "SELECT 1")
        XCTAssertEqual("not an error (SELECT 1) (code: 21)",
            SQLResult(errorCode: SQLITE_MISUSE, connection: connection, statement: statement)?.description)
    }

    #if !SKIP // SkipSQLDB TODO
    func test_init_extended_with_other_code_returns_error() {
        connection.usesExtendedErrorCodes = true
        if case .some(.extendedError(let message, let extendedCode, let statement)) =
            SQLResult(errorCode: SQLITE_MISUSE, connection: connection, statement: nil) {
            XCTAssertEqual("not an error", message)
            XCTAssertEqual(extendedCode, 0)
            XCTAssertNil(statement)
            XCTAssert(connection === connection)
        } else {
            XCTFail("no error")
        }
    }
    #endif
}
