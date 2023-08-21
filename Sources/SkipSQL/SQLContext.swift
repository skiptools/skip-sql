// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org
import Foundation
import OSLog

#if SKIP
#else
#if os(Linux)
import CSQLite
#else
import SQLite3
#endif
#endif

#if !SKIP
import CryptoKit
import struct Foundation.Data // explicit to not overlap with SQLite3
import struct Foundation.URL
#else
import Foundation
#endif

/// A context for evaluating SQL Statements against a SQLite database.
@available(macOS 11, iOS 14, watchOS 7, tvOS 14, *)
public final class SQLContext {
    internal static let logger: Logger = Logger(subsystem: "skip.sql", category: "SQL")

    #if SKIP
    public let db: android.database.sqlite.SQLiteDatabase
    #else
    public typealias Handle = OpaquePointer
    fileprivate var _handle: Handle?
    public var handle: Handle { _handle! }
    #endif

    /// Whether the connection to the database is closed or not
    public private(set) var closed = false

    /// Creates a connection from the given URL
    public static func open(url: URL, readonly: Bool = false) throws -> SQLContext {
        try SQLContext(url.path, readonly: readonly)
    }

    public init(_ filename: String = ":memory:", readonly: Bool = false) throws {
        #if SKIP
        // self.db = SQLiteDatabase.openDatabase(filename, nil, readonly ? SQLiteDatabase.OPEN_READONLY : (SQLiteDatabase.CREATE_IF_NECESSARY | SQLiteDatabase.OPEN_READWRITE))
        self.db = android.database.sqlite.SQLiteDatabase.openDatabase(filename, nil, android.database.sqlite.SQLiteDatabase.CREATE_IF_NECESSARY)
        #else
        let flags = readonly ? SQLITE_OPEN_READONLY : (SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE)
        try check(resultOf: sqlite3_open_v2(filename, &_handle, flags | SQLITE_OPEN_FULLMUTEX | SQLITE_OPEN_URI, nil))
        #endif
    }

    deinit {
        close()
    }

    /// Closes the connection to the database
    public func close() {
        if !closed {
            closed = true
            #if SKIP
            self.db.close()
            #else
            sqlite3_close(handle)
            #endif
        }
    }

    /// Executes the given query with the specified parameters.
    public func query(sql: String, params: [SQLValue] = []) throws -> Cursor {
        try Cursor(self, sql, params: params)
    }

    /// Executes a single SQL statement.
    public func execute(sql: any StringProtocol, params: [SQLValue] = []) throws {
        Self.logger.debug("execute: \(sql.description)")
        #if SKIP
        let bindArgs = params.map { $0.toBindArg() }
        db.execSQL(sql.toString(), bindArgs.toList().toTypedArray())
        #else
        if params.isEmpty {
            // no-param single-shot exec convenience
            try check(resultOf: sqlite3_exec(handle, sql.description, nil, nil, nil))
        } else {
            _ = try Cursor(self, sql, params: params).nextRow(close: true)
        }
        #endif
    }

    #if !SKIP
    @discardableResult fileprivate func check(resultOf resultCode: Int32) throws -> Int32 {
        let successCodes: Set = [SQLITE_OK, SQLITE_ROW, SQLITE_DONE]
        if !successCodes.contains(resultCode) {
            let message = String(cString: sqlite3_errmsg(self.handle))
            struct SQLError : Error {
                let message: String
            }
            throw SQLError(message: message)
        }

        return resultCode
    }

    /// Binds the given parameter at the given index.
    /// - Parameters:
    ///   - handle: the statement handle to bind to
    ///   - parameter: the parameter value to bind
    ///   - index: the index of the matching '?' parameter, which starts at 1
    fileprivate func bind(handle: Cursor.Handle?, parameter: SQLValue, index: Int32) throws {
        switch parameter {
        case .nul:
            try self.check(resultOf: sqlite3_bind_null(handle, index))
        case let .text(string: string):
            try self.check(resultOf: sqlite3_bind_text(handle, index, string, -1, SQLITE_TRANSIENT))
        case let .integer(int: num):
            try self.check(resultOf: sqlite3_bind_int64(handle, index, num))
        case let .float(double: dbl):
            try self.check(resultOf: sqlite3_bind_double(handle, index, dbl))
        case let .blob(data: bytes) where bytes.isEmpty:
            try self.check(resultOf: sqlite3_bind_zeroblob(handle, index, 0))
        case let .blob(data: bytes):
            _ = try bytes.withUnsafeBytes { ptr in
                try self.check(resultOf: sqlite3_bind_blob(handle, index, ptr.baseAddress.unsafelyUnwrapped, Int32(bytes.count), SQLITE_TRANSIENT))
            }
       }
    }
    #endif

