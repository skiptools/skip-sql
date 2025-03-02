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

class FoundationTests: XCTestCase {
    func testDataFromBlob() {
        let data = Data([1, 2, 3])
        let blob = data.datatypeValue
        XCTAssertEqual([1, 2, 3], blob.bytes)
    }

    func testBlobToData() {
        let blob = Blob(bytes: [1, 2, 3])
        let data = Data.fromDatatypeValue(blob)
        XCTAssertEqual(Data([1, 2, 3]), data)
    }

    func testStringFromUUID() {
        let uuid = UUID(uuidString: "4ABE10C9-FF12-4CD4-90C1-4B429001BAD3")!
        let string = uuid.datatypeValue
        XCTAssertEqual("4ABE10C9-FF12-4CD4-90C1-4B429001BAD3", string)
    }

    func testUUIDFromString() {
        let string = "4ABE10C9-FF12-4CD4-90C1-4B429001BAD3"
        let uuid = UUID.fromDatatypeValue(string)
        XCTAssertEqual(UUID(uuidString: "4ABE10C9-FF12-4CD4-90C1-4B429001BAD3"), uuid)
    }

    func testURLFromString() {
        let string = "http://foo.com"
        let url = URL.fromDatatypeValue(string)
        XCTAssertEqual(URL(string: string), url)
    }

    func testStringFromURL() {
        let url = URL(string: "http://foo.com")!
        let string = url.datatypeValue
        XCTAssertEqual("http://foo.com", string)
    }
}
