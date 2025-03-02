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

/// - Warning: `Binding` is a protocol that SQLite.swift uses internally to
///   directly map SQLite types to Swift types.
///
///   Do not conform custom types to the Binding protocol. See the `Value`
///   protocol, instead.
public protocol Binding {}

public protocol Number: Binding {}

public protocol Value: Expressible { // extensions cannot have inheritance clauses

    associatedtype ValueType = Self

    associatedtype Datatype: Binding

    static var declaredDatatype: String { get }

    static func fromDatatypeValue(_ datatypeValue: Datatype) throws -> ValueType

    var datatypeValue: Datatype { get }

}

#if !SKIP // SkipSQLDB TODO
extension Double: Number, Value {
}
#endif

extension Double {
    public static let declaredDatatype = "REAL"

    public static func fromDatatypeValue(_ datatypeValue: Double) -> Double {
        datatypeValue
    }

    public var datatypeValue: Double {
        self
    }

}

#if !SKIP // SkipSQLDB TODO
extension Int64: Number, Value {
}
#endif

extension Int64 {
    public static let declaredDatatype = "INTEGER"

    public static func fromDatatypeValue(_ datatypeValue: Int64) -> Int64 {
        datatypeValue
    }

    public var datatypeValue: Int64 {
        self
    }

}

#if !SKIP // SkipSQLDB TODO
extension String: Binding, Value {
}
#endif

extension String {
    public static let declaredDatatype = "TEXT"

    public static func fromDatatypeValue(_ datatypeValue: String) -> String {
        datatypeValue
    }

    public var datatypeValue: String {
        self
    }

}

#if !SKIP // SkipSQLDB TODO
extension Blob: Binding, Value {
}
#endif

extension Blob {
    public static let declaredDatatype = "BLOB"

    public static func fromDatatypeValue(_ datatypeValue: Blob) -> Blob {
        datatypeValue
    }

    public var datatypeValue: Blob {
        self
    }

}

// MARK: -

#if !SKIP // SkipSQLDB TODO
extension Bool: Binding, Value {
}
#endif

extension Bool {
    public static var declaredDatatype = Int64.declaredDatatype

    public static func fromDatatypeValue(_ datatypeValue: Int64) -> Bool {
        datatypeValue != 0 as Int64
    }

    public var datatypeValue: Int64 {
        (self ? 1 : 0) as Int64
    }

}

#if !SKIP // SkipSQLDB TODO
extension Int: Number, Value {
}
#endif

extension Int {
    public static var declaredDatatype = Int64.declaredDatatype

    public static func fromDatatypeValue(_ datatypeValue: Int64) -> Int {
        Int(datatypeValue)
    }

    public var datatypeValue: Int64 {
        Int64(self)
    }

}