    /// A cursor to the open result set returned by `SQLContext.query`.
    public final class Cursor {
        fileprivate let connection: SQLContext

        #if SKIP
        fileprivate var cursor: android.database.Cursor
        #else
        typealias Handle = OpaquePointer
        fileprivate var handle: Handle?
        #endif

        /// Whether the cursor is closed or not
        public private(set) var closed = false

        /// Whether the cursor has started to be traversed
        private var opened = false

        fileprivate init(_ connection: SQLContext, _ SQL: any StringProtocol, params: [SQLValue]) throws {
            self.connection = connection
            SQLContext.logger.debug("query: \(SQL.description)")

            #if SKIP
            let bindArgs: [String?] = params.map { $0.toBindString() }
            self.cursor = connection.db.rawQuery(SQL.toString(), bindArgs.toList().toTypedArray())
            #else
            try connection.check(resultOf: sqlite3_prepare_v2(connection.handle, SQL.description, -1, &handle, nil))
            for (index, param) in params.enumerated() {
                try connection.bind(handle: self.handle, parameter: param, index: .init(index + 1))
            }
            #endif
        }

        public var columnCount: Int32 {
            if closed { return 0 }
            #if SKIP
            return self.cursor.getColumnCount()
            #else
            return sqlite3_column_count(handle)
            #endif
        }

        /// Moves to the next row in the result set, returning `false` if there are no more rows to traverse.
        public func next() throws -> Bool {
            if closed {
                throw CursorClosedError()
            }
            #if SKIP
            let success = self.cursor.moveToNext()
            #else
            let success = try connection.check(resultOf: sqlite3_step(handle)) == SQLITE_ROW
            #endif
            opened = opened || success
            return success
        }

        #if !SKIP // TODO: zip
        /// Returns the current row as a dictionary.
        public func dictionary() throws -> Dictionary<String, SQLValue> {
            try Dictionary(uniqueKeysWithValues: zip(getColumnNames(), getRow()))
        }
        #endif

        /// Generates a SHA-256 hash by iterating over the remaining rows and updating a hash of each string value of the columns in order.
        ///
        /// The exact algorithm is to iterate through the remaining rows in the Cursor, then output a series of tab-delimited pair of count\tvalue for each column.
        public func digest(rows: Int? = nil, algorithm: any HashFunction = SHA256()) throws -> (rows: Int, digest: Data) {
            var hash = algorithm
            let columns = columnCount
            let tab = "\t".data(using: String.Encoding.utf8)!
            let nl = "\n".data(using: String.Encoding.utf8)!

            var rowCount = 0
            while try next(), rowCount < (rows ?? Int.max) {
                rowCount += 1
                for i in 0..<columns {
                    let columnData = try getValue(column: i).toData()

                    // we always prefix the column's hash in order to ensure that overlapping values (e.g., COL1="ABC"+COL2="DEF" == COL1="A"+COL2="BCDEF")
                    // NULLs are specified as -1 to distinguish from empty data
                    let valueLength = "\(columnData?.count ?? -1)".data(using: String.Encoding.utf8) ?? Data()
                    hash.update(data: valueLength)
                    hash.update(data: tab) // length-value separated by tabs
                    hash.update(data: columnData ?? Data()) // then add the data itself

                    if i == columns - 1 {
                        hash.update(data: nl) // lines end in a newline
                    } else {
                        hash.update(data: tab) // length-value separated by tabs
                    }
                }
            }
            try close()
            return (rowCount, Data(hash.finalize()))
        }

        /// Returns the name of the column at the given zero-based index.
        public func getColumnName(column: Int32) throws -> String {
            if closed {
                throw CursorClosedError()
            }
            #if SKIP
            return self.cursor.getColumnName(column)
            #else
            return String(cString: sqlite3_column_name(handle, column))
            #endif
        }

        public func getColumnType(column: Int32) throws -> ColumnType {
            if closed {
                throw CursorClosedError()
            }

            //return ColumnType(rawValue: getTypeConstant(column: column))

            switch try getTypeConstant(column: column) {
            case ColumnType.nul.rawValue:
                return .nul
            case ColumnType.integer.rawValue:
                return .integer
            case ColumnType.float.rawValue:
                return .float
            case ColumnType.text.rawValue:
                return .text
            case ColumnType.blob.rawValue:
                return .blob
            //case let type: // “error: Unsupported switch case item (failed to translate SwiftSyntax node)”
            default:
                return .nul
                //fatalError("unsupported column type")
            }
        }

