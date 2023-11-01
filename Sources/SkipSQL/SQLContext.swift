// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org
import Foundation
import OSLog
#if !SKIP
import SQLite3
#else
import SkipFFI
private let SQLite3 = SQLiteLibrary()
#endif

private let logger: Logger = Logger(subsystem: "skip.sql", category: "SQL")

public final class SQLContext {
    /// The pointer to the SQLite database
    private let db: OpaquePointer
    private var closed = false

    public init(path: String = ":memory:", flags: Int32? = nil, vfs: String? = nil) throws {
        var db: OpaquePointer? = nil

        try check(code: withUnsafeMutablePointer(to: &db) { ptr in
            SQLite3.sqlite3_open(path, ptr)
        })

        self.db = db!
    }

    public func exec(sql: String) throws {
        try checkClosed()
        try check(code: SQLite3.sqlite3_exec(db, sql, nil, nil, nil))
    }

    public func close() throws {
        if !closed {
            closed = true
            try check(code: SQLite3.sqlite3_close(db))
        }
    }

    public func prepare(sql: String) throws -> SQLStatement {
        try checkClosed()
        var stmnt: OpaquePointer? = nil

        try check(code: withUnsafeMutablePointer(to: &stmnt) { ptr in
            SQLite3.sqlite3_prepare_v2(db, sql, Int32(-1), ptr, nil)
        })

        return SQLStatement(stmnt: stmnt!)
    }

    private func checkClosed() throws {
        if closed {
            throw SQLContextClosedError()
        }
    }
}

public final class SQLStatement {
    /// The pointer to the SQLite statement
    private let stmnt: OpaquePointer
    private var closed = false

    fileprivate init(stmnt: OpaquePointer) {
        self.stmnt = stmnt
    }

    public lazy var columnCount: Int32 = SQLite3.sqlite3_column_count(stmnt)

    public lazy var columnNames: [String] = Array((0..<columnCount).map {
        str(SQLite3.sqlite3_column_name(stmnt, $0))
    })

    public lazy var columnTypes: [String] = Array((0..<columnCount).map {
        str(SQLite3.sqlite3_column_decltype(stmnt, $0))
    })

    public lazy var columnTables: [String] = Array((0..<columnCount).map {
        str(SQLite3.sqlite3_column_table_name(stmnt, $0))
    })

    public lazy var columnDatabases: [String] = Array((0..<columnCount).map {
        str(SQLite3.sqlite3_column_database_name(stmnt, $0))
    })

    public func next() throws -> Bool {
        try checkClosed()
        let result = SQLite3.sqlite3_step(stmnt)
        if result == SQLITE_ROW {
            return true
        } else if result == SQLITE_DONE {
            return false
        } else {
            throw SQLStatementError(code: result)
        }
    }

    public func close() throws {
        if !closed {
            closed = true
            try check(code: SQLite3.sqlite3_finalize(stmnt))
        }
    }

    /// It is a grievous error for the application to try to use a prepared statement after it has been finalized.
    private func checkClosed() throws {
        if closed {
            throw SQLStatementClosedError()
        }
    }
}

fileprivate func check(code: Int32 = 0) throws {
    if code != 0 {
        throw SQLContextError(code: code)
    }
}

#if !SKIP
fileprivate func str(_ ptr: Optional<UnsafePointer<Int8>>) -> String {
    return ptr == nil ? "" : String(cString: ptr!)
}
#else
fileprivate func str(_ str: String) -> String {
    return str // JNA handles coersion to Java strings automatically
}
#endif


public struct SQLContextClosedError : Error {
}

public struct SQLStatementClosedError : Error {
}

public struct SQLContextError : Error {
    public let code: Int32
}

public struct SQLStatementError : Error {
    public let code: Int32
}

#if SKIP

// MARK: SQLiteLibrary JNA

