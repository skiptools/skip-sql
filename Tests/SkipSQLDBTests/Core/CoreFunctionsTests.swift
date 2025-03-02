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

class CoreFunctionsTests: XCTestCase {

    func test_round_wrapsDoubleExpressionsWithRoundFunction() {
        assertSQL("round(\"double\")", double.round())
        assertSQL("round(\"doubleOptional\")", doubleOptional.round())

        assertSQL("round(\"double\", 1)", double.round(1))
        assertSQL("round(\"doubleOptional\", 2)", doubleOptional.round(2))
    }

    func test_random_generatesExpressionWithRandomFunction() {
        assertSQL("random()", SQLExpression<Int64>.random())
        assertSQL("random()", SQLExpression<Int>.random())
    }

    func test_length_wrapsStringExpressionWithLengthFunction() {
        assertSQL("length(\"string\")", string.length)
        assertSQL("length(\"stringOptional\")", stringOptional.length)
    }

    func test_lowercaseString_wrapsStringExpressionWithLowerFunction() {
        assertSQL("lower(\"string\")", string.lowercaseString)
        assertSQL("lower(\"stringOptional\")", stringOptional.lowercaseString)
    }

    func test_uppercaseString_wrapsStringExpressionWithUpperFunction() {
        assertSQL("upper(\"string\")", string.uppercaseString)
        assertSQL("upper(\"stringOptional\")", stringOptional.uppercaseString)
    }

    func test_like_buildsExpressionWithLikeOperator() {
        assertSQL("(\"string\" LIKE 'a%')", string.like("a%"))
        assertSQL("(\"stringOptional\" LIKE 'b%')", stringOptional.like("b%"))

        assertSQL("(\"string\" LIKE '%\\%' ESCAPE '\\')", string.like("%\\%", escape: "\\"))
        assertSQL("(\"stringOptional\" LIKE '_\\_' ESCAPE '\\')", stringOptional.like("_\\_", escape: "\\"))

        assertSQL("(\"string\" LIKE \"a\")", string.like(SQLExpression<String>("a")))
        assertSQL("(\"stringOptional\" LIKE \"a\")", stringOptional.like(SQLExpression<String>("a")))

        assertSQL("(\"string\" LIKE \"a\" ESCAPE '\\')", string.like(SQLExpression<String>("a"), escape: "\\"))
        assertSQL("(\"stringOptional\" LIKE \"a\" ESCAPE '\\')", stringOptional.like(SQLExpression<String>("a"), escape: "\\"))

        assertSQL("('string' LIKE \"a\")", "string".like(SQLExpression<String>("a")))
        assertSQL("('string' LIKE \"a\" ESCAPE '\\')", "string".like(SQLExpression<String>("a"), escape: "\\"))
    }

    func test_glob_buildsExpressionWithGlobOperator() {
        assertSQL("(\"string\" GLOB 'a*')", string.glob("a*"))
        assertSQL("(\"stringOptional\" GLOB 'b*')", stringOptional.glob("b*"))
    }

    func test_match_buildsExpressionWithMatchOperator() {
        assertSQL("(\"string\" MATCH 'a*')", string.match("a*"))
        assertSQL("(\"stringOptional\" MATCH 'b*')", stringOptional.match("b*"))
    }

    func test_regexp_buildsExpressionWithRegexpOperator() {
        assertSQL("(\"string\" REGEXP '^.+@.+\\.com$')", string.regexp("^.+@.+\\.com$"))
        assertSQL("(\"stringOptional\" REGEXP '^.+@.+\\.net$')", stringOptional.regexp("^.+@.+\\.net$"))
    }

    func test_collate_buildsExpressionWithCollateOperator() {
        assertSQL("(\"string\" COLLATE BINARY)", string.collate(Collation.binary))
        assertSQL("(\"string\" COLLATE NOCASE)", string.collate(Collation.nocase))
        assertSQL("(\"string\" COLLATE RTRIM)", string.collate(Collation.rtrim))
        assertSQL("(\"string\" COLLATE \"CUSTOM\")", string.collate(Collation.custom("CUSTOM")))

        assertSQL("(\"stringOptional\" COLLATE BINARY)", stringOptional.collate(Collation.binary))
        assertSQL("(\"stringOptional\" COLLATE NOCASE)", stringOptional.collate(Collation.nocase))
        assertSQL("(\"stringOptional\" COLLATE RTRIM)", stringOptional.collate(Collation.rtrim))
        assertSQL("(\"stringOptional\" COLLATE \"CUSTOM\")", stringOptional.collate(Collation.custom("CUSTOM")))
    }

