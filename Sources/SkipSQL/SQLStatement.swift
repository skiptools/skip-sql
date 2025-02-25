// Copyright 2023–2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
#if SKIP
import SkipFFI
#endif
import Foundation
import OSLog

/// A database prepared statement.
public final class SQLStatement {
    /// The SQLite3 library to use.
    fileprivate let SQLite3: SQLiteLibrary

    /// The pointer to the SQLite statement.
    fileprivate let stmnt: OpaquePointer
    fileprivate var closed = false

    deinit {
        #if !SKIP
        #if DEBUG
//        assert(isClosed, "SQLStatement must be closed before deinit")
        #endif
        #endif
    }

    internal init(stmnt: OpaquePointer, SQLite3: SQLiteLibrary) {
        self.stmnt = stmnt
        self.SQLite3 = SQLite3
    }

    /// The database pointer that created this statement.
    private var db: OpaquePointer {
        SQLite3.sqlite3_db_handle(stmnt)
    }

    public lazy var columnCount: Int32 = SQLite3.sqlite3_column_count(stmnt)

    public lazy var columnNames: [String] = Array((0..<columnCount).map {
        strptr(SQLite3.sqlite3_column_name(stmnt, $0)) ?? ""
    })

    public lazy var columnTypes: [String] = Array((0..<columnCount).map {
        strptr(SQLite3.sqlite3_column_decltype(stmnt, $0)) ?? ""
    })

    // doesn't work in Android
//    public lazy var columnTables: [String] = Array((0..<columnCount).map {
//        strptr(SQLite3.sqlite3_column_table_name(stmnt, $0))
//    })

    // doesn't work in Android
//    public lazy var columnDatabases: [String] = Array((0..<columnCount).map {
//        strptr(SQLite3.sqlite3_column_database_name(stmnt, $0)) ?? ""
//    })

    /// Binds the given value at the 1-based index.
    public func bind(_ value: SQLValue, at index: Int32) throws {
        precondition(index >= 1, "bind index in sqlite starts at 1")
        switch value {
        case .null:
            try check(SQLite3, db: db, code: SQLite3.sqlite3_bind_null(stmnt, index))
        case .integer(let int):
            try check(SQLite3, db: db, code: SQLite3.sqlite3_bind_int64(stmnt, index, int))
        case .text(let str):
            try check(SQLite3, db: db, code: SQLite3.sqlite3_bind_text(stmnt, index, str, -1, SQLITE_TRANSIENT))
        case .float(let double):
            try check(SQLite3, db: db, code: SQLite3.sqlite3_bind_double(stmnt, index, double))
        case .blob(let blob):
            let size = Int32(blob.count)
            if size == 0 {
                try check(SQLite3, db: db, code: SQLite3.sqlite3_bind_zeroblob(stmnt, index, size))
            } else {
                try blob.withUnsafeBytes { ptr in
                    try check(SQLite3, db: db, code: SQLite3.sqlite3_bind_blob(stmnt, index, ptr.baseAddress, size, SQLITE_TRANSIENT))
                }
            }
        }
    }
    
    /// Perform an update with the prepared statemement, resetting it once the update is complete.
    /// - Parameter params: the parameters to bind to the SQL statement
    public func update(parameters: [SQLValue] = []) throws {
        try checkClosed()
        defer { reset() }
        if !parameters.isEmpty {
            try bind(parameters: parameters)
        }
        let result = SQLite3.sqlite3_step(stmnt)
        try check(SQLite3, db: db, code: result, permit: [Int32(SQLITE_DONE)])
    }

    /// Binds the given parameters to the statement. The parameter count must match the number of `?` parameters in the statement.
    public func bind(parameters: [SQLValue]) throws {
        for (i, param) in parameters.enumerated() {
            try bind(param, at: Int32(i + 1)) // column index starts at 1
        }
    }

    /// After a prepared statement has been prepared this function must be called one or more times to evaluate the statement.
    public func next() throws -> Bool {
        try checkClosed()
        let result = SQLite3.sqlite3_step(stmnt)
        if result == SQLITE_ROW {
            return true
        } else if result == SQLITE_DONE {
            return false
        } else {
            try check(SQLite3, db: db, code: result) // try to extract the error message
            throw SQLStatementError(code: result)
        }
    }

    /// True if the statement has been closed.
    public var isClosed: Bool {
        closed
    }

