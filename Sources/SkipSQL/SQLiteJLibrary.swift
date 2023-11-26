// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

#if SKIP
import Foundation
import OSLog
import SkipFFI

/// Mock constructor for a `SQLiteLibrary` instance that uses the built-in sqlite3 library
internal func SQLitePlatformLibrary() -> SQLiteLibrary {
    let cachedImplementation = true
    if true { // test cases: 76 sec
        return SQLiteJNALibrary.shared
    } else { // test cases: 212 sec
        do {
            return com.sun.jna.Native.load("sqlite3", (SQLiteLibrary.self as kotlin.reflect.KClass).java)
        } catch let error as java.lang.UnsatisfiedLinkError { // "Unable to load library 'sqlite3'"
            // on Android the sqlite3 lib is already loaded, so we can map to the current process for symbols
            // http://java-native-access.github.io/jna/5.13.0/javadoc/com/sun/jna/Native.html#load-java.lang.String-java.lang.Class-
            return com.sun.jna.Native.load(nil, (SQLiteLibrary.self as kotlin.reflect.KClass).java)
        }
    }
}

/// The argument to `sqlite3_update_hook`
public protocol sqlite3_update_hook : NativeCallback {
    func callback(userData: OpaquePointer?, operation: Int32, databaseName: OpaquePointer?, tableName: OpaquePointer?, rowid: Int64)
}


/// A concrete implementation of the `SQLiteLibrary` interface that declared `external` methods to use [JNA Direct Mapping](https://github.com/java-native-access/jna/blob/master/www/DirectMapping.md) to cache native method lookups.
private final class SQLiteJNALibrary : SQLiteLibrary {
    static let shared = SQLiteJNALibrary()

    private init() {
        do {
            com.sun.jna.Native.register((SQLiteJNALibrary.self as kotlin.reflect.KClass).java, "sqlite3")
        } catch let error as java.lang.UnsatisfiedLinkError { // "Unable to load library 'sqlite3'"
            com.sun.jna.Native.register((SQLiteJNALibrary.self as kotlin.reflect.KClass).java, nil as String?)
        }
    }

