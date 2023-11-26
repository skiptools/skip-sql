// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

#if !SKIP
import SQLite3

public typealias sqlite3_int64 = SQLite3.sqlite3_int64
/// An action that can be registered to receive updates whenever a ROWID table changes
/// `((UnsafeMutableRawPointer?, Int32, UnsafePointer<CChar>?, UnsafePointer<CChar>?, sqlite3_int64) -> Void)`
public typealias sqlite3_update_hook = @convention(c) (_ updateActionPtr: UnsafeMutableRawPointer?, _ operation: Int32, _ dbname: UnsafePointer<CChar>?, _ tblname: UnsafePointer<CChar>?, _ rowid: sqlite3_int64) -> ()

public let SQLITE_DONE = 101
public let SQLITE_ROW = 100

public typealias sqlite3_destructor_type = SQLite3.sqlite3_destructor_type
public typealias sqlite3_callback = SQLite3.sqlite3_callback

public let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

internal final class SQLitePlatformLibrary : SQLiteCLibrary {
}

open class SQLiteCLibrary : SQLiteLibrary {
    public init() {
    }

    open func sqlite3_sleep(_ duration: Int32) -> Int32 {
        SQLite3.sqlite3_sleep(duration)
    }

    open func sqlite3_open(_ filename: String, _ ppDb: sqlite3_openarg?) -> Int32 {
        SQLite3.sqlite3_open(filename, ppDb)
    }

    open func sqlite3_open_v2(_ filename: String, _ ppDb: sqlite3_openarg?, _ flags: Int32, _ vfs: String?) -> Int32 {
        SQLite3.sqlite3_open_v2(filename, ppDb, flags, vfs)
    }

    open func sqlite3_close(_ db: OpaquePointer) -> Int32 {
        SQLite3.sqlite3_close(db)
    }

    open func sqlite3_errcode(_ db: OpaquePointer) -> Int32 {
        SQLite3.sqlite3_errcode(db)
    }

    open func sqlite3_errmsg(_ db: OpaquePointer) -> sqlite3_cstring_ptr? {
        SQLite3.sqlite3_errmsg(db)
    }

    open func sqlite3_last_insert_rowid(_ db: OpaquePointer) -> Int64 {
        SQLite3.sqlite3_last_insert_rowid(db)
    }

    open func sqlite3_total_changes(_ db: OpaquePointer) -> Int32 {
        SQLite3.sqlite3_total_changes(db)
    }

    open func sqlite3_changes(_ db: OpaquePointer) -> Int32 {
        SQLite3.sqlite3_changes(db)
    }

    open func sqlite3_total_changes64(_ db: OpaquePointer) -> Int64 {
        SQLite3.sqlite3_total_changes64(db)
    }

    open func sqlite3_changes64(_ db: OpaquePointer) -> Int64 {
        SQLite3.sqlite3_changes64(db)
    }

    open func sqlite3_interrupt(_ db: OpaquePointer) {
        SQLite3.sqlite3_interrupt(db)
    }

    open func sqlite3_exec(_ db: OpaquePointer, _ sql: String, _ callback: sqlite3_callback, _ pArg: UnsafeMutableRawPointer?, _ errmsg: sqlite_error_ptr?) -> Int32 {
        SQLite3.sqlite3_exec(db, sql, callback, pArg, errmsg)
    }

    open func sqlite3_prepare_v2(_ db: OpaquePointer, _ sql: String, _ nBytes: Int32, _ ppStmt: sqlite3_openarg, _ tail: UnsafeMutablePointer<UnsafePointer<CChar>?>?) -> Int32 {
        SQLite3.sqlite3_prepare_v2(db, sql, nBytes, ppStmt, tail)
    }

    open func sqlite3_step(_ stmt: OpaquePointer) -> Int32 {
        SQLite3.sqlite3_step(stmt)
    }

    open func sqlite3_finalize(_ stmt: OpaquePointer) -> Int32 {
        SQLite3.sqlite3_finalize(stmt)
    }