    func test_ltrim_wrapsStringWithLtrimFunction() {
        assertSQL("ltrim(\"string\")", string.ltrim())
        assertSQL("ltrim(\"stringOptional\")", stringOptional.ltrim())

        assertSQL("ltrim(\"string\", ' ')", string.ltrim([" "]))
        assertSQL("ltrim(\"stringOptional\", ' ')", stringOptional.ltrim([" "]))
    }

    func test_ltrim_wrapsStringWithRtrimFunction() {
        assertSQL("rtrim(\"string\")", string.rtrim())
        assertSQL("rtrim(\"stringOptional\")", stringOptional.rtrim())

        assertSQL("rtrim(\"string\", ' ')", string.rtrim([" "]))
        assertSQL("rtrim(\"stringOptional\", ' ')", stringOptional.rtrim([" "]))
    }

    func test_ltrim_wrapsStringWithTrimFunction() {
        assertSQL("trim(\"string\")", string.trim())
        assertSQL("trim(\"stringOptional\")", stringOptional.trim())

        assertSQL("trim(\"string\", ' ')", string.trim([" "]))
        assertSQL("trim(\"stringOptional\", ' ')", stringOptional.trim([" "]))
    }

    func test_replace_wrapsStringWithReplaceFunction() {
        assertSQL("replace(\"string\", '@example.com', '@example.net')", string.replace("@example.com", with: "@example.net"))
        assertSQL("replace(\"stringOptional\", '@example.net', '@example.com')", stringOptional.replace("@example.net", with: "@example.com"))
    }

    func test_substring_wrapsStringWithSubstrFunction() {
        assertSQL("substr(\"string\", 1, 2)", string.substring(1, length: 2))
        assertSQL("substr(\"stringOptional\", 2, 1)", stringOptional.substring(2, length: 1))
    }

    func test_subscriptWithRange_wrapsStringWithSubstrFunction() {
        assertSQL("substr(\"string\", 1, 2)", string[1..<3])
        assertSQL("substr(\"stringOptional\", 2, 1)", stringOptional[2..<3])
    }

    func test_nilCoalescingOperator_wrapsOptionalsWithIfnullFunction() {
        assertSQL("ifnull(\"intOptional\", 1)", intOptional ?? 1)
        // AssertSQL("ifnull(\"doubleOptional\", 1.0)", doubleOptional ?? 1) // rdar://problem/21677256
        XCTAssertEqual("ifnull(\"doubleOptional\", 1.0)", (doubleOptional ?? 1).asSQL())
        assertSQL("ifnull(\"stringOptional\", 'literal')", stringOptional ?? "literal")

        assertSQL("ifnull(\"intOptional\", \"int\")", intOptional ?? int)
        assertSQL("ifnull(\"doubleOptional\", \"double\")", doubleOptional ?? double)
        assertSQL("ifnull(\"stringOptional\", \"string\")", stringOptional ?? string)

        assertSQL("ifnull(\"intOptional\", \"intOptional\")", intOptional ?? intOptional)
        assertSQL("ifnull(\"doubleOptional\", \"doubleOptional\")", doubleOptional ?? doubleOptional)
        assertSQL("ifnull(\"stringOptional\", \"stringOptional\")", stringOptional ?? stringOptional)
    }

    func test_absoluteValue_wrapsNumberWithAbsFucntion() {
        assertSQL("abs(\"int\")", int.absoluteValue)
        assertSQL("abs(\"intOptional\")", intOptional.absoluteValue)

        assertSQL("abs(\"double\")", double.absoluteValue)
        assertSQL("abs(\"doubleOptional\")", doubleOptional.absoluteValue)
    }

    func test_contains_buildsExpressionWithInOperator() {
        assertSQL("(\"string\" IN ('hello', 'world'))", ["hello", "world"].contains(string))
        assertSQL("(\"stringOptional\" IN ('hello', 'world'))", ["hello", "world"].contains(stringOptional))
    }

}
