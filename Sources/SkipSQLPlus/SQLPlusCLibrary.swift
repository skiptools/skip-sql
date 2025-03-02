// Copyright 2023–2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
#if !SKIP
import SQLExt
import SkipSQL

/// A `SQLiteLibrary` implementation that uses the locally built `SQLExt` library
/// to provide a consistent SQLite build with full-text-search (FTS) and encryption (sqlcipher)
/// extensions enabled.
internal final class SQLPlusCLibrary : SQLiteLibrary {
    static let shared = SQLPlusCLibrary()

    init() {
    }

    func sqlite3_sleep(_ duration: Int32) -> Int32 {
        SQLExt.sqlite3_sleep(duration)
    }

    func sqlite3_open(_ filename: String, _ ppDb: sqlite3_openarg?) -> Int32 {
        SQLExt.sqlite3_open(filename, ppDb)
    }

    func sqlite3_open_v2(_ filename: String, _ ppDb: sqlite3_openarg?, _ flags: Int32, _ vfs: String?) -> Int32 {
        SQLExt.sqlite3_open_v2(filename, ppDb, flags, vfs)
    }

    func sqlite3_close(_ db: OpaquePointer) -> Int32 {
        SQLExt.sqlite3_close(db)
    }

    func sqlite3_errcode(_ db: OpaquePointer) -> Int32 {
        SQLExt.sqlite3_errcode(db)
    }

    func sqlite3_errmsg(_ db: OpaquePointer) -> sqlite3_cstring_ptr? {
        SQLExt.sqlite3_errmsg(db)
    }

    func sqlite3_extended_errcode(_ db: OpaquePointer) -> Int32 {
        SQLExt.sqlite3_extended_errcode(db)
    }

    func sqlite3_last_insert_rowid(_ db: OpaquePointer) -> Int64 {
        SQLExt.sqlite3_last_insert_rowid(db)
    }

    func sqlite3_total_changes(_ db: OpaquePointer) -> Int32 {
        SQLExt.sqlite3_total_changes(db)
    }

    func sqlite3_changes(_ db: OpaquePointer) -> Int32 {
        SQLExt.sqlite3_changes(db)
    }

    func sqlite3_interrupt(_ db: OpaquePointer) {
        SQLExt.sqlite3_interrupt(db)
    }

    func sqlite3_db_filename(_ db: OpaquePointer, _ zDbName: sqlite3_cstring_ptr?) -> sqlite3_cstring_ptr? {
        SQLExt.sqlite3_db_filename(db, zDbName)
    }

    func sqlite3_exec(_ db: OpaquePointer, _ sql: String, _ callback: sqlite3_callback?, _ pArg: UnsafeMutableRawPointer?, _ errmsg: sqlite_error_ptr?) -> Int32 {
        SQLExt.sqlite3_exec(db, sql, callback, pArg, errmsg)
    }

    func sqlite3_prepare_v2(_ db: OpaquePointer, _ sql: String, _ nBytes: Int32, _ ppStmt: sqlite3_openarg, _ tail: UnsafeMutablePointer<UnsafePointer<CChar>?>?) -> Int32 {
        SQLExt.sqlite3_prepare_v2(db, sql, nBytes, ppStmt, tail)
    }

    func sqlite3_step(_ stmt: OpaquePointer?) -> Int32 {
        SQLExt.sqlite3_step(stmt)
    }

    func sqlite3_finalize(_ stmt: OpaquePointer?) -> Int32 {
        SQLExt.sqlite3_finalize(stmt)
    }

    func sqlite3_reset(_ stmt: OpaquePointer?) -> Int32 {
        SQLExt.sqlite3_reset(stmt)
    }

    func sqlite3_column_count(_ stmt: OpaquePointer?) -> Int32 {
        SQLExt.sqlite3_column_count(stmt)
    }

    func sqlite3_bind_parameter_count(_ stmt: OpaquePointer?) -> Int32 {
        SQLExt.sqlite3_bind_parameter_count(stmt)
    }

    func sqlite3_bind_parameter_name(_ stmt: OpaquePointer?, _ columnIndex: Int32) -> sqlite3_cstring_ptr? {
        SQLExt.sqlite3_bind_parameter_name(stmt, columnIndex)
    }

    func sqlite3_bind_parameter_index(_ stmt: OpaquePointer?, _ name: String) -> Int32 {
        SQLExt.sqlite3_bind_parameter_index(stmt, name)
    }

    func sqlite3_clear_bindings(_ stmt: OpaquePointer?) -> Int32 {
        SQLExt.sqlite3_clear_bindings(stmt)
    }

    func sqlite3_column_name(_ stmt: OpaquePointer?, _ columnIndex: Int32) -> sqlite3_cstring_ptr? {
        SQLExt.sqlite3_column_name(stmt!, columnIndex)
    }

    func sqlite3_column_decltype(_ stmt: OpaquePointer?, _ columnIndex: Int32) -> sqlite3_cstring_ptr? {
        SQLExt.sqlite3_column_decltype(stmt, columnIndex)
    }

    func sqlite3_sql(_ stmt: OpaquePointer?) -> sqlite3_cstring_ptr? {
        SQLExt.sqlite3_sql(stmt)
    }

    func sqlite3_db_handle(_ stmt: OpaquePointer?) -> OpaquePointer {
        SQLExt.sqlite3_db_handle(stmt)
    }

