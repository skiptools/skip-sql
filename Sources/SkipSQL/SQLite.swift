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


#if SKIP


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

