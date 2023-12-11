// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org
import Foundation
import OSLog
#if SKIP
import SkipFFI
#endif

/// An action taken on a row.
public enum SQLAction : Int32 {
    case insert = 18 // SQLITE_INSERT
    case delete = 9 // SQLITE_DELETE
    case update = 23 // SQLITE_UPDATE

    public var description: String {
        switch self {
        case .insert: return "INSERT"
        case .delete: return "DELETE"
        case .update: return "UPDATE"
        }
    }
}

/// The return value of `sqlite3_column_type()` can be used to decide which
/// of the first six interface should be used to extract the column value.
/// The value returned by `sqlite3_column_type()` is only meaningful if no
/// automatic type conversions have occurred for the value in question.
/// After a type conversion, the result of calling `sqlite3_column_type()`
/// is undefined, though harmless.  Future
/// versions of SQLite may change the behavior of `sqlite3_column_type()`
/// following a type conversion.
public enum SQLType : Int32, CaseIterable, Hashable {
    case integer = 1 // SQLITE_INTEGER
    case float = 2 // SQLITE_FLOAT
    case text = 3 // SQLITE_TEXT
    case blob = 4 // SQLITE_BLOB
    case null = 5 // SQLITE_NULL
}

/// A database value.
public enum SQLValue : Hashable {
    case integer(Int64)
    case float(Double)
    case text(String)
    case blob(Data)
    case null

    /// Returns the type of this value
    public var type: SQLType {
        switch self {
        case .integer: return .integer
        case .float: return .float
        case .text: return .text
        case .blob: return .blob
        case .null: return .null
        }
    }

    public var description: String {
        switch self {
        case .integer(let integer): return integer.description
        case .float(let float): return float.description
        case .text(let text): return text.description
        case .blob(let blob): return blob.description
        case .null: return "null"
        }
    }

    public var integerValue: Int64? {
        switch self {
        case .integer(let integer): return integer
        default: return nil
        }
    }

    public var floatValue: Double? {
        switch self {
        case .float(let float): return float
        default: return nil
        }
    }

    public var textValue: String? {
        switch self {
        case .text(let text): return text
        default: return nil
        }
    }

    public var blobValue: Data? {
        switch self {
        case .blob(let blob): return blob
        default: return nil
        }
    }
}

public struct SQLContextClosedError : Error {
}

public struct SQLStatementCreationError : Error {
}

public struct SQLStatementClosedError : Error {
}

public struct InternalError : Error {
    public let code: Int32

    public init(code: Int32) {
        self.code = code
    }
}

public struct SQLError : Error {
    public let msg: String
    public let code: Int32

    public init(msg: String, code: Int32) {
        self.msg = msg
        self.code = code
    }

    public var description: String {
        "SQLite error \(code): \(msg)"
    }
}

public struct SQLStatementError : Error {
    public let code: Int32
}


internal func check(_ SQLite3: SQLiteLibrary, db: OpaquePointer?, code: Int32, permit: Set<Int32>? = nil) throws {
    if code != 0 && permit?.contains(code) != true {
        if let db = db, let msg = SQLite3.sqlite3_errmsg(db) {
            throw SQLError(msg: String(cString: msg), code: code)
        } else {
            throw SQLError(msg: "Unknown SkipSQL error", code: code)
        }
    }
}

#if SKIP
internal func strptr(_ ptr: OpaquePointer?) -> String? {
    guard let ptr = ptr else { return nil }
    return String(cString: ptr)
}
#else
internal func strptr(_ ptr: UnsafePointer<CChar>?) -> String? {
    guard let ptr = ptr else { return nil }
    return String(cString: ptr)
}

internal func strptr(_ ptr: UnsafePointer<UInt8>?) -> String? {
    guard let ptr = ptr else { return nil }
    return String(cString: ptr)
}
#endif