    func sqlite3_bind_null(_ stmt: OpaquePointer?, _ paramIndex: Int32) -> Int32 {
        SQLExt.sqlite3_bind_null(stmt, paramIndex)
    }

    func sqlite3_bind_int(_ stmt: OpaquePointer?, _ paramIndex: Int32, _ value: Int32) -> Int32 {
        SQLExt.sqlite3_bind_int(stmt, paramIndex, value)
    }

    func sqlite3_bind_int64(_ stmt: OpaquePointer?, _ paramIndex: Int32, _ value: Int64) -> Int32 {
        SQLExt.sqlite3_bind_int64(stmt, paramIndex, value)
    }

    func sqlite3_bind_double(_ stmt: OpaquePointer?, _ paramIndex: Int32, _ value: Double) -> Int32 {
        SQLExt.sqlite3_bind_double(stmt, paramIndex, value)
    }

    func sqlite3_bind_text(_ stmt: OpaquePointer?, _ paramIndex: Int32, _ value: String, _ length: Int32, _ destructor: sqlite3_destructor_type) -> Int32 {
        SQLExt.sqlite3_bind_text(stmt, paramIndex, value, length, destructor)
    }

    func sqlite3_bind_blob(_ stmt: OpaquePointer?, _ paramIndex: Int32, _ value: UnsafeRawPointer?, _ length: Int32, _ destructor: sqlite3_destructor_type) -> Int32 {
        SQLExt.sqlite3_bind_blob(stmt, paramIndex, value, length, destructor)
    }

    func sqlite3_bind_zeroblob(_ stmt: OpaquePointer?, _ paramIndex: Int32, _ length: Int32) -> Int32 {
        SQLExt.sqlite3_bind_zeroblob(stmt, paramIndex, length)
    }

    func sqlite3_column_type(_ stmt: OpaquePointer?, _ columnIndex: Int32) -> Int32 {
        SQLExt.sqlite3_column_type(stmt, columnIndex)
    }

    func sqlite3_column_int(_ stmt: OpaquePointer?, _ columnIndex: Int32) -> Int32 {
        SQLExt.sqlite3_column_int(stmt, columnIndex)
    }

    func sqlite3_column_int64(_ stmt: OpaquePointer?, _ columnIndex: Int32) -> Int64 {
        SQLExt.sqlite3_column_int64(stmt, columnIndex)
    }

    func sqlite3_column_double(_ stmt: OpaquePointer?, _ columnIndex: Int32) -> Double {
        SQLExt.sqlite3_column_double(stmt, columnIndex)
    }

    func sqlite3_column_text(_ stmt: OpaquePointer?, _ columnIndex: Int32) -> sqlite3_uint8_ptr? {
        SQLExt.sqlite3_column_text(stmt, columnIndex)
    }

    func sqlite3_column_blob(_ stmt: OpaquePointer?, _ columnIndex: Int32) -> UnsafeRawPointer? {
        SQLExt.sqlite3_column_blob(stmt, columnIndex)
    }

    func sqlite3_column_bytes(_ stmt: OpaquePointer?, _ columnIndex: Int32) -> Int32 {
        SQLExt.sqlite3_column_bytes(stmt, columnIndex)
    }

    func sqlite3_backup_init(_ destDb: OpaquePointer, _ destName: String, _ sourceDb: OpaquePointer?, _ sourceName: String) -> OpaquePointer {
        SQLExt.sqlite3_backup_init(destDb, destName, sourceDb, sourceName)
    }

    func sqlite3_backup_step(_ backup: OpaquePointer, _ pages: Int32) -> Int32 {
        SQLExt.sqlite3_backup_step(backup, pages)
    }

    func sqlite3_backup_finish(_ backup: OpaquePointer) -> Int32 {
        SQLExt.sqlite3_backup_finish(backup)
    }

    func sqlite3_backup_remaining(_ backup: OpaquePointer) -> Int32 {
        SQLExt.sqlite3_backup_remaining(backup)
    }

    func sqlite3_backup_pagecount(_ backup: OpaquePointer) -> Int32 {
        SQLExt.sqlite3_backup_pagecount(backup)
    }

    func sqlite3_initialize() -> Int32 {
        SQLExt.sqlite3_initialize()
    }

    func sqlite3_shutdown() -> Int32 {
        SQLExt.sqlite3_shutdown()
    }

    func sqlite3_extended_result_codes(_ db: OpaquePointer, _ on: Int32) -> Int32 {
        SQLExt.sqlite3_extended_result_codes(db, on)
    }

    func sqlite3_db_mutex(_ db: OpaquePointer?) -> OpaquePointer? {
        SQLExt.sqlite3_db_mutex(db)
    }

    func sqlite3_mutex_free(_ lock: OpaquePointer?) {
        SQLExt.sqlite3_mutex_free(lock)
    }

    func sqlite3_mutex_enter(_ lock: OpaquePointer?) {
        SQLExt.sqlite3_mutex_enter(lock)
    }

    func sqlite3_mutex_leave(_ lock: OpaquePointer?) {
        SQLExt.sqlite3_mutex_leave(lock)
    }

    func sqlite3_update_hook(_ db: OpaquePointer?, _ callback: sqlite3_update_hook?, _ pArg: UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer? {
        SQLExt.sqlite3_update_hook(db, callback, pArg)
    }
}
#endif

