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

#if !SKIP // SkipSQLDB TODO
class ConnectionAttachTests: SQLiteTestCase {
    func test_attach_detach_memory_database() throws {
        let schemaName = "test"

        try db.attach(.inMemory, as: schemaName)

        let table = Table("attached_users", database: schemaName)
        let name = SQLExpression<String>("string")

        // create a table, insert some data
        try db.run(table.create { builder in
            builder.column(name)
        })
        _ = try db.run(table.insert(name <- "test"))

        // query data
        let rows = try db.prepare(table.select(name)).map { $0[name] }
        XCTAssertEqual(["test"], rows)

        try db.detach(schemaName)
    }

    #if !os(Windows) // fails on Windows for some reason, maybe due to URI parameter (because test_init_with_Uri_and_Parameters fails too)
    func test_attach_detach_file_database() throws {
        let schemaName = "test"
        let testDb = fixture("test", withExtension: "sqlite")

        try db.attach(.uri(testDb, parameters: [.mode(.readOnly)]), as: schemaName)

        let table = Table("tests", database: schemaName)
        let email = SQLExpression<String>("email")

        let rows = try db.prepare(table.select(email)).map { $0[email] }
        XCTAssertEqual(["foo@bar.com"], rows)

        try db.detach(schemaName)
    }
    #endif

    func test_detach_invalid_schema_name_errors_with_no_such_database() throws {
        XCTAssertThrowsError(try db.detach("no-exist")) { error in
            if case let SQLResult.error(message, code, _) = error {
                XCTAssertEqual(code, SQLITE_ERROR)
                XCTAssertEqual("no such database: no-exist", message)
            } else {
                XCTFail("unexpected error: \(error)")
            }
        }
    }
}
#endif

