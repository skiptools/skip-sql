// Copyright 2023–2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
import Foundation
#if canImport(OSLog)
import OSLog
#endif
#if SKIP
import SkipFFI
#endif

let logger: Logger = Logger(subsystem: "skip.sql", category: "SQL")

/// A context for performing operations on a SQLite database.
public final class SQLContext {
    /// The SQLite3 library to use.
    fileprivate let SQLite3: SQLiteLibrary

    /// The logging level for this context; SQL statements and warnings will be sent to this log.
    public var logLevel: OSLogType? = nil

    /// The pointer to the SQLite database.
    private let db: OpaquePointer
    private var closed = false
    private var updateHook: UpdateHook? = nil

    /// The rowid of the most recent successful `INSERT` into a rowid table.
    public var lastInsertRowID: Int64 {
        SQLite3.sqlite3_last_insert_rowid(db)
    }

    /// The number of rows modified, inserted or deleted by the most recently completed INSERT, UPDATE or DELETE statement.
    public var changes: Int32 {
        SQLite3.sqlite3_changes(db)
    }

    /// The total number of rows inserted, modified or deleted by all [INSERT], [UPDATE] or [DELETE] statements completed since the database connection was opened, including those executed as part of triggers.
    public var totalChanges: Int32 {
        SQLite3.sqlite3_total_changes(db)
    }

    deinit {
        #if !SKIP
        #if DEBUG
        //assert(isClosed, "SQLContext must be closed before deinit")
        #endif
        #endif
    }

    /// Create an in-memory `SQLContext`.
    public init(configuration: SQLiteConfiguration = .platform) {
        // try! because creating an in-memory context should never fail
        self.SQLite3 = configuration.library
        self.db = try! Self.connect(path: ":memory:", configuration: configuration)!
    }

    /// Create a new `SQLContext` with the given options, either in-memory (the default), or on a file path.
    /// - Parameters:
    ///   - path: The path to the local file, or ":memory:" for an in-memory database.
    ///   - flags: The flags to use to open the database.
    public init(path: String, flags: OpenFlags? = nil, logLevel: OSLogType? = nil, configuration: SQLiteConfiguration = .platform) throws {
        self.logLevel = logLevel
        self.SQLite3 = configuration.library
        self.db = try Self.connect(path: path, flags: flags, configuration: configuration)!

        if let logLevel = logLevel {
            logger.log(level: logLevel, "opened database: \(path)")
        }
    }

    private static func connect(path: String, flags: OpenFlags? = nil, configuration: SQLiteConfiguration = .platform) throws -> OpaquePointer? {
        var db: OpaquePointer? = nil
        let library = configuration.library
        try check(library, db: db, code: withUnsafeMutablePointer(to: &db) { ptr in
            if let flags = flags {
                return library.sqlite3_open_v2(path, ptr, flags.rawValue, nil)
            } else {
                return library.sqlite3_open(path, ptr)
            }
        })

        return db
    }

    public struct OpenFlags: OptionSet {
       public let rawValue: Int32

        public init(rawValue: Int32) {
            self.rawValue = rawValue
        }

        public static let readOnly = OpenFlags(rawValue: 0x00000001)
        public static let readWrite = OpenFlags(rawValue: 0x00000002)
        public static let create = OpenFlags(rawValue: 0x00000004)
        public static let uri = OpenFlags(rawValue: 0x00000040)
        public static let memory = OpenFlags(rawValue: 0x00000080)
        public static let nomutex = OpenFlags(rawValue: 0x00008000)
        public static let fullMutex = OpenFlags(rawValue: 0x00010000)
        public static let sharedCache = OpenFlags(rawValue: 0x00020000)
        public static let privateCache = OpenFlags(rawValue: 0x00040000)
    }


    /// Execute the given SQL statement.
    public func exec(sql: String, parameters: [SQLValue] = []) throws {
        try checkClosed()
        let stmnt = try prepare(sql: sql)
        var err: Error? = nil
        do {
            try stmnt.update(parameters: parameters)
        } catch let e {
            err = e
        }
        // always close the statements; we don't use a `defer` block because they can't throw
        try stmnt.close()
        if let err = err {
            throw err
        }
    }

    /// See <https://www.sqlite.org/c3ref/interrupt.html>
    public func interrupt() {
        SQLite3.sqlite3_interrupt(db)
    }

    /// True if the context has been closed.
    public var isClosed: Bool {
        closed
    }

    /// Close the connection.
    public func close() throws {
        if !closed {
            try check(SQLite3, db: db, code: SQLite3.sqlite3_close(db))
            closed = true
        }
    }

    /// Prepares the given SQL as a statement, which can be executed with parameter bindings.
    public func prepare(sql: String) throws -> SQLStatement {
        try checkClosed()
        if let logLevel = self.logLevel {
            logger.log(level: logLevel, "prepare: \(sql)")
        }
        var stmntPtr: OpaquePointer? = nil

        try check(SQLite3, db: db, code: withUnsafeMutablePointer(to: &stmntPtr) { ptr in
            SQLite3.sqlite3_prepare_v2(db, sql, Int32(-1), ptr, nil)
        })

        if stmntPtr == nil {
            throw SQLStatementCreationError()
        }

        return SQLStatement(stmnt: stmntPtr!, SQLite3: self.SQLite3)
    }

