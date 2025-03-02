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

class AggregateFunctionsTests: XCTestCase {
    #if !SKIP // SkipSQLDB TODO

    func test_distinct_prependsExpressionsWithDistinctKeyword() {
        assertSQL("DISTINCT \"int\"", int.distinct)
        assertSQL("DISTINCT \"intOptional\"", intOptional.distinct)
        assertSQL("DISTINCT \"double\"", double.distinct)
        assertSQL("DISTINCT \"doubleOptional\"", doubleOptional.distinct)
        assertSQL("DISTINCT \"string\"", string.distinct)
        assertSQL("DISTINCT \"stringOptional\"", stringOptional.distinct)
    }

    func test_count_wrapsOptionalExpressionsWithCountFunction() {
        assertSQL("count(\"intOptional\")", intOptional.count)
        assertSQL("count(\"doubleOptional\")", doubleOptional.count)
        assertSQL("count(\"stringOptional\")", stringOptional.count)
    }

    func test_max_wrapsComparableExpressionsWithMaxFunction() {
        assertSQL("max(\"int\")", int.max)
        assertSQL("max(\"intOptional\")", intOptional.max)
        assertSQL("max(\"double\")", double.max)
        assertSQL("max(\"doubleOptional\")", doubleOptional.max)
        assertSQL("max(\"string\")", string.max)
        assertSQL("max(\"stringOptional\")", stringOptional.max)
        assertSQL("max(\"date\")", date.max)
        assertSQL("max(\"dateOptional\")", dateOptional.max)
    }

    func test_min_wrapsComparableExpressionsWithMinFunction() {
        assertSQL("min(\"int\")", int.min)
        assertSQL("min(\"intOptional\")", intOptional.min)
        assertSQL("min(\"double\")", double.min)
        assertSQL("min(\"doubleOptional\")", doubleOptional.min)
        assertSQL("min(\"string\")", string.min)
        assertSQL("min(\"stringOptional\")", stringOptional.min)
        assertSQL("min(\"date\")", date.min)
        assertSQL("min(\"dateOptional\")", dateOptional.min)
    }

    func test_average_wrapsNumericExpressionsWithAvgFunction() {
        assertSQL("avg(\"int\")", int.average)
        assertSQL("avg(\"intOptional\")", intOptional.average)
        assertSQL("avg(\"double\")", double.average)
        assertSQL("avg(\"doubleOptional\")", doubleOptional.average)
    }

    func test_sum_wrapsNumericExpressionsWithSumFunction() {
        assertSQL("sum(\"int\")", int.sum)
        assertSQL("sum(\"intOptional\")", intOptional.sum)
        assertSQL("sum(\"double\")", double.sum)
        assertSQL("sum(\"doubleOptional\")", doubleOptional.sum)
    }

    func test_total_wrapsNumericExpressionsWithTotalFunction() {
        assertSQL("total(\"int\")", int.total)
        assertSQL("total(\"intOptional\")", intOptional.total)
        assertSQL("total(\"double\")", double.total)
        assertSQL("total(\"doubleOptional\")", doubleOptional.total)
    }

    func test_count_withStar_wrapsStarWithCountFunction() {
        assertSQL("count(*)", count(*))
    }
    #endif
}