        /// Returns the value contained in the given column, coerced to the expected type based on the column definition.
        public func getValue(column: Int32) throws -> SQLValue {
            if closed {
                throw CursorClosedError()
            }
            switch try getColumnType(column: column) {
            case .nul:
                return .nul
            case .integer:
                return .integer(try getInt64(column: column))
            case .float:
                return .float(try getDouble(column: column))
            case .text:
                guard let str = try getString(column: column) else {
                    return .nul
                }
                return .text(str)
            case .blob:
                guard let blob = try getBlob(column: column) else {
                    return .nul
                }
                return .blob(blob)
            }
        }

        /// Returns the column names as an array
        public func getColumnNames() throws -> [String] {
            return try Array((0..<columnCount).map { column in
                try getColumnName(column: column)
            })
        }

        /// Returns the values of the current row as an array
        public func getRow() throws -> [SQLValue] {
            return try Array((0..<columnCount).map { column in
                try getValue(column: column)
            })
        }

        /// Returns a textual description of the row's values in a format suitable for printing to a console
        public func rowText(header: Bool = false, values: Bool = false, width: Int = 80) throws -> String {
            var str = ""
            let sep = header == false && values == false ? "+" : "|"
            str += sep
            let count: Int = Int(columnCount)
            var cellSpan: Int = (width / count) - 2
            if cellSpan < 0 {
                cellSpan = 0
                cellSpan = 0
            }

            for col in 0..<count {
                let i = Int32(col)
                let cell: String
                if header {
                    cell = try getColumnName(column: i)
                } else if values {
                    cell = try getValue(column: i).toBindString() ?? ""
                } else {
                    cell = ""
                }

                let numeric = header || values ? try getColumnType(column: i).isNumeric : false
                let padding = header || values ? " " : "-"
                str += padding
                str += cell.pad(to: cellSpan - 2, with: padding, rightAlign: numeric)
                str += padding
                if col < count - 1 {
                    str += sep
                }
            }
            str += sep
            return str
        }

        /// Returns a single value from the query, closing the result set afterwards
        public func singleValue() throws -> SQLValue? {
            try nextRow(close: true)?.first
        }

        /// Steps to the next row and returns all the values in the row.
        /// - Parameter close: if true, closes the cursor after returning the values; this can be useful for single-shot execution of queries where only one row is expected.
        /// - Returns: an array of ``SQLValue`` containing the row contents.
       public func nextRow(close: Bool = false) throws -> [SQLValue]? {
           do {
               if try next() == false {
                   try self.close()
                   return nil
               } else {
                   let values = try getRow()
                   if close {
                       try self.close()
                   }
                   return values
               }
           } catch let error {
               try? self.close()
               throw error
           }
        }

        public func rows(count: Int = Int.max) throws -> [[SQLValue]] {
            if closed {
                throw CursorClosedError()
            }
            var values: [[SQLValue]] = []
            for _ in 1...count {
                if let row = try nextRow() {
                    values.append(row)
                } else {
                    try close()
                    break
                }
            }
            return values
        }

        public func getDouble(column: Int32) throws -> Double {
            if closed {
                throw CursorClosedError()
            }
            #if SKIP
            return self.cursor.getDouble(column)
            #else
            return sqlite3_column_double(handle, column)
            #endif
        }

        public func getInt64(column: Int32) throws -> Int64 {
            if closed {
                throw CursorClosedError()
            }
            #if SKIP
            return self.cursor.getLong(column)
            #else
            return sqlite3_column_int64(handle, column)
            #endif
        }

        public func getString(column: Int32) throws -> String? {
            if closed {
                throw CursorClosedError()
            }
            #if SKIP
            return self.cursor.getString(column)
            #else
            guard let text = sqlite3_column_text(handle, Int32(column)) else {
                return nil
            }
            return String(cString: UnsafePointer(text))
            #endif
        }

        public func getBlob(column: Int32) throws -> Data? {
            if closed {
                throw CursorClosedError()
            }
            #if SKIP
            guard let blob = self.cursor.getBlob(column) else {
                return nil
            }
            return Data(platformValue: blob)
            #else
            if let pointer = sqlite3_column_blob(handle, Int32(column)) {
                let length = Int(sqlite3_column_bytes(handle, Int32(column)))
                //let ptr = UnsafeBufferPointer(start: pointer.assumingMemoryBound(to: Int8.self), count: length)
                return Data(bytes: pointer, count: length)
            } else {
                // The return value from sqlite3_column_blob() for a zero-length BLOB is a NULL pointer.
                return nil
            }
            #endif
        }