    /// How a transaction is being performed.
    public enum TransactionMode: String {
        case deferred = "DEFERRED"
        case immediate = "IMMEDIATE"
        case exclusive = "EXCLUSIVE"
    }

    /// Performs the given operation in the context of a transaction.
    ///
    /// Specifying `.none` as the transaction mode will execute the command without a transaction.
    public func transaction<T>(_ mode: TransactionMode? = .deferred, block: () throws -> T) throws -> T {
        if let mode = mode {
            return try perform(
                "BEGIN \(mode.rawValue) TRANSACTION",
                block,
                "COMMIT TRANSACTION", or: "ROLLBACK TRANSACTION")
        } else {
            return try block()
        }
    }

    /// Performs the given operation within the databases mutex lock.
    public func mutex<T>(block: () throws -> T) rethrows -> T {
        let lock = SQLite3.sqlite3_db_mutex(db)
        SQLite3.sqlite3_mutex_enter(lock)
        defer {
            SQLite3.sqlite3_mutex_leave(lock)
            // SQLite3.sqlite3_mutex_free(lock) // don't free!
        }
        return try block()
    }

    /// Performs the given operation in the context of a begin and commit/rollback statement.
    fileprivate func perform<T>(_ begin: String, _ block: () throws -> T, _ commit: String, or rollback: String) throws -> T {
        try exec(sql: begin)
        do {
            let result = try block()
            try exec(sql: commit)
            return result
        } catch {
            try exec(sql: rollback)
            throw error
        }
    }

    private func checkClosed() throws {
        if closed {
            throw SQLContextClosedError()
        }
    }
    
    /// Issues a SQL query with the optional parameters and returns all the values.
    public func query(sql: String, parameters: [SQLValue] = []) throws -> [[SQLValue]] {
        let stmnt = try prepare(sql: sql)
        if !parameters.isEmpty {
            try stmnt.bind(parameters: parameters)
        }

        var err: Error? = nil

        var rows: [[SQLValue]] = []
        do {
            while try stmnt.next() {
                var cols: [SQLValue] = []
                for i in 0..<stmnt.columnCount {
                    cols.append(stmnt.value(at: i))
                }
                rows.append(cols)
            }
        } catch let e {
            err = e
        }

        try stmnt.close()
        if let err = err {
            throw err
        }
        return rows
    }

    /// An action that can be registered to receive updates whenever a ROWID table changes.
    public typealias UpdateAction = (_ action: SQLAction, _ rowid: Int64, _ dbname: String, _ tblname: String) -> Void

    /// Registers a function to be invoked whenever a ROWID table is changed.
    ///
    /// As described at https://www.sqlite.org/c3ref/update_hook.html , a given connection can only have a single update hook at a time, so setting this function will replace any pre-existing update hook.
    public func onUpdate(hook: @escaping UpdateAction) {
        #if !SKIP
        self.updateHook = hook
        let updateActionPtr = Unmanaged.passRetained(hook as AnyObject).toOpaque()
        func callback(updateActionPtr: UnsafeMutableRawPointer?, operation: Int32, dbname: UnsafePointer<CChar>?, tblname: UnsafePointer<CChar>?, rowid: sqlite3_int64) -> Void {
            if let operation = SQLAction(rawValue: operation),
               let updateActionPtr = updateActionPtr,
               let hook = Unmanaged<AnyObject>.fromOpaque(updateActionPtr).takeUnretainedValue() as? UpdateAction,
               let dbnamePtr = dbname, let tblnamePtr = tblname {
                hook(operation, rowid, String(cString: dbnamePtr), String(cString: tblnamePtr))
            }
        }
        _ = SQLite3.sqlite3_update_hook(db, callback, updateActionPtr)
        #else
        self.updateHook = UpdateHook(action: hook) // need to retain or it will be garbage collected eventually
        // The Kotlin update mechanism is different; it uses a SQLiteUpdateHookCallback implementation, and doesn't pass a userData pointer
        SQLite3.sqlite3_update_hook(db, self.updateHook, nil)
        #endif
    }

    #if !SKIP
    private typealias UpdateHook = UpdateAction
    #else
    private final class UpdateHook : sqlite3_update_hook {
        let updateAction: UpdateAction

        init(action: UpdateAction) {
            self.updateAction = action
        }

        override func callback(ptr: OpaquePointer?, operation: Int32, databaseName: OpaquePointer?, tableName: OpaquePointer?, rowid: Int64) {
            if let operation = SQLAction(rawValue: operation),
               let dbnamePtr = databaseName, let tblnamePtr = tableName {
                updateAction(operation, rowid, String(cString: dbnamePtr), String(cString: tblnamePtr))
            }
        }
    }
    #endif
}