/// Direct access to the Android SQLite library from Skip.
private func SQLiteLibrary() -> SQLiteLibrary {
    do {
        return com.sun.jna.Native.load("sqlite3", (SQLiteLibrary.self as kotlin.reflect.KClass).java)
    } catch let error as java.lang.UnsatisfiedLinkError { // "Unable to load library 'sqlite3'"
        // on Android the sqlite3 lib is already loaded, so we can map to the current process for symbols
        // http://java-native-access.github.io/jna/5.13.0/javadoc/com/sun/jna/Native.html#load-java.lang.String-java.lang.Class-
        return com.sun.jna.Native.load(nil, (SQLiteLibrary.self as kotlin.reflect.KClass).java)
    }
}

private protocol SQLiteLibrary : com.sun.jna.Library {
    func sqlite3_sleep(_ duration: Int32) -> Int32

    // Database Connection API
    func sqlite3_open(filename: String, ppDb: UnsafeMutableRawPointer?) -> Int32
    func sqlite3_open_v2(filename: String, ppDb: UnsafeMutableRawPointer?, flags: Int32, vfs: String?) -> Int32
    func sqlite3_close(db: OpaquePointer) -> Int32
    func sqlite3_errcode(db: OpaquePointer) -> Int32
    func sqlite3_errmsg(db: OpaquePointer) -> String
    func sqlite3_changes(db: OpaquePointer) -> Int32
    func sqlite3_total_changes(db: OpaquePointer) -> Int32

    // Statement API
    func sqlite3_prepare_v2(db: OpaquePointer, sql: String, nBytes: Int32, ppStmt: UnsafeMutableRawPointer?, tail: UnsafeMutableRawPointer?) -> Int32
    func sqlite3_step(stmt: OpaquePointer) -> Int32
    func sqlite3_finalize(stmt: OpaquePointer) -> Int32
    func sqlite3_reset(stmt: OpaquePointer) -> Int32
    func sqlite3_column_count(stmt: OpaquePointer) -> Int32
    func sqlite3_bind_parameter_count(stmnt: OpaquePointer) -> Int32
    func sqlite3_bind_parameter_name(stmnt: OpaquePointer, columnIndex: Int32) -> String
    func sqlite3_bind_parameter_index(stmnt: OpaquePointer, name: String) -> Int32
    func sqlite3_clear_bindings(stmnt: OpaquePointer) -> Int32


    func sqlite3_column_name(stmt: OpaquePointer!, columnIndex: Int32) -> String
    func sqlite3_column_database_name(stmt: OpaquePointer, columnIndex: Int32) -> String
    func sqlite3_column_table_name(stmt: OpaquePointer, columnIndex: Int32) -> String
    func sqlite3_column_origin_name(stmt: OpaquePointer, columnIndex: Int32) -> String
    func sqlite3_column_decltype(stmt: OpaquePointer, columnIndex: Int32) -> String

    func sqlite3_sql(stmt: OpaquePointer) -> String

    // Parameter Binding
    func sqlite3_bind_null(stmt: OpaquePointer, paramIndex: Int32) -> Int32
    func sqlite3_bind_int(stmt: OpaquePointer, paramIndex: Int32, value: Int32) -> Int32
    func sqlite3_bind_long(stmt: OpaquePointer, paramIndex: Int32, value: Int64) -> Int32
    func sqlite3_bind_double(stmt: OpaquePointer, paramIndex: Int32, value: Double) -> Int32
    func sqlite3_bind_text(stmt: OpaquePointer, paramIndex: Int32, value: String, length: Int32, destructor: OpaquePointer?) -> Int32

    // Column Value API
    func sqlite3_column_type(stmt: OpaquePointer, columnIndex: Int32) -> Int32
    func sqlite3_column_int(stmt: OpaquePointer, columnIndex: Int32) -> Int32
    func sqlite3_column_long(stmt: OpaquePointer, columnIndex: Int32) -> Int64
    func sqlite3_column_double(stmt: OpaquePointer, columnIndex: Int32) -> Double
    func sqlite3_column_text(stmt: OpaquePointer, columnIndex: Int32) -> String

