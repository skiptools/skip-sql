<<<<<<< HEAD
// Copyright 2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception

// This code is adapted from the SQLite.swift project, with the following license:

=======
//
>>>>>>> d0c842f (Add SkipSQLDB module)
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

<<<<<<< HEAD
import SkipSQL

// TODO: make this customizable in the Connnection constructor
let SQLite3: SQLiteLibrary = SQLiteConfiguration.platform.library

public typealias Star = (SQLExpression<Binding>?, SQLExpression<Binding>?) -> SQLExpression<Void>

#if !SKIP // SkipSQLDB TODO
public func *(_: SQLExpression<Binding>?, _: SQLExpression<Binding>?) -> SQLExpression<Void> {
    SQLExpression(literal: "*")
}
#endif
=======
#if SQLITE_SWIFT_STANDALONE
import sqlite3
#elseif SQLITE_SWIFT_SQLCIPHER
import SQLCipher
#elseif os(Linux) || os(Windows) || os(Android)
import CSQLite
#else
import SQLite3
#endif

public typealias Star = (SQLExpression<Binding>?, SQLExpression<Binding>?) -> SQLExpression<Void>

public func *(_: SQLExpression<Binding>?, _: SQLExpression<Binding>?) -> SQLExpression<Void> {
    SQLExpression(literal: "*")
}
>>>>>>> d0c842f (Add SkipSQLDB module)

// swiftlint:disable:next type_name
public protocol _OptionalType {

    associatedtype WrappedType

}

<<<<<<< HEAD
#if !SKIP // SkipSQLDB TODO
=======
>>>>>>> d0c842f (Add SkipSQLDB module)
extension Optional: _OptionalType {

    public typealias WrappedType = Wrapped

}
<<<<<<< HEAD
#endif
=======
>>>>>>> d0c842f (Add SkipSQLDB module)

// let SQLITE_STATIC = unsafeBitCast(0, sqlite3_destructor_type.self)
let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

extension String {
    func quote(_ mark: Character = "\"") -> String {
        var quoted = ""
        quoted.append(mark)
        for character in self {
            quoted.append(character)
            if character == mark {
                quoted.append(character)
            }
        }
        quoted.append(mark)
        return quoted
    }

    func join(_ expressions: [Expressible]) -> Expressible {
        var (template, bindings) = ([String](), [Binding?]())
        for expressible in expressions {
            let expression = expressible.expression
            template.append(expression.template)
            bindings.append(contentsOf: expression.bindings)
        }
        return SQLExpression<Void>(template.joined(separator: self), bindings)
    }

    func infix<T>(_ lhs: Expressible, _ rhs: Expressible, wrap: Bool = true) -> SQLExpression<T> {
        infix([lhs, rhs], wrap: wrap)
    }

    func infix<T>(_ terms: [Expressible], wrap: Bool = true) -> SQLExpression<T> {
        let expression = SQLExpression<T>(" \(self) ".join(terms).expression)
        guard wrap else {
            return expression
        }
        return "".wrap(expression)
    }

    func prefix(_ expressions: Expressible) -> Expressible {
        "\(self) ".wrap(expressions) as SQLExpression<Void>
    }

    func prefix(_ expressions: [Expressible]) -> Expressible {
        "\(self) ".wrap(expressions) as SQLExpression<Void>
    }

    func wrap<T>(_ expression: Expressible) -> SQLExpression<T> {
        SQLExpression("\(self)(\(expression.expression.template))", expression.expression.bindings)
    }

    func wrap<T>(_ expressions: [Expressible]) -> SQLExpression<T> {
        wrap(", ".join(expressions))
    }

}

func transcode(_ literal: Binding?) -> String {
    guard let literal else { return "NULL" }

    switch literal {
    case let blob as Blob:
        return blob.description
    case let string as String:
        return string.quote("'")
    case let binding:
        return "\(binding)"
    }
}

// swiftlint:disable force_cast force_try
func value<A: Value>(_ binding: Binding) -> A {
    try! A.fromDatatypeValue(binding as! A.Datatype) as! A
}

func value<A: Value>(_ binding: Binding?) -> A {
    value(binding!)
}
<<<<<<< HEAD


// MARK: SQLite Result Codes

