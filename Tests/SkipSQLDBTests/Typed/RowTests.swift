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
@testable import SkipSQLDB

class RowTests: XCTestCase {

    public func test_get_value() throws {
        let row = Row(["\"foo\"": 0], ["value"])
        let result = try row.get(SQLExpression<String>("foo"))

        XCTAssertEqual("value", result)
    }

    public func test_get_value_subscript() {
        let row = Row(["\"foo\"": 0], ["value"])
        let result = row[SQLExpression<String>("foo")]

        XCTAssertEqual("value", result)
    }

    public func test_get_value_optional() throws {
        let row = Row(["\"foo\"": 0], ["value"])
        let result = try row.get(SQLExpression<String?>("foo"))

        XCTAssertEqual("value", result)
    }

    public func test_get_value_optional_subscript() {
        let row = Row(["\"foo\"": 0], ["value"])
        let result = row[SQLExpression<String?>("foo")]

        XCTAssertEqual("value", result)
    }

    public func test_get_value_optional_nil() throws {
        let row = Row(["\"foo\"": 0], [nil])
        let result = try row.get(SQLExpression<String?>("foo"))

        XCTAssertNil(result)
    }

    public func test_get_value_optional_nil_subscript() {
        let row = Row(["\"foo\"": 0], [nil])
        let result = row[SQLExpression<String?>("foo")]

        XCTAssertNil(result)
    }

    public func test_get_type_mismatch_throws_unexpected_null_value() {
        let row = Row(["\"foo\"": 0], ["value"])
        XCTAssertThrowsError(try row.get(SQLExpression<Int>("foo"))) { error in
            if case QueryError.unexpectedNullValue(let name) = error {
                XCTAssertEqual("\"foo\"", name)
            } else {
                XCTFail("unexpected error: \(error)")
            }
        }
    }

    public func test_get_type_mismatch_optional_returns_nil() throws {
        let row = Row(["\"foo\"": 0], ["value"])
        let result = try row.get(SQLExpression<Int?>("foo"))
        XCTAssertNil(result)
    }

    public func test_get_non_existent_column_throws_no_such_column() {
        let row = Row(["\"foo\"": 0], ["value"])
        XCTAssertThrowsError(try row.get(SQLExpression<Int>("bar"))) { error in
            if case QueryError.noSuchColumn(let name, let columns) = error {
                XCTAssertEqual("\"bar\"", name)
                XCTAssertEqual(["\"foo\""], columns)
            } else {
                XCTFail("unexpected error: \(error)")
            }
        }
    }

    public func test_get_ambiguous_column_throws() {
        let row = Row(["table1.\"foo\"": 0, "table2.\"foo\"": 1], ["value"])
        XCTAssertThrowsError(try row.get(SQLExpression<Int>("foo"))) { error in
            if case QueryError.ambiguousColumn(let name, let columns) = error {
                XCTAssertEqual("\"foo\"", name)
                XCTAssertEqual(["table1.\"foo\"", "table2.\"foo\""], columns.sorted())
            } else {
                XCTFail("unexpected error: \(error)")
            }
        }
    }

    public func test_get_datatype_throws() {
        // swiftlint:disable nesting
        let row = Row(["\"foo\"": 0], [Blob(bytes: [])])
        XCTAssertThrowsError(try row.get(SQLExpression<MyType>("foo"))) { error in
            if case MyType.MyError.failed = error {
                XCTAssertTrue(true)
            } else {
                XCTFail("unexpected error: \(error)")
            }
        }
    }

    struct MyType: Value {
        enum MyError: Error {
            case failed
        }

        public static var declaredDatatype: String {
            Blob.declaredDatatype
        }

        public static func fromDatatypeValue(_ dataValue: Blob) throws -> Data {
            throw MyError.failed
        }

        public var datatypeValue: Blob {
            return Blob(bytes: [])
        }
    }
}