    open func sqlite3_reset(_ stmt: OpaquePointer) -> Int32 {
        SQLite3.sqlite3_reset(stmt)
    }

    open func sqlite3_column_count(_ stmt: OpaquePointer) -> Int32 {
        SQLite3.sqlite3_column_count(stmt)
    }

    open func sqlite3_bind_parameter_count(_ stmnt: OpaquePointer) -> Int32 {
        SQLite3.sqlite3_bind_parameter_count(stmnt)
    }

    open func sqlite3_bind_parameter_name(_ stmnt: OpaquePointer, _ columnIndex: Int32) -> sqlite3_cstring_ptr? {
        SQLite3.sqlite3_bind_parameter_name(stmnt, columnIndex)
    }

    open func sqlite3_bind_parameter_index(_ stmnt: OpaquePointer, _ name: String) -> Int32 {
        SQLite3.sqlite3_bind_parameter_index(stmnt, name)
    }

    open func sqlite3_clear_bindings(_ stmnt: OpaquePointer) -> Int32 {
        SQLite3.sqlite3_clear_bindings(stmnt)
    }

    open func sqlite3_column_name(_ stmt: OpaquePointer!, _ columnIndex: Int32) -> sqlite3_cstring_ptr? {
        SQLite3.sqlite3_column_name(stmt!, columnIndex)
    }

    open func sqlite3_column_database_name(_ stmt: OpaquePointer, _ columnIndex: Int32) -> sqlite3_cstring_ptr? {
        SQLite3.sqlite3_column_database_name(stmt, columnIndex)
    }

    open func sqlite3_column_origin_name(_ stmt: OpaquePointer, _ columnIndex: Int32) -> sqlite3_cstring_ptr? {
        SQLite3.sqlite3_column_origin_name(stmt, columnIndex)
    }

    open func sqlite3_column_decltype(_ stmt: OpaquePointer, _ columnIndex: Int32) -> sqlite3_cstring_ptr? {
        SQLite3.sqlite3_column_decltype(stmt, columnIndex)
    }

    open func sqlite3_sql(_ stmt: OpaquePointer) -> sqlite3_cstring_ptr? {
        SQLite3.sqlite3_sql(stmt)
    }

    open func sqlite3_db_handle(_ stmt: OpaquePointer) -> OpaquePointer {
        SQLite3.sqlite3_db_handle(stmt)
    }

    open func sqlite3_bind_null(_ stmt: OpaquePointer, _ paramIndex: Int32) -> Int32 {
        SQLite3.sqlite3_bind_null(stmt, paramIndex)
    }

    open func sqlite3_bind_int(_ stmt: OpaquePointer, _ paramIndex: Int32, _ value: Int32) -> Int32 {
        SQLite3.sqlite3_bind_int(stmt, paramIndex, value)
    }

    open func sqlite3_bind_int64(_ stmt: OpaquePointer, _ paramIndex: Int32, _ value: Int64) -> Int32 {
        SQLite3.sqlite3_bind_int64(stmt, paramIndex, value)
    }

    open func sqlite3_bind_double(_ stmt: OpaquePointer, _ paramIndex: Int32, _ value: Double) -> Int32 {
        SQLite3.sqlite3_bind_double(stmt, paramIndex, value)
    }

    open func sqlite3_bind_text(_ stmt: OpaquePointer, _ paramIndex: Int32, _ value: String, _ length: Int32, _ destructor: sqlite3_destructor_type) -> Int32 {
        SQLite3.sqlite3_bind_text(stmt, paramIndex, value, length, destructor)
    }

    open func sqlite3_bind_blob(_ stmt: OpaquePointer, _ paramIndex: Int32, _ value: UnsafeRawPointer?, _ length: Int32, _ destructor: sqlite3_destructor_type) -> Int32 {
        SQLite3.sqlite3_bind_blob(stmt, paramIndex, value, length, destructor)
    }