        private func getTypeConstant(column: Int32) throws -> Int32 {
            if closed {
                throw CursorClosedError()
            }
            #if SKIP
            return self.cursor.getType(column)
            #else
            return sqlite3_column_type(handle, column)
            #endif
        }

        public func close() throws {
            if !closed {
                #if SKIP
                self.cursor.close()
                #else
                try connection.check(resultOf: sqlite3_finalize(handle))
                #endif
            }
            closed = true
        }

        #if SKIP
        // TODO: finalize { close() }
        #else
        deinit {
            try? close()
        }
        #endif
    }
}

struct CursorClosedError : Error {
    let errorDescription: String?

    init(errorDescription: String = "Cursor closed") {
        self.errorDescription = errorDescription
    }
}

#if !SKIP
// let SQLITE_STATIC = unsafeBitCast(0, sqlite3_destructor_type.self)
let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
#endif

public enum SQLValue {
    case nul
    case text(_ string: String)
    case integer(_ int: Int64)
    case float(_ double: Double)
    case blob(_ data: Data)

    public var columnType: ColumnType {
        switch self {
        case SQLValue.nul:
            return ColumnType.nul
        case SQLValue.text:
            return ColumnType.text
        case SQLValue.integer:
            return ColumnType.integer
        case SQLValue.float:
            return ColumnType.float
        case SQLValue.blob:
            return ColumnType.blob
        }
    }

    func toBindArg() -> Any? {
        switch self {
        case SQLValue.nul:
            return nil
        case let SQLValue.text(str):
            return str
        case let SQLValue.integer(num):
            return num
        case let SQLValue.float(dbl):
            return dbl
        case let SQLValue.blob(bytes):
            return bytes
        }
    }

    /// Convert this column to Data, either the underlying blob or the .utf8-encoded string form of the string or number.
    func toData() -> Data? {
        switch self {
        case .nul:
            return nil
        case .blob(let data):
            return data
        case .float(let number):
            return number.description.data(using: String.Encoding.utf8)
        case .integer(let int):
            return int.description.data(using: String.Encoding.utf8)
        case .text(let str):
            return str.data(using: String.Encoding.utf8)
        }
    }

    public func toBindString() -> String? {
        switch self {
        case SQLValue.nul:
            return nil
        case let SQLValue.text(str):
            return str
        case let SQLValue.integer(num):
            return num.description
        case let SQLValue.float(dbl):
            return dbl.description
        case SQLValue.blob:
            return nil // bytes.description // mis-transpiles
        }
    }

    /// If this is a `text` value, then return the underlying string
    public var textValue: String? {
        switch self {
        case let SQLValue.text(str): return str
        default: return nil
        }
    }

    /// If this is a `integer` value, then return the underlying integer
    public var integerValue: Int64? {
        switch self {
        case let SQLValue.integer(num): return num
        default: return nil
        }
    }

    /// If this is a `float` value, then return the underlying double
    public var floatValue: Double? {
        switch self {
        case let SQLValue.float(dbl): return dbl
        default: return nil
        }
    }

    /// If this is a `blob` value, then return the underlying data
    public var blobValue: Data? {
        switch self {
        case SQLValue.blob(let dat): return dat
        default: return nil
        }
    }

}

/// The type of a SQLite colums.
///
/// Every value in SQLite has one of five fundamental datatypes:
///  - 64-bit signed integer
///  - 64-bit IEEE floating point number
///  - string
///  - BLOB
///  - NULL
public enum ColumnType : Int32 {
    /// `SQLITE_NULL`
    case nul = 0
    /// `SQLITE_INTEGER`, a 64-bit signed integer
    case integer = 1
    /// `SQLITE_FLOAT`, a 64-bit IEEE floating point number
    case float = 2
    /// `SQLITE_TEXT`, a string
    case text = 3
    /// `SQLITE_BLOB`, a byte array
    case blob = 4
}

extension ColumnType {
    /// Returns true if this column is expected to hold a numeric type.
    public var isNumeric: Bool {
        switch self {
        case .integer: return true
        case .float: return true
        default: return false
        }
    }
}


extension String {
    func pad(to width: Int, with padding: String, rightAlign: Bool) -> String {
        var str = self
        while str.count < width {
            str = (rightAlign ? padding : "") + str + (!rightAlign ? padding : "")
        }
        if str.count > width {
            #if SKIP
            str = str.dropLast(width - str.count)
            #else
            str.removeLast(width - str.count)
            #endif
        }
        return str
    }
}