let SQLITE_OK: Int32 =          0   /* Successful result */
let SQLITE_ERROR: Int32 =       1   /* Generic error */
let SQLITE_INTERNAL: Int32 =    2   /* Internal logic error in SQLite */
let SQLITE_PERM: Int32 =        3   /* Access permission denied */
let SQLITE_ABORT: Int32 =       4   /* Callback routine requested an abort */
let SQLITE_BUSY: Int32 =        5   /* The database file is locked */
let SQLITE_LOCKED: Int32 =      6   /* A table in the database is locked */
let SQLITE_NOMEM: Int32 =       7   /* A malloc() failed */
let SQLITE_READONLY: Int32 =    8   /* Attempt to write a readonly database */
let SQLITE_INTERRUPT: Int32 =   9   /* Operation terminated by sqlite3_interrupt()*/
let SQLITE_IOERR: Int32 =      10   /* Some kind of disk I/O error occurred */
let SQLITE_CORRUPT: Int32 =    11   /* The database disk image is malformed */
let SQLITE_NOTFOUND: Int32 =   12   /* Unknown opcode in sqlite3_file_control() */
let SQLITE_FULL: Int32 =       13   /* Insertion failed because database is full */
let SQLITE_CANTOPEN: Int32 =   14   /* Unable to open the database file */
let SQLITE_PROTOCOL: Int32 =   15   /* Database lock protocol error */
let SQLITE_EMPTY: Int32 =      16   /* Internal use only */
let SQLITE_SCHEMA: Int32 =     17   /* The database schema changed */
let SQLITE_TOOBIG: Int32 =     18   /* String or BLOB exceeds size limit */
let SQLITE_CONSTRAINT: Int32 = 19   /* Abort due to constraint violation */
let SQLITE_MISMATCH: Int32 =   20   /* Data type mismatch */
let SQLITE_MISUSE: Int32 =     21   /* Library used incorrectly */
let SQLITE_NOLFS: Int32 =      22   /* Uses OS features not supported on host */
let SQLITE_AUTH: Int32 =       23   /* Authorization denied */
let SQLITE_FORMAT: Int32 =     24   /* Not used */
let SQLITE_RANGE: Int32 =      25   /* 2nd parameter to sqlite3_bind out of range */
let SQLITE_NOTADB: Int32 =     26   /* File opened that is not a database file */
let SQLITE_NOTICE: Int32 =     27   /* Notifications from sqlite3_log() */
let SQLITE_WARNING: Int32 =    28   /* Warnings from sqlite3_log() */
let SQLITE_ROW: Int32 =        100  /* sqlite3_step() has another row ready */
let SQLITE_DONE: Int32 =       101  /* sqlite3_step() has finished executing */

// MARK Extended Result Codes

