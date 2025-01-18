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
import SkipSQL

class StatementTests: SQLiteTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        try createUsersTable()
    }

    func test_cursor_to_blob() throws {
        try insertUsers("alice")
        let statement = try db.prepare("SELECT email FROM users")
        XCTAssert(try statement.step())
        let blob = statement.row[0] as Blob
        XCTAssertEqual("alice@example.com", String(bytes: blob.bytes, encoding: .utf8)!)
    }

    func test_zero_sized_blob_returns_null() throws {
        let blobs = Table("blobs")
        let blobColumn = SQLExpression<Blob>("blob_column")
        try db.run(blobs.create { $0.column(blobColumn) })
        try db.run(blobs.insert(blobColumn <- Blob(bytes: [])))
        let blobValue = try db.scalar(blobs.select(blobColumn).limit(1, offset: 0))
        XCTAssertEqual([], blobValue.bytes)
    }

    func test_prepareRowIterator() throws {
        let names = ["a", "b", "c"]
        try insertUsers(names)

        let emailColumn = SQLExpression<String>("email")
        let statement = try db.prepare("SELECT email FROM users")
        let emails = try statement.prepareRowIterator().map { $0[emailColumn] }

        XCTAssertEqual(names.map({ "\($0)@example.com" }), emails.sorted())
    }

    /// Check that a statement reset will close the implicit transaction, allowing wal file to checkpoint
    func test_reset_statement() throws {
        // insert single row
        try insertUsers("bob")

        // prepare a statement and read a single row. This will increment the cursor which
        // prevents the implicit transaction from closing.
        // https://www.sqlite.org/lang_transaction.html#implicit_versus_explicit_transactions
        let statement = try db.prepare("SELECT email FROM users")
        _ = try statement.step()

        // verify implicit transaction is not closed, and the users table is still locked
        XCTAssertThrowsError(try db.run("DROP TABLE users")) { error in
            if case let Result.error(_, code, _) = error {
                XCTAssertEqual(code, SQLITE_LOCKED)
            } else {
                XCTFail("unexpected error")
            }
        }

        // reset the prepared statement, unlocking the table and allowing the implicit transaction to close
        statement.reset()

        // truncate succeeds
        try db.run("DROP TABLE users")
    }
}
