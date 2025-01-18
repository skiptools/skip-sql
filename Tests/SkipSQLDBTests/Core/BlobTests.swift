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
import SkipSQLDB

class BlobTests: XCTestCase {

    func test_toHex() {
        let blob = Blob(bytes: [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 150, 250, 255])
        XCTAssertEqual(blob.toHex(), "000a141e28323c46505a6496faff")
    }

    func test_toHex_empty() {
        let blob = Blob(bytes: [])
        XCTAssertEqual(blob.toHex(), "")
    }

    func test_description() {
        let blob = Blob(bytes: [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 150, 250, 255])
        XCTAssertEqual(blob.description, "x'000a141e28323c46505a6496faff'")
    }

    func test_description_empty() {
        let blob = Blob(bytes: [])
        XCTAssertEqual(blob.description, "x''")
    }

    func test_init_array() {
        let blob = Blob(bytes: [42, 43, 44])
        XCTAssertEqual(blob.bytes, [42, 43, 44])
    }

    #if !SKIP // SkipSQLDB TODO
    func test_init_unsafeRawPointer() {
        let pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: 3)
        pointer.initialize(repeating: 42, count: 3)
        let blob = Blob(bytes: pointer, length: 3)
        XCTAssertEqual(blob.bytes, [42, 42, 42])
    }
    #endif

    func test_equality() {
        let blob1 = Blob(bytes: [42, 42, 42])
        let blob2 = Blob(bytes: [42, 42, 42])
        let blob3 = Blob(bytes: [42, 42, 43])

        XCTAssertEqual(Blob(bytes: []), Blob(bytes: []))
        XCTAssertEqual(blob1, blob2)
        XCTAssertNotEqual(blob1, blob3)
    }
}