    // Transactions
    func sqlite3_exec(db: OpaquePointer, sql: String, callback: OpaquePointer?, pArg: OpaquePointer?, errmsg: UnsafeMutableRawPointer?) -> Int32
    func sqlite3_begin_transaction(db: OpaquePointer) -> Int32
    func sqlite3_commit(db: OpaquePointer) -> Int32
    func sqlite3_rollback(db: OpaquePointer) -> Int32

    // Backup API
    func sqlite3_backup_init(destDb: OpaquePointer, destName: String, sourceDb: OpaquePointer?, sourceName: String) -> OpaquePointer
    func sqlite3_backup_step(backup: OpaquePointer, pages: Int32) -> Int32
    func sqlite3_backup_finish(backup: OpaquePointer) -> Int32
    func sqlite3_backup_remaining(backup: OpaquePointer) -> Int32
    func sqlite3_backup_pagecount(backup: OpaquePointer) -> Int32

    // Other Functions
    func sqlite3_initialize() -> Int32
    func sqlite3_shutdown() -> Int32
    //func sqlite3_config(option: Int32, values: Object...) -> Int32
    func sqlite3_extended_result_codes(db: OpaquePointer, on: Int32) -> Int32

    // Pragma Statements
    //func sqlite3_db_status(db: OpaquePointer, op: Int32, pCurrent: UnsafeRawPointer, pHighwater: UnsafeRawPointer, resetFlg: Int32) -> Int32

    // User-Defined Functions
    //func sqlite3_create_function(db: OpaquePointer, functionName: String, numArgs: Int32, encoding: Int32, pApp: OpaquePointer?, xFunc: OpaquePointer?, xStep: OpaquePointer?, xFinal: OpaquePointer?) -> Int32

    // Savepoints
    func sqlite3_savepoint(db: OpaquePointer, op: Int32, savepointName: String) -> Int32
    func sqlite3_release_savepoint(db: OpaquePointer, savepointName: String) -> Int32
    func sqlite3_rollback_to_savepoint(db: OpaquePointer, savepointName: String) -> Int32

    // Additional Configuration
    func sqlite3_trace(db: OpaquePointer, xTrace: OpaquePointer?, pApp: OpaquePointer?) -> Int32
    func sqlite3_progress_handler(db: OpaquePointer, op: Int32, xProgress: OpaquePointer?, pApp: OpaquePointer?) -> Int32

    // Virtual Table API
    func sqlite3_create_module(db: OpaquePointer, moduleName: String, pModule: OpaquePointer?, pClientData: OpaquePointer?) -> Int32

}

// MARK: SQLite Result Codes

