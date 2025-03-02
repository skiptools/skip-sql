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
import XCTest
import SkipSQLDB

#if false // SkipSQLDB TODO

=======
import XCTest
import SkipSQLDB

>>>>>>> d0c842f (Add SkipSQLDB module)
// https://github.com/stephencelis/SQLite.swift/issues/1071
#if !os(Linux) && !os(Android) && !os(Windows)

class CustomFunctionNoArgsTests: SQLiteTestCase {
    typealias FunctionNoOptional              = () -> SQLExpression<String>
    typealias FunctionResultOptional          = () -> SQLExpression<String?>

    func testFunctionNoOptional() throws {
        let _: FunctionNoOptional = try db.createFunction("test", deterministic: true) {
            "a"
        }
        let result = try db.prepare("SELECT test()").scalar() as! String
        XCTAssertEqual("a", result)
    }

    func testFunctionResultOptional() throws {
        let _: FunctionResultOptional = try db.createFunction("test", deterministic: true) {
            "a"
        }
        let result = try db.prepare("SELECT test()").scalar() as! String?
        XCTAssertEqual("a", result)
    }
}

class CustomFunctionWithOneArgTests: SQLiteTestCase {
    typealias FunctionNoOptional              = (SQLExpression<String>) -> SQLExpression<String>
    typealias FunctionLeftOptional            = (SQLExpression<String?>) -> SQLExpression<String>
    typealias FunctionResultOptional          = (SQLExpression<String>) -> SQLExpression<String?>
    typealias FunctionLeftResultOptional      = (SQLExpression<String?>) -> SQLExpression<String?>

    func testFunctionNoOptional() throws {
        let _: FunctionNoOptional = try db.createFunction("test", deterministic: true) { a in
            "b" + a
        }
        let result = try db.prepare("SELECT test(?)").scalar("a") as! String
        XCTAssertEqual("ba", result)
    }

    func testFunctionLeftOptional() throws {
        let _: FunctionLeftOptional = try db.createFunction("test", deterministic: true) { a in
            "b" + a!
        }
        let result = try db.prepare("SELECT test(?)").scalar("a") as! String
        XCTAssertEqual("ba", result)
    }

    func testFunctionResultOptional() throws {
        let _: FunctionResultOptional = try db.createFunction("test", deterministic: true) { a in
            "b" + a
        }
        let result = try db.prepare("SELECT test(?)").scalar("a") as! String
        XCTAssertEqual("ba", result)
    }

    func testFunctionLeftResultOptional() throws {
        let _: FunctionLeftResultOptional = try db.createFunction("test", deterministic: true) { (a: String?) -> String? in
            "b" + a!
        }
        let result = try db.prepare("SELECT test(?)").scalar("a") as! String
        XCTAssertEqual("ba", result)
    }
}

class CustomFunctionWithTwoArgsTests: SQLiteTestCase {
    typealias FunctionNoOptional              = (SQLExpression<String>, SQLExpression<String>) -> SQLExpression<String>
    typealias FunctionLeftOptional            = (SQLExpression<String?>, SQLExpression<String>) -> SQLExpression<String>
    typealias FunctionRightOptional           = (SQLExpression<String>, SQLExpression<String?>) -> SQLExpression<String>
    typealias FunctionResultOptional          = (SQLExpression<String>, SQLExpression<String>) -> SQLExpression<String?>
    typealias FunctionLeftRightOptional       = (SQLExpression<String?>, SQLExpression<String?>) -> SQLExpression<String>
    typealias FunctionLeftResultOptional      = (SQLExpression<String?>, SQLExpression<String>) -> SQLExpression<String?>
    typealias FunctionRightResultOptional     = (SQLExpression<String>, SQLExpression<String?>) -> SQLExpression<String?>
    typealias FunctionLeftRightResultOptional = (SQLExpression<String?>, SQLExpression<String?>) -> SQLExpression<String?>

    func testNoOptional() throws {
        let _: FunctionNoOptional = try db.createFunction("test", deterministic: true) { a, b in
            a + b
        }
        let result = try db.prepare("SELECT test(?, ?)").scalar("a", "b") as! String
        XCTAssertEqual("ab", result)
    }

    func testLeftOptional() throws {
        let _: FunctionLeftOptional = try db.createFunction("test", deterministic: true) { a, b in
            a! + b
        }
        let result = try db.prepare("SELECT test(?, ?)").scalar("a", "b") as! String
        XCTAssertEqual("ab", result)
    }

    func testRightOptional() throws {
        let _: FunctionRightOptional = try db.createFunction("test", deterministic: true) { a, b in
            a + b!
        }
        let result = try db.prepare("SELECT test(?, ?)").scalar("a", "b") as! String
        XCTAssertEqual("ab", result)
    }

    func testResultOptional() throws {
        let _: FunctionResultOptional = try db.createFunction("test", deterministic: true) { a, b in
            a + b
        }
        let result = try db.prepare("SELECT test(?, ?)").scalar("a", "b") as! String?
        XCTAssertEqual("ab", result)
    }

    func testFunctionLeftRightOptional() throws {
        let _: FunctionLeftRightOptional = try db.createFunction("test", deterministic: true) { a, b in
            a! + b!
        }
        let result = try db.prepare("SELECT test(?, ?)").scalar("a", "b") as! String
        XCTAssertEqual("ab", result)
    }

    func testFunctionLeftResultOptional() throws {
        let _: FunctionLeftResultOptional = try db.createFunction("test", deterministic: true) { a, b in
            a! + b
        }
        let result = try db.prepare("SELECT test(?, ?)").scalar("a", "b") as! String?
        XCTAssertEqual("ab", result)
    }

    func testFunctionRightResultOptional() throws {
        let _: FunctionRightResultOptional = try db.createFunction("test", deterministic: true) { a, b in
            a + b!
        }
        let result = try db.prepare("SELECT test(?, ?)").scalar("a", "b") as! String?
        XCTAssertEqual("ab", result)
    }

    func testFunctionLeftRightResultOptional() throws {
        let _: FunctionLeftRightResultOptional = try db.createFunction("test", deterministic: true) { a, b in
            a! + b!
        }
        let result = try db.prepare("SELECT test(?, ?)").scalar("a", "b") as! String?
        XCTAssertEqual("ab", result)
    }
}

class CustomFunctionTruncation: SQLiteTestCase {
    // https://github.com/stephencelis/SQLite.swift/issues/468
    func testStringTruncation() throws {
        _ = try db.createFunction("customLower") { (value: String) in value.lowercased() }
        let result = try db.prepare("SELECT customLower(?)").scalar("TÖL-AA 12") as? String
        XCTAssertEqual("töl-aa 12", result)
    }
}

#endif
<<<<<<< HEAD

#endif

=======
>>>>>>> d0c842f (Add SkipSQLDB module)
