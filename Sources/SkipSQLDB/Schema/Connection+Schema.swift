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

#if !SKIP // SkipSQLDB TODO

public extension Connection {
    var schema: SchemaReader { SchemaReader(connection: self) }

    // There are four columns in each result row.
    // The first column is the name of the table that
    // contains the REFERENCES clause.
    // The second column is the rowid of the row that contains the
    // invalid REFERENCES clause, or NULL if the child table is a WITHOUT ROWID table.
    // The third column is the name of the table that is referred to.
    // The fourth column is the index of the specific foreign key constraint that failed.
    //
    // https://sqlite.org/pragma.html#pragma_foreign_key_check
    func foreignKeyCheck(table: String? = nil) throws -> [ForeignKeyError] {
        try run("PRAGMA foreign_key_check" + (table.map { "(\($0.quote()))" } ?? ""))
            .compactMap { (row: [Binding?]) -> ForeignKeyError? in
                guard let table = row[0] as? String,
                      let rowId = row[1] as? Int64,
                      let target = row[2] as? String else { return nil }

                return ForeignKeyError(from: table, rowId: rowId, to: target)
            }
    }

    // This pragma does a low-level formatting and consistency check of the database.
    // https://sqlite.org/pragma.html#pragma_integrity_check
    func integrityCheck(table: String? = nil) throws -> [String] {
        precondition(table == nil || supports(.partialIntegrityCheck), "partial integrity check not supported")

        return try run("PRAGMA integrity_check" + (table.map { "(\($0.quote()))" } ?? ""))
            .compactMap { $0[0] as? String }
            .filter { $0 != "ok" }
    }
}
#endif

