// Copyright 2025 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

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
@testable import SkipSQLDB

class ConnectionSchemaTests: SQLiteTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        try createUsersTable()
    }

    func test_foreignKeyCheck() throws {
        let errors = try db.foreignKeyCheck()
        XCTAssert(errors.isEmpty)
    }

    func test_foreignKeyCheck_with_table() throws {
        let errors = try db.foreignKeyCheck(table: "users")
        XCTAssert(errors.isEmpty)
    }

    func test_foreignKeyCheck_table_not_found() throws {
        XCTAssertThrowsError(try db.foreignKeyCheck(table: "xxx")) { error in
            guard case Result.error(let message, _, _) = error else {
                assertionFailure("invalid error type")
                return
            }
            XCTAssertEqual(message, "no such table: xxx")
        }
    }

    func test_integrityCheck_global() throws {
        let results = try db.integrityCheck()
        XCTAssert(results.isEmpty)
    }

    func test_partial_integrityCheck_table() throws {
        guard db.supports(.partialIntegrityCheck) else { return }
        let results = try db.integrityCheck(table: "users")
        XCTAssert(results.isEmpty)
    }

    func test_integrityCheck_table_not_found() throws {
        guard db.supports(.partialIntegrityCheck) else { return }
        XCTAssertThrowsError(try db.integrityCheck(table: "xxx")) { error in
            guard case Result.error(let message, _, _) = error else {
                assertionFailure("invalid error type")
                return
            }
            XCTAssertEqual(message, "no such table: xxx")
        }
    }
}