let SQLITE_ERROR_MISSING_COLLSEQ: Int32 =   (SQLITE_ERROR | (1<<8))
let SQLITE_ERROR_RETRY: Int32 =             (SQLITE_ERROR | (2<<8))
let SQLITE_ERROR_SNAPSHOT: Int32 =          (SQLITE_ERROR | (3<<8))
let SQLITE_IOERR_READ: Int32 =              (SQLITE_IOERR | (1<<8))
let SQLITE_IOERR_SHORT_READ: Int32 =        (SQLITE_IOERR | (2<<8))
let SQLITE_IOERR_WRITE: Int32 =             (SQLITE_IOERR | (3<<8))
let SQLITE_IOERR_FSYNC: Int32 =             (SQLITE_IOERR | (4<<8))
let SQLITE_IOERR_DIR_FSYNC: Int32 =         (SQLITE_IOERR | (5<<8))
let SQLITE_IOERR_TRUNCATE: Int32 =          (SQLITE_IOERR | (6<<8))
let SQLITE_IOERR_FSTAT: Int32 =             (SQLITE_IOERR | (7<<8))
let SQLITE_IOERR_UNLOCK: Int32 =            (SQLITE_IOERR | (8<<8))
let SQLITE_IOERR_RDLOCK: Int32 =            (SQLITE_IOERR | (9<<8))
let SQLITE_IOERR_DELETE: Int32 =            (SQLITE_IOERR | (10<<8))
let SQLITE_IOERR_BLOCKED: Int32 =           (SQLITE_IOERR | (11<<8))
let SQLITE_IOERR_NOMEM: Int32 =             (SQLITE_IOERR | (12<<8))
let SQLITE_IOERR_ACCESS: Int32 =            (SQLITE_IOERR | (13<<8))
let SQLITE_IOERR_CHECKRESERVEDLOCK: Int32 = (SQLITE_IOERR | (14<<8))
let SQLITE_IOERR_LOCK: Int32 =              (SQLITE_IOERR | (15<<8))
let SQLITE_IOERR_CLOSE: Int32 =             (SQLITE_IOERR | (16<<8))
let SQLITE_IOERR_DIR_CLOSE: Int32 =         (SQLITE_IOERR | (17<<8))
let SQLITE_IOERR_SHMOPEN: Int32 =           (SQLITE_IOERR | (18<<8))
let SQLITE_IOERR_SHMSIZE: Int32 =           (SQLITE_IOERR | (19<<8))
let SQLITE_IOERR_SHMLOCK: Int32 =           (SQLITE_IOERR | (20<<8))
let SQLITE_IOERR_SHMMAP: Int32 =            (SQLITE_IOERR | (21<<8))
let SQLITE_IOERR_SEEK: Int32 =              (SQLITE_IOERR | (22<<8))
let SQLITE_IOERR_DELETE_NOENT: Int32 =      (SQLITE_IOERR | (23<<8))
let SQLITE_IOERR_MMAP: Int32 =              (SQLITE_IOERR | (24<<8))
let SQLITE_IOERR_GETTEMPPATH: Int32 =       (SQLITE_IOERR | (25<<8))
let SQLITE_IOERR_CONVPATH: Int32 =          (SQLITE_IOERR | (26<<8))
let SQLITE_IOERR_VNODE: Int32 =             (SQLITE_IOERR | (27<<8))
let SQLITE_IOERR_AUTH: Int32 =              (SQLITE_IOERR | (28<<8))
let SQLITE_IOERR_BEGIN_ATOMIC: Int32 =      (SQLITE_IOERR | (29<<8))
let SQLITE_IOERR_COMMIT_ATOMIC: Int32 =     (SQLITE_IOERR | (30<<8))
let SQLITE_IOERR_ROLLBACK_ATOMIC: Int32 =   (SQLITE_IOERR | (31<<8))
let SQLITE_IOERR_DATA: Int32 =              (SQLITE_IOERR | (32<<8))
let SQLITE_IOERR_CORRUPTFS: Int32 =         (SQLITE_IOERR | (33<<8))
let SQLITE_IOERR_IN_PAGE: Int32 =           (SQLITE_IOERR | (34<<8))
let SQLITE_LOCKED_SHAREDCACHE: Int32 =      (SQLITE_LOCKED |  (1<<8))
let SQLITE_LOCKED_VTAB: Int32 =             (SQLITE_LOCKED |  (2<<8))
let SQLITE_BUSY_RECOVERY: Int32 =           (SQLITE_BUSY   |  (1<<8))
let SQLITE_BUSY_SNAPSHOT: Int32 =           (SQLITE_BUSY   |  (2<<8))
let SQLITE_BUSY_TIMEOUT: Int32 =            (SQLITE_BUSY   |  (3<<8))
let SQLITE_CANTOPEN_NOTEMPDIR: Int32 =      (SQLITE_CANTOPEN | (1<<8))
let SQLITE_CANTOPEN_ISDIR: Int32 =          (SQLITE_CANTOPEN | (2<<8))
let SQLITE_CANTOPEN_FULLPATH: Int32 =       (SQLITE_CANTOPEN | (3<<8))
let SQLITE_CANTOPEN_CONVPATH: Int32 =       (SQLITE_CANTOPEN | (4<<8))
let SQLITE_CANTOPEN_DIRTYWAL: Int32 =       (SQLITE_CANTOPEN | (5<<8)) /* Not Used */
let SQLITE_CANTOPEN_SYMLINK: Int32 =        (SQLITE_CANTOPEN | (6<<8))
let SQLITE_CORRUPT_VTAB: Int32 =            (SQLITE_CORRUPT | (1<<8))
let SQLITE_CORRUPT_SEQUENCE: Int32 =        (SQLITE_CORRUPT | (2<<8))
let SQLITE_CORRUPT_INDEX: Int32 =           (SQLITE_CORRUPT | (3<<8))
let SQLITE_READONLY_RECOVERY: Int32 =       (SQLITE_READONLY | (1<<8))
let SQLITE_READONLY_CANTLOCK: Int32 =       (SQLITE_READONLY | (2<<8))
let SQLITE_READONLY_ROLLBACK: Int32 =       (SQLITE_READONLY | (3<<8))
let SQLITE_READONLY_DBMOVED: Int32 =        (SQLITE_READONLY | (4<<8))
let SQLITE_READONLY_CANTINIT: Int32 =       (SQLITE_READONLY | (5<<8))
let SQLITE_READONLY_DIRECTORY: Int32 =      (SQLITE_READONLY | (6<<8))
let SQLITE_ABORT_ROLLBACK: Int32 =          (SQLITE_ABORT | (2<<8))
let SQLITE_CONSTRAINT_CHECK: Int32 =        (SQLITE_CONSTRAINT | (1<<8))
let SQLITE_CONSTRAINT_COMMITHOOK: Int32 =   (SQLITE_CONSTRAINT | (2<<8))
let SQLITE_CONSTRAINT_FOREIGNKEY: Int32 =   (SQLITE_CONSTRAINT | (3<<8))
let SQLITE_CONSTRAINT_FUNCTION: Int32 =     (SQLITE_CONSTRAINT | (4<<8))
let SQLITE_CONSTRAINT_NOTNULL: Int32 =      (SQLITE_CONSTRAINT | (5<<8))
let SQLITE_CONSTRAINT_PRIMARYKEY: Int32 =   (SQLITE_CONSTRAINT | (6<<8))
let SQLITE_CONSTRAINT_TRIGGER: Int32 =      (SQLITE_CONSTRAINT | (7<<8))
let SQLITE_CONSTRAINT_UNIQUE: Int32 =       (SQLITE_CONSTRAINT | (8<<8))
let SQLITE_CONSTRAINT_VTAB: Int32 =         (SQLITE_CONSTRAINT | (9<<8))
let SQLITE_CONSTRAINT_ROWID: Int32 =        (SQLITE_CONSTRAINT | (10<<8))
let SQLITE_CONSTRAINT_PINNED: Int32 =       (SQLITE_CONSTRAINT | (11<<8))
let SQLITE_CONSTRAINT_DATATYPE: Int32 =     (SQLITE_CONSTRAINT | (12<<8))
let SQLITE_NOTICE_RECOVER_WAL: Int32 =      (SQLITE_NOTICE | (1<<8))
let SQLITE_NOTICE_RECOVER_ROLLBACK: Int32 = (SQLITE_NOTICE | (2<<8))
let SQLITE_NOTICE_RBU: Int32 =              (SQLITE_NOTICE | (3<<8))
let SQLITE_WARNING_AUTOINDEX: Int32 =       (SQLITE_WARNING | (1<<8))
let SQLITE_AUTH_USER: Int32 =               (SQLITE_AUTH | (1<<8))
let SQLITE_OK_LOAD_PERMANENTLY: Int32 =     (SQLITE_OK | (1<<8))
let SQLITE_OK_SYMLINK: Int32 =              (SQLITE_OK | (2<<8)) /* internal use only */


