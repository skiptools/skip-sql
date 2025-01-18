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

class DateAndTimeFunctionsTests: XCTestCase {

    func test_date() {
        assertSQL("date('now')", DateFunctions.date("now"))
        assertSQL("date('now', 'localtime')", DateFunctions.date("now", "localtime"))
    }

    func test_time() {
        assertSQL("time('now')", DateFunctions.time("now"))
        assertSQL("time('now', 'localtime')", DateFunctions.time("now", "localtime"))
    }

    func test_datetime() {
        assertSQL("datetime('now')", DateFunctions.datetime("now"))
        assertSQL("datetime('now', 'localtime')", DateFunctions.datetime("now", "localtime"))
    }

    func test_julianday() {
        assertSQL("julianday('now')", DateFunctions.julianday("now"))
        assertSQL("julianday('now', 'localtime')", DateFunctions.julianday("now", "localtime"))
    }

    func test_strftime() {
        assertSQL("strftime('%Y-%m-%d', 'now')", DateFunctions.strftime("%Y-%m-%d", "now"))
        assertSQL("strftime('%Y-%m-%d', 'now', 'localtime')", DateFunctions.strftime("%Y-%m-%d", "now", "localtime"))
    }
}

class DateExtensionTests: XCTestCase {
    func test_time() {
        assertSQL("time('1970-01-01T00:00:00.000')", Date(timeIntervalSince1970: 0).time)
    }

    func test_date() {
        assertSQL("date('1970-01-01T00:00:00.000')", Date(timeIntervalSince1970: 0).date)
    }

    func test_datetime() {
        assertSQL("datetime('1970-01-01T00:00:00.000')", Date(timeIntervalSince1970: 0).datetime)
    }

    func test_julianday() {
        assertSQL("julianday('1970-01-01T00:00:00.000')", Date(timeIntervalSince1970: 0).julianday)
    }
}

class DateExpressionTests: XCTestCase {
    func test_date() {
        assertSQL("date(\"date\")", date.date)
    }

    func test_time() {
        assertSQL("time(\"date\")", date.time)
    }

    func test_datetime() {
        assertSQL("datetime(\"date\")", date.datetime)
    }

    func test_julianday() {
        assertSQL("julianday(\"date\")", date.julianday)
    }
}