    /* SKIP INSERT: external */ func sqlite3_sleep(_ duration: Int32) -> Int32
    /* SKIP INSERT: external override */ public func sqlite3_open(_ filename: String, _ ppDb: sqlite3_openarg?) -> Int32
    /* SKIP INSERT: external override */ public func sqlite3_open_v2(_ filename: String, _ ppDb: sqlite3_openarg?, _ flags: Int32, _ vfs: String?) -> Int32
    /* SKIP INSERT: external */ func sqlite3_close(_ db: OpaquePointer) -> Int32
    /* SKIP INSERT: external */ func sqlite3_errcode(_ db: OpaquePointer) -> Int32
    /* SKIP INSERT: external */ func sqlite3_errmsg(_ db: OpaquePointer) -> sqlite3_cstring_ptr?
    /* SKIP INSERT: external */ func sqlite3_last_insert_rowid(_ db: OpaquePointer) -> Int64
    /* SKIP INSERT: external */ func sqlite3_total_changes(_ db: OpaquePointer) -> Int32
    /* SKIP INSERT: external */ func sqlite3_changes(_ db: OpaquePointer) -> Int32
    // /* SKIP INSERT: external */ func sqlite3_total_changes64(_ db: OpaquePointer) -> Int64
    // /* SKIP INSERT: external */ func sqlite3_changes64(_ db: OpaquePointer) -> Int64 // unavailable on Android
    /* SKIP INSERT: external */ func sqlite3_interrupt(_ db: OpaquePointer)
    /* SKIP INSERT: external override */ public func sqlite3_exec(_ db: OpaquePointer, _ sql: String, _ callback: sqlite3_callback?, _ pArg: UnsafeMutableRawPointer?, _ errmsg: sqlite_error_ptr?) -> Int32
    /* SKIP INSERT: external override */ public func sqlite3_prepare_v2(_ db: OpaquePointer, _ sql: String, _ nBytes: Int32, _ ppStmt: sqlite3_openarg, _ tail: sqlite_tail_ptr?) -> Int32
    /* SKIP INSERT: external */ func sqlite3_step(_ stmt: OpaquePointer) -> Int32
    /* SKIP INSERT: external */ func sqlite3_finalize(_ stmt: OpaquePointer) -> Int32
    /* SKIP INSERT: external */ func sqlite3_reset(_ stmt: OpaquePointer) -> Int32
    /* SKIP INSERT: external */ func sqlite3_column_count(_ stmt: OpaquePointer) -> Int32
    /* SKIP INSERT: external */ func sqlite3_bind_parameter_count(_ stmnt: OpaquePointer) -> Int32
    /* SKIP INSERT: external */ func sqlite3_bind_parameter_name(_ stmnt: OpaquePointer, _ columnIndex: Int32) -> sqlite3_cstring_ptr?
    /* SKIP INSERT: external */ func sqlite3_bind_parameter_index(_ stmnt: OpaquePointer, _ name: String) -> Int32
    /* SKIP INSERT: external */ func sqlite3_clear_bindings(_ stmnt: OpaquePointer) -> Int32
    /* SKIP INSERT: external */ func sqlite3_column_name(_ stmt: OpaquePointer!, _ columnIndex: Int32) -> sqlite3_cstring_ptr?
    // /* SKIP INSERT: external */ func sqlite3_column_database_name(_ stmt: OpaquePointer, _ columnIndex: Int32) -> sqlite3_cstring_ptr? // unavailable on Android
    // /* SKIP INSERT: external */ func sqlite3_column_origin_name(_ stmt: OpaquePointer, _ columnIndex: Int32) -> sqlite3_cstring_ptr?
    /* SKIP INSERT: external */ func sqlite3_column_decltype(_ stmt: OpaquePointer, _ columnIndex: Int32) -> sqlite3_cstring_ptr?
    /* SKIP INSERT: external */ func sqlite3_sql(_ stmt: OpaquePointer) -> sqlite3_cstring_ptr?
    /* SKIP INSERT: external */ func sqlite3_db_handle(_ stmt: OpaquePointer) -> OpaquePointer
    /* SKIP INSERT: external */ func sqlite3_bind_null(_ stmt: OpaquePointer, _ paramIndex: Int32) -> Int32
    /* SKIP INSERT: external */ func sqlite3_bind_int(_ stmt: OpaquePointer, _ paramIndex: Int32, _ value: Int32) -> Int32
    /* SKIP INSERT: external */ func sqlite3_bind_int64(_ stmt: OpaquePointer, _ paramIndex: Int32, _ value: Int64) -> Int32
    /* SKIP INSERT: external */ func sqlite3_bind_double(_ stmt: OpaquePointer, _ paramIndex: Int32, _ value: Double) -> Int32
    /* SKIP INSERT: external */ func sqlite3_bind_text(_ stmt: OpaquePointer, _ paramIndex: Int32, _ value: String, _ length: Int32, _ destructor: sqlite3_destructor_type) -> Int32
    /* SKIP INSERT: external override */ public func sqlite3_bind_blob(_ stmt: OpaquePointer, _ paramIndex: Int32, _ value: UnsafeRawPointer?, _ length: Int32, _ destructor: sqlite3_destructor_type) -> Int32
    /* SKIP INSERT: external */ func sqlite3_bind_zeroblob(_ stmt: OpaquePointer, _ paramIndex: Int32, _ length: Int32) -> Int32
    /* SKIP INSERT: external */ func sqlite3_column_type(_ stmt: OpaquePointer, _ columnIndex: Int32) -> Int32
    /* SKIP INSERT: external */ func sqlite3_column_int(_ stmt: OpaquePointer, _ columnIndex: Int32) -> Int32
    /* SKIP INSERT: external */ func sqlite3_column_int64(_ stmt: OpaquePointer, _ columnIndex: Int32) -> Int64
    /* SKIP INSERT: external */ func sqlite3_column_double(_ stmt: OpaquePointer, _ columnIndex: Int32) -> Double
    /* SKIP INSERT: external */ func sqlite3_column_text(_ stmt: OpaquePointer, _ columnIndex: Int32) -> sqlite3_uint8_ptr?
    /* SKIP INSERT: external */ func sqlite3_column_blob(_ stmt: OpaquePointer, _ columnIndex: Int32) -> UnsafeRawPointer?
    /* SKIP INSERT: external */ func sqlite3_column_bytes(_ stmt: OpaquePointer, _ columnIndex: Int32) -> Int32
    /* SKIP INSERT: external */ func sqlite3_backup_init(_ destDb: OpaquePointer, _ destName: String, _ sourceDb: OpaquePointer?, _ sourceName: String) -> OpaquePointer
    /* SKIP INSERT: external */ func sqlite3_backup_step(_ backup: OpaquePointer, _ pages: Int32) -> Int32
    /* SKIP INSERT: external */ func sqlite3_backup_finish(_ backup: OpaquePointer) -> Int32
    /* SKIP INSERT: external */ func sqlite3_backup_remaining(_ backup: OpaquePointer) -> Int32
    /* SKIP INSERT: external */ func sqlite3_backup_pagecount(_ backup: OpaquePointer) -> Int32
    /* SKIP INSERT: external */ func sqlite3_initialize() -> Int32
    /* SKIP INSERT: external */ func sqlite3_shutdown() -> Int32
    /* SKIP INSERT: external */ func sqlite3_extended_result_codes(_ db: OpaquePointer, _ on: Int32) -> Int32
    /* SKIP INSERT: external */ func sqlite3_db_mutex(_ db: OpaquePointer?) -> OpaquePointer?
    /* SKIP INSERT: external */ func sqlite3_mutex_free(_ lock: OpaquePointer?)
    /* SKIP INSERT: external */ func sqlite3_mutex_enter(_ lock: OpaquePointer?)
    /* SKIP INSERT: external */ func sqlite3_mutex_leave(_ lock: OpaquePointer?)
    /* SKIP INSERT: external */ func sqlite3_update_hook(_ db: OpaquePointer?, _ callback: sqlite3_update_hook?, _ pArg: UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer?
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

let SQLITE_TRANSIENT = Int64(-1)

#endif
