// Copyright 2023–2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
import Foundation
import OSLog
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

    public func exec(_ expr: SQLExpression) throws {
        try checkClosed()
        let stmnt = try prepare(sql: expr.template)
        var err: Error? = nil
        do {
            try stmnt.update(parameters: expr.bindings)
        } catch let e {
            err = e
        }
        // always close the statements; we don't use a `defer` block because they can't throw
        try stmnt.close()
        if let err = err {
            throw err
        }
    }

    /// Execute the given SQL statement.
    public func exec(sql: String, parameters: [SQLValue] = []) throws {
        try exec(SQLExpression(sql, parameters))
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

    /// Issue a query and return all the rows in a single batch
    public func query(sql: String, parameters: [SQLValue] = []) throws -> [[SQLValue]] {
        try cursor(SQLExpression(sql, parameters)).map({ try $0.get() })
    }

    /// Issues a SQL query with the optional parameters and returns all the values.
    public func cursor(_ expr: SQLExpression) throws -> RowCursor<[SQLValue]> {
        let stmnt = try prepare(sql: expr.template)
        if !expr.bindings.isEmpty {
            try stmnt.bind(parameters: expr.bindings)
        }
        return RowCursor(statement: stmnt, creator: { $0.rowValues() })
    }


    // MARK: trace

    public typealias TraceAction = (String) -> Void
    private var traceHook: TraceHook?

    #if !SKIP
    typealias TraceBox = @convention(block) (UnsafeRawPointer) -> Void
    private typealias TraceHook = TraceBox
    #else
    private final class TraceHook : sqlite3_trace_hook {
        let action: TraceAction
        let context: SQLContext

        init(action: TraceAction, context: SQLContext) {
            self.action = action
            self.context = context
        }

        override func callback(type: sqlite3_unsigned, ctx: OpaquePointer?, pointer: OpaquePointer?, px: OpaquePointer?) -> Int32 {
            if let pointer,
               let expandedSQL: sqlite3_cstring_mutptr = context.SQLite3.sqlite3_expanded_sql(pointer) {
                action(expandedSQL.getString(0))
                context.SQLite3.sqlite3_free(expandedSQL)
            }
            return 0
        }
    }
    #endif

    /// Adds a callback that will be invoked with the expanded SQL whenever a statement is executed
    public func trace(_ action: TraceAction?) {
        guard let action else {
            // disable trace
            _ = SQLite3.sqlite3_trace_v2(db, 0, nil, nil)
            self.traceHook = nil
            return
        }

        #if !SKIP
        let box: TraceBox = { (pointer: UnsafeRawPointer) in
            if let expandedSQL: sqlite3_cstring_mutptr = self.SQLite3.sqlite3_expanded_sql(OpaquePointer(pointer)) {
                action(String(cString: expandedSQL))
                self.SQLite3.sqlite3_free(expandedSQL)
            }
        }

        _ = SQLite3.sqlite3_trace_v2(db, UInt32(SQLITE_TRACE_STMT), {
                 (_: UInt32, context: UnsafeMutableRawPointer?, pointer: UnsafeMutableRawPointer?, _: UnsafeMutableRawPointer?) in
                if let pointer {
                     unsafeBitCast(context, to: TraceBox.self)(pointer)
                 }
                 return Int32(0)
             },
             unsafeBitCast(box, to: UnsafeMutableRawPointer.self)
        )
        traceHook = box
        #else
        self.traceHook = TraceHook(action: action, context: self) // need to retain or it will be garbage collected eventually
        // The Kotlin update mechanism is different; it uses a TraceHook implementation, and doesn't pass a context pointer
        SQLite3.sqlite3_trace_v2(db, SQLITE_TRACE_STMT, self.traceHook, nil)
        #endif
    }


    // MARK: onUpdate

    private var updateHook: UpdateHook? = nil

    /// An action that can be registered to receive updates whenever a ROWID table changes.
    public typealias UpdateAction = (_ action: SQLAction, _ rowid: Int64, _ dbname: String, _ tblname: String) -> Void

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

    /// Registers a function to be invoked whenever a ROWID table is changed.
    ///
    /// As described at https://www.sqlite.org/c3ref/update_hook.html , a given connection can only have a single update hook at a time, so setting this function will replace any pre-existing update hook.
    public func onUpdate(hook: UpdateAction?) {
        guard let hook else {
            // clear the update hook
            self.updateHook = nil
            return
        }
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
}

public struct SQLExpression {
    public var template: String
    public var bindings: [SQLValue]

    public init(_ template: String, _ bindings: [SQLValue] = []) {
        self.template = template
        self.bindings = bindings
    }
}

extension String {
    /// Encodes the String so the given mark is doubled in the resulting string.
    public func quote(_ mark: Character = "\"") -> String {
        var quoted = ""
        quoted += mark.description
        for character in self {
            quoted += character.description
            if character == mark {
                quoted += character.description
            }
        }
        quoted += mark.description
        return quoted
    }
}

/// A lazy sequence of rows from the database
public class RowCursor<Row> : Sequence {
    public typealias Element = Result<Row, Error>
    let statement: SQLStatement
    let creator: (SQLStatement) throws -> Row

    public init(statement: SQLStatement, creator: @escaping (SQLStatement) throws -> Row) {
        self.statement = statement
        self.creator = creator
    }

    public func close() {
        do {
            try statement.close()
        } catch {
        }
    }


    #if !SKIP
    public func makeIterator() -> RowIterator<Row> {
        RowIterator<Row>(statement: statement, creator: creator)
    }
    #else
    override var iterable: kotlin.collections.Iterable<Element> {
        AbstractIterable<Row> {
            RowIterator<Row>(statement: statement, creator: creator)
        }
    }
    #endif
}

#if !SKIP
typealias RowIteratorType<T> = IteratorProtocol
#else
typealias RowIteratorType<T> = kotlin.collections.Iterator<Result<T, Error>>

class AbstractIterable<T> : kotlin.collections.Iterable<Result<T, Error>> {
    let makeIterator: () -> RowIterator<T>

    init(makeIterator: () -> RowIterator<T>) {
        self.makeIterator = makeIterator
    }

    override func iterator() -> RowIterator<T> {
        makeIterator()
    }
}
#endif

public class RowIterator<Row> : RowIteratorType<Row> {
    public typealias Element = Result<Row, Error>
    let stmnt: SQLStatement
    let creator: (SQLStatement) throws -> Row
    var errorOccurred = false

    init(statement: SQLStatement, creator: @escaping (SQLStatement) throws -> Row) {
        self.stmnt = statement
        self.creator = creator
    }

    deinit {
        close()
    }

    func close() {
        do {
            try stmnt.close()
        } catch {
            // ignore
        }
    }

    #if !SKIP
    public func next() -> Element? {
        if errorOccurred {
            return nil
        }
        do {
            if try stmnt.next() == false { return nil }
            return Result.success(try creator(stmnt))
        } catch {
            errorOccurred = true
            return Result.failure(error)
        }
    }
    #else
    var nextElement: Element? = nil

    override func next() -> Element {
        if let nextElement = nextElement {
            return nextElement
        } else {
            throw java.util.NoSuchElementException()
        }
    }

    override func hasNext() -> Bool {
        if errorOccurred {
            return false
        }
        do {
            if try stmnt.next() == false {
                close()
                return false
            }
            nextElement = Result.success(try creator(stmnt))
            return true
        } catch {
            errorOccurred = true
            nextElement = Result.failure(error)
            close()
            return false
        }
    }
    #endif
}
