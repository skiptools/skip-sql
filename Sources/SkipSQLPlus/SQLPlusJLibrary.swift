// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

#if SKIP
import Foundation
import OSLog
import SkipFFI
import SkipSQL

/// A concrete implementation of the `SQLiteLibrary` interface that declared `external` methods to use [JNA Direct Mapping](https://github.com/java-native-access/jna/blob/master/www/DirectMapping.md) to cache native method lookups.
///
/// Note that this is identical to the `SkipSQL.SQLLiteJNALibrary`, but it is registered
/// to the locally-built `sqlext` library.
internal final class SQLPlusJNALibrary : SQLiteLibrary {
    static let shared = registerNatives(SQLPlusJNALibrary(), frameworkName: "SkipSQLPlus", libraryName: "sqlext")

    /* SKIP INSERT: external */ func sqlite3_sleep(_ duration: Int32) -> Int32
    /* SKIP INSERT: external override */ public func sqlite3_open(_ filename: String, _ ppDb: sqlite3_openarg?) -> Int32
    /* SKIP INSERT: external override */ public func sqlite3_open_v2(_ filename: String, _ ppDb: sqlite3_openarg?, _ flags: Int32, _ vfs: String?) -> Int32
    /* SKIP INSERT: external */ func sqlite3_close(_ db: OpaquePointer) -> Int32
    /* SKIP INSERT: external */ func sqlite3_errcode(_ db: OpaquePointer) -> Int32
    /* SKIP INSERT: external */ func sqlite3_errmsg(_ db: OpaquePointer) -> sqlite3_cstring_ptr?
    /* SKIP INSERT: external */ func sqlite3_extended_errcode(_ db: OpaquePointer) -> Int32
    /* SKIP INSERT: external */ func sqlite3_last_insert_rowid(_ db: OpaquePointer) -> Int64
    /* SKIP INSERT: external */ func sqlite3_total_changes(_ db: OpaquePointer) -> Int32
    /* SKIP INSERT: external */ func sqlite3_changes(_ db: OpaquePointer) -> Int32
    // /* SKIP INSERT: external */ func sqlite3_total_changes64(_ db: OpaquePointer) -> Int64
    // /* SKIP INSERT: external */ func sqlite3_changes64(_ db: OpaquePointer) -> Int64 // unavailable on Android
    /* SKIP INSERT: external */ func sqlite3_interrupt(_ db: OpaquePointer)
    /* SKIP INSERT: external override */ public func sqlite3_db_filename(_ db: OpaquePointer, _ zDbName: sqlite3_cstring_ptr?) -> sqlite3_cstring_ptr?
    /* SKIP INSERT: external override */ public func sqlite3_exec(_ db: OpaquePointer, _ sql: String, _ callback: sqlite3_callback?, _ pArg: UnsafeMutableRawPointer?, _ errmsg: sqlite_error_ptr?) -> Int32
    /* SKIP INSERT: external override */ public func sqlite3_prepare_v2(_ db: OpaquePointer, _ sql: String, _ nBytes: Int32, _ ppStmt: sqlite3_openarg, _ tail: sqlite_tail_ptr?) -> Int32
    /* SKIP INSERT: external */ func sqlite3_step(_ stmt: OpaquePointer?) -> Int32
    /* SKIP INSERT: external */ func sqlite3_finalize(_ stmt: OpaquePointer?) -> Int32
    /* SKIP INSERT: external */ func sqlite3_reset(_ stmt: OpaquePointer?) -> Int32
    /* SKIP INSERT: external */ func sqlite3_column_count(_ stmt: OpaquePointer?) -> Int32
    /* SKIP INSERT: external */ func sqlite3_bind_parameter_count(_ stmt: OpaquePointer?) -> Int32
    /* SKIP INSERT: external */ func sqlite3_bind_parameter_name(_ stmt: OpaquePointer?, _ columnIndex: Int32) -> sqlite3_cstring_ptr?
    /* SKIP INSERT: external */ func sqlite3_bind_parameter_index(_ stmt: OpaquePointer?, _ name: String) -> Int32
    /* SKIP INSERT: external */ func sqlite3_clear_bindings(_ stmt: OpaquePointer?) -> Int32
    /* SKIP INSERT: external */ func sqlite3_column_name(_ stmt: OpaquePointer?!, _ columnIndex: Int32) -> sqlite3_cstring_ptr?
    // /* SKIP INSERT: external */ func sqlite3_column_database_name(_ stmt: OpaquePointer?, _ columnIndex: Int32) -> sqlite3_cstring_ptr? // unavailable on Android
    // /* SKIP INSERT: external */ func sqlite3_column_origin_name(_ stmt: OpaquePointer?, _ columnIndex: Int32) -> sqlite3_cstring_ptr?
    /* SKIP INSERT: external */ func sqlite3_column_decltype(_ stmt: OpaquePointer?, _ columnIndex: Int32) -> sqlite3_cstring_ptr?
    /* SKIP INSERT: external */ func sqlite3_sql(_ stmt: OpaquePointer?) -> sqlite3_cstring_ptr?
    /* SKIP INSERT: external */ func sqlite3_db_handle(_ stmt: OpaquePointer?) -> OpaquePointer
    /* SKIP INSERT: external */ func sqlite3_bind_null(_ stmt: OpaquePointer?, _ paramIndex: Int32) -> Int32
    /* SKIP INSERT: external */ func sqlite3_bind_int(_ stmt: OpaquePointer?, _ paramIndex: Int32, _ value: Int32) -> Int32
    /* SKIP INSERT: external */ func sqlite3_bind_int64(_ stmt: OpaquePointer?, _ paramIndex: Int32, _ value: Int64) -> Int32
    /* SKIP INSERT: external */ func sqlite3_bind_double(_ stmt: OpaquePointer?, _ paramIndex: Int32, _ value: Double) -> Int32
    /* SKIP INSERT: external */ func sqlite3_bind_text(_ stmt: OpaquePointer?, _ paramIndex: Int32, _ value: String, _ length: Int32, _ destructor: sqlite3_destructor_type) -> Int32
    /* SKIP INSERT: external override */ public func sqlite3_bind_blob(_ stmt: OpaquePointer?, _ paramIndex: Int32, _ value: UnsafeRawPointer?, _ length: Int32, _ destructor: sqlite3_destructor_type) -> Int32
    /* SKIP INSERT: external */ func sqlite3_bind_zeroblob(_ stmt: OpaquePointer?, _ paramIndex: Int32, _ length: Int32) -> Int32
    /* SKIP INSERT: external */ func sqlite3_column_type(_ stmt: OpaquePointer?, _ columnIndex: Int32) -> Int32
    /* SKIP INSERT: external */ func sqlite3_column_int(_ stmt: OpaquePointer?, _ columnIndex: Int32) -> Int32
    /* SKIP INSERT: external */ func sqlite3_column_int64(_ stmt: OpaquePointer?, _ columnIndex: Int32) -> Int64
    /* SKIP INSERT: external */ func sqlite3_column_double(_ stmt: OpaquePointer?, _ columnIndex: Int32) -> Double
    /* SKIP INSERT: external */ func sqlite3_column_text(_ stmt: OpaquePointer?, _ columnIndex: Int32) -> sqlite3_uint8_ptr?
    /* SKIP INSERT: external */ func sqlite3_column_blob(_ stmt: OpaquePointer?, _ columnIndex: Int32) -> UnsafeRawPointer?
    /* SKIP INSERT: external */ func sqlite3_column_bytes(_ stmt: OpaquePointer?, _ columnIndex: Int32) -> Int32
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

#endif