    open func sqlite3_bind_zeroblob(_ stmt: OpaquePointer, _ paramIndex: Int32, _ length: Int32) -> Int32 {
        SQLite3.sqlite3_bind_zeroblob(stmt, paramIndex, length)
    }

    open func sqlite3_column_type(_ stmt: OpaquePointer, _ columnIndex: Int32) -> Int32 {
        SQLite3.sqlite3_column_type(stmt, columnIndex)
    }

    open func sqlite3_column_int(_ stmt: OpaquePointer, _ columnIndex: Int32) -> Int32 {
        SQLite3.sqlite3_column_int(stmt, columnIndex)
    }

    open func sqlite3_column_int64(_ stmt: OpaquePointer, _ columnIndex: Int32) -> Int64 {
        SQLite3.sqlite3_column_int64(stmt, columnIndex)
    }

    open func sqlite3_column_double(_ stmt: OpaquePointer, _ columnIndex: Int32) -> Double {
        SQLite3.sqlite3_column_double(stmt, columnIndex)
    }

    open func sqlite3_column_text(_ stmt: OpaquePointer, _ columnIndex: Int32) -> sqlite3_uint8_ptr? {
        SQLite3.sqlite3_column_text(stmt, columnIndex)
    }

    open func sqlite3_column_blob(_ stmt: OpaquePointer, _ columnIndex: Int32) -> UnsafeRawPointer? {
        SQLite3.sqlite3_column_blob(stmt, columnIndex)
    }

    open func sqlite3_column_bytes(_ stmt: OpaquePointer, _ columnIndex: Int32) -> Int32 {
        SQLite3.sqlite3_column_bytes(stmt, columnIndex)
    }

    open func sqlite3_backup_init(_ destDb: OpaquePointer, _ destName: String, _ sourceDb: OpaquePointer?, _ sourceName: String) -> OpaquePointer {
        SQLite3.sqlite3_backup_init(destDb, destName, sourceDb, sourceName)
    }

    open func sqlite3_backup_step(_ backup: OpaquePointer, _ pages: Int32) -> Int32 {
        SQLite3.sqlite3_backup_step(backup, pages)
    }

    open func sqlite3_backup_finish(_ backup: OpaquePointer) -> Int32 {
        SQLite3.sqlite3_backup_finish(backup)
    }

    open func sqlite3_backup_remaining(_ backup: OpaquePointer) -> Int32 {
        SQLite3.sqlite3_backup_remaining(backup)
    }

    open func sqlite3_backup_pagecount(_ backup: OpaquePointer) -> Int32 {
        SQLite3.sqlite3_backup_pagecount(backup)
    }

    open func sqlite3_initialize() -> Int32 {
        SQLite3.sqlite3_initialize()
    }

    open func sqlite3_shutdown() -> Int32 {
        SQLite3.sqlite3_shutdown()
    }

    open func sqlite3_extended_result_codes(_ db: OpaquePointer, _ on: Int32) -> Int32 {
        SQLite3.sqlite3_extended_result_codes(db, on)
    }

    open func sqlite3_db_mutex(_ db: OpaquePointer?) -> OpaquePointer? {
        SQLite3.sqlite3_db_mutex(db)
    }

    open func sqlite3_mutex_free(_ lock: OpaquePointer?) {
        SQLite3.sqlite3_mutex_free(lock)
    }

    open func sqlite3_mutex_enter(_ lock: OpaquePointer?) {
        SQLite3.sqlite3_mutex_enter(lock)
    }

    open func sqlite3_mutex_leave(_ lock: OpaquePointer?) {
        SQLite3.sqlite3_mutex_leave(lock)
    }

    public func sqlite3_update_hook(_ db: OpaquePointer?, _ callback: sqlite3_update_hook?, _ pArg: UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer? {
        SQLite3.sqlite3_update_hook(db, callback, pArg)
    }
}
#endif