let SQLITE_OK =          0   /* Successful result */
let SQLITE_ERROR =       1   /* Generic error */
let SQLITE_INTERNAL =    2   /* Internal logic error in SQLite */
let SQLITE_PERM =        3   /* Access permission denied */
let SQLITE_ABORT =       4   /* Callback routine requested an abort */
let SQLITE_BUSY =        5   /* The database file is locked */
let SQLITE_LOCKED =      6   /* A table in the database is locked */
let SQLITE_NOMEM =       7   /* A malloc() failed */
let SQLITE_READONLY =    8   /* Attempt to write a readonly database */
let SQLITE_INTERRUPT =   9   /* Operation terminated by sqlite3_interrupt()*/
let SQLITE_IOERR =      10   /* Some kind of disk I/O error occurred */
let SQLITE_CORRUPT =    11   /* The database disk image is malformed */
let SQLITE_NOTFOUND =   12   /* Unknown opcode in sqlite3_file_control() */
let SQLITE_FULL =       13   /* Insertion failed because database is full */
let SQLITE_CANTOPEN =   14   /* Unable to open the database file */
let SQLITE_PROTOCOL =   15   /* Database lock protocol error */
let SQLITE_EMPTY =      16   /* Internal use only */
let SQLITE_SCHEMA =     17   /* The database schema changed */
let SQLITE_TOOBIG =     18   /* String or BLOB exceeds size limit */
let SQLITE_CONSTRAINT = 19   /* Abort due to constraint violation */
let SQLITE_MISMATCH =   20   /* Data type mismatch */
let SQLITE_MISUSE =     21   /* Library used incorrectly */
let SQLITE_NOLFS =      22   /* Uses OS features not supported on host */
let SQLITE_AUTH =       23   /* Authorization denied */
let SQLITE_FORMAT =     24   /* Not used */
let SQLITE_RANGE =      25   /* 2nd parameter to sqlite3_bind out of range */
let SQLITE_NOTADB =     26   /* File opened that is not a database file */
let SQLITE_NOTICE =     27   /* Notifications from sqlite3_log() */
let SQLITE_WARNING =    28   /* Warnings from sqlite3_log() */
let SQLITE_ROW =        100  /* sqlite3_step() has another row ready */
let SQLITE_DONE =       101  /* sqlite3_step() has finished executing */

// MARK Extended Result Codes