    /// The application must close every prepared statement in order to avoid
    /// resource leaks.  It is a grievous error for the application to try to use
    /// a prepared statement after it has been closed.
    public func close() throws {
        if !closed {
            reset() // need to reset interrupted statemets or an interrupted error will be throws
            try check(SQLite3, db: db, code: SQLite3.sqlite3_finalize(stmnt))
            closed = true
        }
    }
    
    public func reset() {
        reset(clearBindings: true)
    }

    internal func reset(clearBindings: Bool) {
        _ = SQLite3.sqlite3_reset(stmnt)
        if clearBindings {
            _ = SQLite3.sqlite3_clear_bindings(stmnt)
        }
    }
    
    /// Returns the type of the column at the given index.
    public func type(at idx: Int32) -> SQLType {
        SQLType(rawValue: SQLite3.sqlite3_column_type(stmnt, idx)) ?? .null
    }

    /// Returns the integer at the given index, coercing if necessary according to https://www.sqlite.org/datatype3.html
    public func integer(at idx: Int32) -> Int64 {
        SQLite3.sqlite3_column_int64(stmnt, idx)
    }

    /// Returns the double at the given index, coercing if necessary according to https://www.sqlite.org/datatype3.html
    public func double(at idx: Int32) -> Double {
        SQLite3.sqlite3_column_double(stmnt, idx)
    }

    /// Returns the string at the given index, coercing if necessary according to https://www.sqlite.org/datatype3.html
    public func string(at idx: Int32) -> String? {
        strptr(SQLite3.sqlite3_column_text(stmnt, idx))
    }

    /// Returns the blob Data at the given index, coercing if necessary according to https://www.sqlite.org/datatype3.html
    public func blob(at idx: Int32) -> Data? {
        if let pointer = SQLite3.sqlite3_column_blob(stmnt, idx) {
            let length = SQLite3.sqlite3_column_bytes(stmnt, idx)
            #if !SKIP
            return Data(bytes: pointer, count: Int(length))
            #else
            let byteArray = pointer.getByteArray(0, length)
            return Data(platformValue: byteArray)
            #endif
        } else {
            // The return value from sqlite3_column_blob() for a zero-length BLOB is a NULL pointer.
            // https://www.sqlite.org/c3ref/column_blob.html
            return nil
        }
    }

    /// Returns the value at the given index, based on the type returned from `type(at:)`.
    public func value(at idx: Int32) -> SQLValue {
        switch type(at: idx) {
        case SQLType.integer: 
            return SQLValue.integer(integer(at: idx))
        case SQLType.float: 
            return SQLValue.float(double(at: idx))
        case SQLType.text: 
            if let string = string(at: idx) {
                return SQLValue.text(string)
            } else {
                return SQLValue.null
            }
        case SQLType.blob:
            if let blob = blob(at: idx) {
                return SQLValue.blob(blob)
            } else {
                return SQLValue.null
            }
        case SQLType.null:
            return SQLValue.null
        }
    }

    public func rowValues() -> [SQLValue] {
        Array((0..<columnCount).map { value(at: $0) })
    }
    
    /// Convenience for iterating to the next row and returning the values, optionally closing the statement after the values have been retrieved.
    public func nextValues(close: Bool) throws -> [SQLValue]? {
        try checkClosed()

        if !(try next()) {
            return nil
        }

        let values = rowValues()

        if close {
            try self.close()
        }

        return values
    }

    /// Returns the values of the current row as an array of strings, coercing if necessary according to https://www.sqlite.org/datatype3.html
    public func stringValues() -> [String?] {
        Array((0..<columnCount).map { string(at: $0) })
    }

    /// It is a grievous error for the application to try to use a prepared statement after it has been finalized.
    private func checkClosed() throws {
        if closed {
            throw SQLStatementClosedError()
        }
    }

    /// The SQL of this statement.
    public var sql: String {
        strptr(SQLite3.sqlite3_sql(stmnt)) ?? ""
    }

    /// The number of named or indexed parameters in this statement.
    public var parameterCount: Int32 {
        SQLite3.sqlite3_bind_parameter_count(stmnt)
    }

    /// The number of named or indexed parameters in this statement.
    public var parameterNames: [String?] {
        Array((1...parameterCount).map {
            strptr(SQLite3.sqlite3_bind_parameter_name(stmnt, $0))
        })
    }
}
