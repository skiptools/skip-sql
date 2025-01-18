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
import SkipSQL
@testable import SkipSQLDB

#if false // SkipSQLDB TODO

class FTSIntegrationTests: SQLiteTestCase {
    let email = SQLExpression<String>("email")
    let index = VirtualTable("index")

    private func createIndex() throws {
        try createOrSkip { db in
            try db.run(index.create(.FTS5(
                FTS5Config()
                    .column(email)
                    .tokenizer(.Unicode61()))
            ))
        }

        for user in try db.prepare(users) {
            try db.run(index.insert(email <- user[email]))
        }
    }

    private func createTrigramIndex() throws {
        try createOrSkip { db in
            try db.run(index.create(.FTS5(
                FTS5Config()
                  .column(email)
                  .tokenizer(.Trigram(caseSensitive: false)))
            ))
        }

        for user in try db.prepare(users) {
            try db.run(index.insert(email <- user[email]))
        }
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        try createUsersTable()
        try insertUsers("John", "Paul", "George", "Ringo")
    }

    func testMatch() throws {
        try createIndex()
        let matches = Array(try db.prepare(index.match("Paul")))
        XCTAssertEqual(matches.map { $0[email ]}, ["Paul@example.com"])
    }

    func testMatchPartial() throws {
        try insertUsers("Paula")
        try createIndex()
        let matches = Array(try db.prepare(index.match("Pa*")))
        XCTAssertEqual(matches.map { $0[email ]}, ["Paul@example.com", "Paula@example.com"])
    }

    func testTrigramIndex() throws {
        try createTrigramIndex()
        let matches = Array(try db.prepare(index.match("Paul")))
        XCTAssertEqual(1, matches.count)
    }

    private func createOrSkip(_ createIndex: (Connection) throws -> Void) throws {
        do {
            try createIndex(db)
        } catch let error as Result {
            try XCTSkipIf(error.description.starts(with: "no such module:") ||
                          error.description.starts(with: "parse error")
            )
            throw error
        }
    }
}
#endif