let SQLITE_ERROR_MISSING_COLLSEQ =   (SQLITE_ERROR | (1<<8))
let SQLITE_ERROR_RETRY =             (SQLITE_ERROR | (2<<8))
let SQLITE_ERROR_SNAPSHOT =          (SQLITE_ERROR | (3<<8))
let SQLITE_IOERR_READ =              (SQLITE_IOERR | (1<<8))
let SQLITE_IOERR_SHORT_READ =        (SQLITE_IOERR | (2<<8))
let SQLITE_IOERR_WRITE =             (SQLITE_IOERR | (3<<8))
let SQLITE_IOERR_FSYNC =             (SQLITE_IOERR | (4<<8))
let SQLITE_IOERR_DIR_FSYNC =         (SQLITE_IOERR | (5<<8))
let SQLITE_IOERR_TRUNCATE =          (SQLITE_IOERR | (6<<8))
let SQLITE_IOERR_FSTAT =             (SQLITE_IOERR | (7<<8))
let SQLITE_IOERR_UNLOCK =            (SQLITE_IOERR | (8<<8))
let SQLITE_IOERR_RDLOCK =            (SQLITE_IOERR | (9<<8))
let SQLITE_IOERR_DELETE =            (SQLITE_IOERR | (10<<8))
let SQLITE_IOERR_BLOCKED =           (SQLITE_IOERR | (11<<8))
let SQLITE_IOERR_NOMEM =             (SQLITE_IOERR | (12<<8))
let SQLITE_IOERR_ACCESS =            (SQLITE_IOERR | (13<<8))
let SQLITE_IOERR_CHECKRESERVEDLOCK = (SQLITE_IOERR | (14<<8))
let SQLITE_IOERR_LOCK =              (SQLITE_IOERR | (15<<8))
let SQLITE_IOERR_CLOSE =             (SQLITE_IOERR | (16<<8))
let SQLITE_IOERR_DIR_CLOSE =         (SQLITE_IOERR | (17<<8))
let SQLITE_IOERR_SHMOPEN =           (SQLITE_IOERR | (18<<8))
let SQLITE_IOERR_SHMSIZE =           (SQLITE_IOERR | (19<<8))
let SQLITE_IOERR_SHMLOCK =           (SQLITE_IOERR | (20<<8))
let SQLITE_IOERR_SHMMAP =            (SQLITE_IOERR | (21<<8))
let SQLITE_IOERR_SEEK =              (SQLITE_IOERR | (22<<8))
let SQLITE_IOERR_DELETE_NOENT =      (SQLITE_IOERR | (23<<8))
let SQLITE_IOERR_MMAP =              (SQLITE_IOERR | (24<<8))
let SQLITE_IOERR_GETTEMPPATH =       (SQLITE_IOERR | (25<<8))
let SQLITE_IOERR_CONVPATH =          (SQLITE_IOERR | (26<<8))
let SQLITE_IOERR_VNODE =             (SQLITE_IOERR | (27<<8))
let SQLITE_IOERR_AUTH =              (SQLITE_IOERR | (28<<8))
let SQLITE_IOERR_BEGIN_ATOMIC =      (SQLITE_IOERR | (29<<8))
let SQLITE_IOERR_COMMIT_ATOMIC =     (SQLITE_IOERR | (30<<8))
let SQLITE_IOERR_ROLLBACK_ATOMIC =   (SQLITE_IOERR | (31<<8))
let SQLITE_IOERR_DATA =              (SQLITE_IOERR | (32<<8))
let SQLITE_IOERR_CORRUPTFS =         (SQLITE_IOERR | (33<<8))
let SQLITE_IOERR_IN_PAGE =           (SQLITE_IOERR | (34<<8))
let SQLITE_LOCKED_SHAREDCACHE =      (SQLITE_LOCKED |  (1<<8))
let SQLITE_LOCKED_VTAB =             (SQLITE_LOCKED |  (2<<8))
let SQLITE_BUSY_RECOVERY =           (SQLITE_BUSY   |  (1<<8))
let SQLITE_BUSY_SNAPSHOT =           (SQLITE_BUSY   |  (2<<8))
let SQLITE_BUSY_TIMEOUT =            (SQLITE_BUSY   |  (3<<8))
let SQLITE_CANTOPEN_NOTEMPDIR =      (SQLITE_CANTOPEN | (1<<8))
let SQLITE_CANTOPEN_ISDIR =          (SQLITE_CANTOPEN | (2<<8))
let SQLITE_CANTOPEN_FULLPATH =       (SQLITE_CANTOPEN | (3<<8))
let SQLITE_CANTOPEN_CONVPATH =       (SQLITE_CANTOPEN | (4<<8))
let SQLITE_CANTOPEN_DIRTYWAL =       (SQLITE_CANTOPEN | (5<<8)) /* Not Used */
let SQLITE_CANTOPEN_SYMLINK =        (SQLITE_CANTOPEN | (6<<8))
let SQLITE_CORRUPT_VTAB =            (SQLITE_CORRUPT | (1<<8))
let SQLITE_CORRUPT_SEQUENCE =        (SQLITE_CORRUPT | (2<<8))
let SQLITE_CORRUPT_INDEX =           (SQLITE_CORRUPT | (3<<8))
let SQLITE_READONLY_RECOVERY =       (SQLITE_READONLY | (1<<8))
let SQLITE_READONLY_CANTLOCK =       (SQLITE_READONLY | (2<<8))
let SQLITE_READONLY_ROLLBACK =       (SQLITE_READONLY | (3<<8))
let SQLITE_READONLY_DBMOVED =        (SQLITE_READONLY | (4<<8))
let SQLITE_READONLY_CANTINIT =       (SQLITE_READONLY | (5<<8))
let SQLITE_READONLY_DIRECTORY =      (SQLITE_READONLY | (6<<8))
let SQLITE_ABORT_ROLLBACK =          (SQLITE_ABORT | (2<<8))
let SQLITE_CONSTRAINT_CHECK =        (SQLITE_CONSTRAINT | (1<<8))
let SQLITE_CONSTRAINT_COMMITHOOK =   (SQLITE_CONSTRAINT | (2<<8))
let SQLITE_CONSTRAINT_FOREIGNKEY =   (SQLITE_CONSTRAINT | (3<<8))
let SQLITE_CONSTRAINT_FUNCTION =     (SQLITE_CONSTRAINT | (4<<8))
let SQLITE_CONSTRAINT_NOTNULL =      (SQLITE_CONSTRAINT | (5<<8))
let SQLITE_CONSTRAINT_PRIMARYKEY =   (SQLITE_CONSTRAINT | (6<<8))
let SQLITE_CONSTRAINT_TRIGGER =      (SQLITE_CONSTRAINT | (7<<8))
let SQLITE_CONSTRAINT_UNIQUE =       (SQLITE_CONSTRAINT | (8<<8))
let SQLITE_CONSTRAINT_VTAB =         (SQLITE_CONSTRAINT | (9<<8))
let SQLITE_CONSTRAINT_ROWID =        (SQLITE_CONSTRAINT | (10<<8))
let SQLITE_CONSTRAINT_PINNED =       (SQLITE_CONSTRAINT | (11<<8))
let SQLITE_CONSTRAINT_DATATYPE =     (SQLITE_CONSTRAINT | (12<<8))
let SQLITE_NOTICE_RECOVER_WAL =      (SQLITE_NOTICE | (1<<8))
let SQLITE_NOTICE_RECOVER_ROLLBACK = (SQLITE_NOTICE | (2<<8))
let SQLITE_NOTICE_RBU =              (SQLITE_NOTICE | (3<<8))
let SQLITE_WARNING_AUTOINDEX =       (SQLITE_WARNING | (1<<8))
let SQLITE_AUTH_USER =               (SQLITE_AUTH | (1<<8))
let SQLITE_OK_LOAD_PERMANENTLY =     (SQLITE_OK | (1<<8))
let SQLITE_OK_SYMLINK =              (SQLITE_OK | (2<<8)) /* internal use only */