// MARK: SQLite Open File Flags

let SQLITE_OPEN_READONLY: Int32 =       0x00000001  /* Ok for sqlite3_open_v2() */
let SQLITE_OPEN_READWRITE: Int32 =      0x00000002  /* Ok for sqlite3_open_v2() */
let SQLITE_OPEN_CREATE: Int32 =         0x00000004  /* Ok for sqlite3_open_v2() */
let SQLITE_OPEN_DELETEONCLOSE: Int32 =  0x00000008  /* VFS only */
let SQLITE_OPEN_EXCLUSIVE: Int32 =      0x00000010  /* VFS only */
let SQLITE_OPEN_AUTOPROXY: Int32 =      0x00000020  /* VFS only */
let SQLITE_OPEN_URI: Int32 =            0x00000040  /* Ok for sqlite3_open_v2() */
let SQLITE_OPEN_MEMORY: Int32 =         0x00000080  /* Ok for sqlite3_open_v2() */
let SQLITE_OPEN_MAIN_DB: Int32 =        0x00000100  /* VFS only */
let SQLITE_OPEN_TEMP_DB: Int32 =        0x00000200  /* VFS only */
let SQLITE_OPEN_TRANSIENT_DB: Int32 =   0x00000400  /* VFS only */
let SQLITE_OPEN_MAIN_JOURNAL: Int32 =   0x00000800  /* VFS only */
let SQLITE_OPEN_TEMP_JOURNAL: Int32 =   0x00001000  /* VFS only */
let SQLITE_OPEN_SUBJOURNAL: Int32 =     0x00002000  /* VFS only */
let SQLITE_OPEN_SUPER_JOURNAL: Int32 =  0x00004000  /* VFS only */
let SQLITE_OPEN_NOMUTEX: Int32 =        0x00008000  /* Ok for sqlite3_open_v2() */
let SQLITE_OPEN_FULLMUTEX: Int32 =      0x00010000  /* Ok for sqlite3_open_v2() */
let SQLITE_OPEN_SHAREDCACHE: Int32 =    0x00020000  /* Ok for sqlite3_open_v2() */
let SQLITE_OPEN_PRIVATECACHE: Int32 =   0x00040000  /* Ok for sqlite3_open_v2() */
let SQLITE_OPEN_WAL: Int32 =            0x00080000  /* VFS only */
let SQLITE_OPEN_NOFOLLOW: Int32 =       0x01000000  /* Ok for sqlite3_open_v2() */
let SQLITE_OPEN_EXRESCODE: Int32 =      0x02000000  /* Extended result codes */

//let SQLITE_TRANSIENT = Int64(-1)
let SQLITE_INSERT = SQLAction.insert.rawValue
let SQLITE_DELETE = SQLAction.delete.rawValue
let SQLITE_UPDATE = SQLAction.update.rawValue

let SQLITE_INTEGER = SQLType.integer.rawValue
let SQLITE_FLOAT = SQLType.float.rawValue
let SQLITE_TEXT = SQLType.text.rawValue
let SQLITE_BLOB = SQLType.blob.rawValue
let SQLITE_NULL = SQLType.null.rawValue


=======
>>>>>>> d0c842f (Add SkipSQLDB module)