// MARK: SQLite Open File Flags

let SQLITE_OPEN_READONLY =       0x00000001  /* Ok for sqlite3_open_v2() */
let SQLITE_OPEN_READWRITE =      0x00000002  /* Ok for sqlite3_open_v2() */
let SQLITE_OPEN_CREATE =         0x00000004  /* Ok for sqlite3_open_v2() */
let SQLITE_OPEN_DELETEONCLOSE =  0x00000008  /* VFS only */
let SQLITE_OPEN_EXCLUSIVE =      0x00000010  /* VFS only */
let SQLITE_OPEN_AUTOPROXY =      0x00000020  /* VFS only */
let SQLITE_OPEN_URI =            0x00000040  /* Ok for sqlite3_open_v2() */
let SQLITE_OPEN_MEMORY =         0x00000080  /* Ok for sqlite3_open_v2() */
let SQLITE_OPEN_MAIN_DB =        0x00000100  /* VFS only */
let SQLITE_OPEN_TEMP_DB =        0x00000200  /* VFS only */
let SQLITE_OPEN_TRANSIENT_DB =   0x00000400  /* VFS only */
let SQLITE_OPEN_MAIN_JOURNAL =   0x00000800  /* VFS only */
let SQLITE_OPEN_TEMP_JOURNAL =   0x00001000  /* VFS only */
let SQLITE_OPEN_SUBJOURNAL =     0x00002000  /* VFS only */
let SQLITE_OPEN_SUPER_JOURNAL =  0x00004000  /* VFS only */
let SQLITE_OPEN_NOMUTEX =        0x00008000  /* Ok for sqlite3_open_v2() */
let SQLITE_OPEN_FULLMUTEX =      0x00010000  /* Ok for sqlite3_open_v2() */
let SQLITE_OPEN_SHAREDCACHE =    0x00020000  /* Ok for sqlite3_open_v2() */
let SQLITE_OPEN_PRIVATECACHE =   0x00040000  /* Ok for sqlite3_open_v2() */
let SQLITE_OPEN_WAL =            0x00080000  /* VFS only */
let SQLITE_OPEN_NOFOLLOW =       0x01000000  /* Ok for sqlite3_open_v2() */
let SQLITE_OPEN_EXRESCODE =      0x02000000  /* Extended result codes */


#endif

