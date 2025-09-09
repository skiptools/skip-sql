// Copyright 2023–2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
#if !SKIP

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Android)
import Android
#endif

#if canImport(SQLite3)
import SQLite3
#endif

/// The vendored SQLite3 library on Darwin platforms.
/// The version of this library will vary between OS version, so some features (e.g., JSON support) might not be available.
final class SQLiteCLibrary : SQLiteLibrary {
    static let shared = SQLiteCLibrary()

    init() {
    }

    func sqlite3_sleep(_ duration: Int32) -> Int32 {
        let sqlite3_sleep: (Int32) -> Int32
        #if canImport(SQLite3)
        sqlite3_sleep = SQLite3.sqlite3_sleep
        #else
        sqlite3_sleep = loadFunction("sqlite3_sleep")
        #endif
        return sqlite3_sleep(duration)
    }

    func sqlite3_open(_ filename: String, _ ppDb: sqlite3_openarg?) -> Int32 {
        let sqlite3_open: (UnsafePointer<CChar>?, UnsafeMutablePointer<OpaquePointer?>?) -> Int32
        #if canImport(SQLite3)
        sqlite3_open = SQLite3.sqlite3_open
        #else
        sqlite3_open = loadFunction("sqlite3_open")
        #endif
        return sqlite3_open(filename, ppDb)
    }

    func sqlite3_open_v2(_ filename: String, _ ppDb: sqlite3_openarg?, _ flags: Int32, _ vfs: String?) -> Int32 {
        let sqlite3_open_v2: (UnsafePointer<CChar>?, UnsafeMutablePointer<OpaquePointer?>?, Int32, UnsafePointer<CChar>?) -> Int32
        #if canImport(SQLite3)
        sqlite3_open_v2 = SQLite3.sqlite3_open_v2
        #else
        sqlite3_open_v2 = loadFunction("sqlite3_open_v2")
        #endif
        return sqlite3_open_v2(filename, ppDb, flags, vfs)
    }

    func sqlite3_close(_ db: OpaquePointer) -> Int32 {
        let sqlite3_close: (OpaquePointer?) -> Int32
        #if canImport(SQLite3)
        sqlite3_close = SQLite3.sqlite3_close
        #else
        sqlite3_close = loadFunction("sqlite3_close")
        #endif
        return sqlite3_close(db)
    }

    func sqlite3_errcode(_ db: OpaquePointer) -> Int32 {
        let sqlite3_errcode: (OpaquePointer?) -> Int32
        #if canImport(SQLite3)
        sqlite3_errcode = SQLite3.sqlite3_errcode
        #else
        sqlite3_errcode = loadFunction("sqlite3_errcode")
        #endif
        return sqlite3_errcode(db)
    }

    func sqlite3_errmsg(_ db: OpaquePointer) -> sqlite3_cstring_ptr? {
        let sqlite3_errmsg: (OpaquePointer?) -> UnsafePointer<CChar>?
        #if canImport(SQLite3)
        sqlite3_errmsg = SQLite3.sqlite3_errmsg
        #else
        sqlite3_errmsg = loadFunction("sqlite3_errmsg")
        #endif
        return sqlite3_errmsg(db)
    }

    func sqlite3_last_insert_rowid(_ db: OpaquePointer) -> Int64 {
        let sqlite3_last_insert_rowid: (OpaquePointer?) -> sqlite3_int64
        #if canImport(SQLite3)
        sqlite3_last_insert_rowid = SQLite3.sqlite3_last_insert_rowid
        #else
        sqlite3_last_insert_rowid = loadFunction("sqlite3_last_insert_rowid")
        #endif
        return sqlite3_last_insert_rowid(db)
    }

    func sqlite3_total_changes(_ db: OpaquePointer) -> Int32 {
        let sqlite3_total_changes: (OpaquePointer?) -> Int32
        #if canImport(SQLite3)
        sqlite3_total_changes = SQLite3.sqlite3_total_changes
        #else
        sqlite3_total_changes = loadFunction("sqlite3_total_changes")
        #endif
        return sqlite3_total_changes(db)
    }

    func sqlite3_changes(_ db: OpaquePointer) -> Int32 {
        let sqlite3_changes: (OpaquePointer?) -> Int32
        #if canImport(SQLite3)
        sqlite3_changes = SQLite3.sqlite3_changes
        #else
        sqlite3_changes = loadFunction("sqlite3_changes")
        #endif
        return sqlite3_changes(db)
    }

    func sqlite3_interrupt(_ db: OpaquePointer) {
        let sqlite3_interrupt: (OpaquePointer?) -> Void
        #if canImport(SQLite3)
        sqlite3_interrupt = SQLite3.sqlite3_interrupt
        #else
        sqlite3_interrupt = loadFunction("sqlite3_interrupt")
        #endif
        return sqlite3_interrupt(db)
    }

    func sqlite3_exec(_ db: OpaquePointer, _ sql: String, _ callback: sqlite3_callback?, _ pArg: UnsafeMutableRawPointer?, _ errmsg: sqlite_error_ptr?) -> Int32 {
        let sqlite3_exec: (OpaquePointer?, UnsafePointer<CChar>?, (@convention(c) (UnsafeMutableRawPointer?, Int32, UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?, UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?) -> Int32)?, UnsafeMutableRawPointer?, UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?) -> Int32
        #if canImport(SQLite3)
        sqlite3_exec = SQLite3.sqlite3_exec
        #else
        sqlite3_exec = loadFunction("sqlite3_exec")
        #endif
        return sqlite3_exec(db, sql, callback, pArg, errmsg)
    }

    func sqlite3_prepare_v2(_ db: OpaquePointer, _ sql: String, _ nBytes: Int32, _ ppStmt: sqlite3_openarg, _ tail: UnsafeMutablePointer<UnsafePointer<CChar>?>?) -> Int32 {
        let sqlite3_prepare_v2: (OpaquePointer?, UnsafePointer<CChar>?, Int32, UnsafeMutablePointer<OpaquePointer?>?, UnsafeMutablePointer<UnsafePointer<CChar>?>?) -> Int32
        #if canImport(SQLite3)
        sqlite3_prepare_v2 = SQLite3.sqlite3_prepare_v2
        #else
        sqlite3_prepare_v2 = loadFunction("sqlite3_prepare_v2")
        #endif
        return sqlite3_prepare_v2(db, sql, nBytes, ppStmt, tail)
    }

    func sqlite3_step(_ stmt: OpaquePointer) -> Int32 {
        let sqlite3_step: (OpaquePointer?) -> Int32
        #if canImport(SQLite3)
        sqlite3_step = SQLite3.sqlite3_step
        #else
        sqlite3_step = loadFunction("sqlite3_step")
        #endif
        return sqlite3_step(stmt)
    }

    func sqlite3_finalize(_ stmt: OpaquePointer) -> Int32 {
        let sqlite3_finalize: (OpaquePointer?) -> Int32
        #if canImport(SQLite3)
        sqlite3_finalize = SQLite3.sqlite3_finalize
        #else
        sqlite3_finalize = loadFunction("sqlite3_finalize")
        #endif
        return sqlite3_finalize(stmt)
    }

    func sqlite3_reset(_ stmt: OpaquePointer) -> Int32 {
        let sqlite3_reset: (OpaquePointer?) -> Int32
        #if canImport(SQLite3)
        sqlite3_reset = SQLite3.sqlite3_reset
        #else
        sqlite3_reset = loadFunction("sqlite3_reset")
        #endif
        return sqlite3_reset(stmt)
    }

    func sqlite3_column_count(_ stmt: OpaquePointer) -> Int32 {
        let sqlite3_column_count: (OpaquePointer?) -> Int32
        #if canImport(SQLite3)
        sqlite3_column_count = SQLite3.sqlite3_column_count
        #else
        sqlite3_column_count = loadFunction("sqlite3_column_count")
        #endif
        return sqlite3_column_count(stmt)
    }

    func sqlite3_bind_parameter_count(_ stmnt: OpaquePointer) -> Int32 {
        let sqlite3_bind_parameter_count: (OpaquePointer?) -> Int32
        #if canImport(SQLite3)
        sqlite3_bind_parameter_count = SQLite3.sqlite3_bind_parameter_count
        #else
        sqlite3_bind_parameter_count = loadFunction("sqlite3_bind_parameter_count")
        #endif
        return sqlite3_bind_parameter_count(stmnt)
    }

    func sqlite3_bind_parameter_name(_ stmnt: OpaquePointer, _ columnIndex: Int32) -> sqlite3_cstring_ptr? {
        let sqlite3_bind_parameter_name: (OpaquePointer?, Int32) -> UnsafePointer<CChar>?
        #if canImport(SQLite3)
        sqlite3_bind_parameter_name = SQLite3.sqlite3_bind_parameter_name
        #else
        sqlite3_bind_parameter_name = loadFunction("sqlite3_bind_parameter_name")
        #endif
        return sqlite3_bind_parameter_name(stmnt, columnIndex)
    }

    func sqlite3_bind_parameter_index(_ stmnt: OpaquePointer, _ name: String) -> Int32 {
        let sqlite3_bind_parameter_index: (OpaquePointer?, UnsafePointer<CChar>?) -> Int32
        #if canImport(SQLite3)
        sqlite3_bind_parameter_index = SQLite3.sqlite3_bind_parameter_index
        #else
        sqlite3_bind_parameter_index = loadFunction("sqlite3_bind_parameter_index")
        #endif
        return sqlite3_bind_parameter_index(stmnt, name)
    }

    func sqlite3_clear_bindings(_ stmnt: OpaquePointer) -> Int32 {
        let sqlite3_clear_bindings: (OpaquePointer?) -> Int32
        #if canImport(SQLite3)
        sqlite3_clear_bindings = SQLite3.sqlite3_clear_bindings
        #else
        sqlite3_clear_bindings = loadFunction("sqlite3_clear_bindings")
        #endif
        return sqlite3_clear_bindings(stmnt)
    }

    func sqlite3_column_name(_ stmt: OpaquePointer!, _ columnIndex: Int32) -> sqlite3_cstring_ptr? {
        let sqlite3_column_name: (OpaquePointer?, Int32) -> UnsafePointer<CChar>?
        #if canImport(SQLite3)
        sqlite3_column_name = SQLite3.sqlite3_column_name
        #else
        sqlite3_column_name = loadFunction("sqlite3_column_name")
        #endif
        return sqlite3_column_name(stmt!, columnIndex)
    }

    func sqlite3_column_decltype(_ stmt: OpaquePointer, _ columnIndex: Int32) -> sqlite3_cstring_ptr? {
        let sqlite3_column_decltype: (OpaquePointer?, Int32) -> UnsafePointer<CChar>?
        #if canImport(SQLite3)
        sqlite3_column_decltype = SQLite3.sqlite3_column_decltype
        #else
        sqlite3_column_decltype = loadFunction("sqlite3_column_decltype")
        #endif
        return sqlite3_column_decltype(stmt, columnIndex)
    }

    func sqlite3_sql(_ stmt: OpaquePointer) -> sqlite3_cstring_ptr? {
        let sqlite3_sql: (OpaquePointer?) -> UnsafePointer<CChar>?
        #if canImport(SQLite3)
        sqlite3_sql = SQLite3.sqlite3_sql
        #else
        sqlite3_sql = loadFunction("sqlite3_sql")
        #endif
        return sqlite3_sql(stmt)
    }

    func sqlite3_expanded_sql(_ stmt: OpaquePointer) -> sqlite3_cstring_mutptr? {
        let sqlite3_expanded_sql: (OpaquePointer?) -> UnsafeMutablePointer<CChar>?
        #if canImport(SQLite3)
        sqlite3_expanded_sql = SQLite3.sqlite3_expanded_sql
        #else
        sqlite3_expanded_sql = loadFunction("sqlite3_expanded_sql")
        #endif
        return sqlite3_expanded_sql(stmt)
    }

    func sqlite3_db_handle(_ stmt: OpaquePointer) -> OpaquePointer {
        let sqlite3_db_handle: (OpaquePointer?) -> OpaquePointer?
        #if canImport(SQLite3)
        sqlite3_db_handle = SQLite3.sqlite3_db_handle
        #else
        sqlite3_db_handle = loadFunction("sqlite3_db_handle")
        #endif
        return sqlite3_db_handle(stmt)!
    }

    func sqlite3_bind_null(_ stmt: OpaquePointer, _ paramIndex: Int32) -> Int32 {
        let sqlite3_bind_null: (OpaquePointer?, Int32) -> Int32
        #if canImport(SQLite3)
        sqlite3_bind_null = SQLite3.sqlite3_bind_null
        #else
        sqlite3_bind_null = loadFunction("sqlite3_bind_null")
        #endif
        return sqlite3_bind_null(stmt, paramIndex)
    }

    func sqlite3_bind_int(_ stmt: OpaquePointer, _ paramIndex: Int32, _ value: Int32) -> Int32 {
        let sqlite3_bind_int: (OpaquePointer?, Int32, Int32) -> Int32
        #if canImport(SQLite3)
        sqlite3_bind_int = SQLite3.sqlite3_bind_int
        #else
        sqlite3_bind_int = loadFunction("sqlite3_bind_int")
        #endif
        return sqlite3_bind_int(stmt, paramIndex, value)
    }

    func sqlite3_bind_int64(_ stmt: OpaquePointer, _ paramIndex: Int32, _ value: Int64) -> Int32 {
        let sqlite3_bind_int64: (OpaquePointer?, Int32, sqlite3_int64) -> Int32
        #if canImport(SQLite3)
        sqlite3_bind_int64 = SQLite3.sqlite3_bind_int64
        #else
        sqlite3_bind_int64 = loadFunction("sqlite3_bind_int64")
        #endif
        return sqlite3_bind_int64(stmt, paramIndex, value)
    }

    func sqlite3_bind_double(_ stmt: OpaquePointer, _ paramIndex: Int32, _ value: Double) -> Int32 {
        let sqlite3_bind_double: (OpaquePointer?, Int32, Double) -> Int32
        #if canImport(SQLite3)
        sqlite3_bind_double = SQLite3.sqlite3_bind_double
        #else
        sqlite3_bind_double = loadFunction("sqlite3_bind_double")
        #endif
        return sqlite3_bind_double(stmt, paramIndex, value)
    }

    func sqlite3_bind_text(_ stmt: OpaquePointer, _ paramIndex: Int32, _ value: String, _ length: Int32, _ destructor: sqlite3_destructor_type) -> Int32 {
        let sqlite3_bind_text: (OpaquePointer?, Int32, UnsafePointer<CChar>?, Int32, (@convention(c) (UnsafeMutableRawPointer?) -> Void)?) -> Int32
        #if canImport(SQLite3)
        sqlite3_bind_text = SQLite3.sqlite3_bind_text
        #else
        sqlite3_bind_text = loadFunction("sqlite3_bind_text")
        #endif
        return sqlite3_bind_text(stmt, paramIndex, value, length, destructor)
    }

    func sqlite3_bind_blob(_ stmt: OpaquePointer, _ paramIndex: Int32, _ value: UnsafeRawPointer?, _ length: Int32, _ destructor: sqlite3_destructor_type) -> Int32 {
        let sqlite3_bind_blob: (OpaquePointer?, Int32, UnsafeRawPointer?, Int32, (@convention(c) (UnsafeMutableRawPointer?) -> Void)?) -> Int32
        #if canImport(SQLite3)
        sqlite3_bind_blob = SQLite3.sqlite3_bind_blob
        #else
        sqlite3_bind_blob = loadFunction("sqlite3_bind_blob")
        #endif
        return sqlite3_bind_blob(stmt, paramIndex, value, length, destructor)
    }

    func sqlite3_bind_zeroblob(_ stmt: OpaquePointer, _ paramIndex: Int32, _ length: Int32) -> Int32 {
        let sqlite3_bind_zeroblob: (OpaquePointer?, Int32, Int32) -> Int32
        #if canImport(SQLite3)
        sqlite3_bind_zeroblob = SQLite3.sqlite3_bind_zeroblob
        #else
        sqlite3_bind_zeroblob = loadFunction("sqlite3_bind_zeroblob")
        #endif
        return sqlite3_bind_zeroblob(stmt, paramIndex, length)
    }

    func sqlite3_column_type(_ stmt: OpaquePointer, _ columnIndex: Int32) -> Int32 {
        let sqlite3_column_type: (OpaquePointer?, Int32) -> Int32
        #if canImport(SQLite3)
        sqlite3_column_type = SQLite3.sqlite3_column_type
        #else
        sqlite3_column_type = loadFunction("sqlite3_column_type")
        #endif
        return sqlite3_column_type(stmt, columnIndex)
    }

    func sqlite3_column_int(_ stmt: OpaquePointer, _ columnIndex: Int32) -> Int32 {
        let sqlite3_column_int: (OpaquePointer?, Int32) -> Int32
        #if canImport(SQLite3)
        sqlite3_column_int = SQLite3.sqlite3_column_int
        #else
        sqlite3_column_int = loadFunction("sqlite3_column_int")
        #endif
        return sqlite3_column_int(stmt, columnIndex)
    }

    func sqlite3_column_int64(_ stmt: OpaquePointer, _ columnIndex: Int32) -> Int64 {
        let sqlite3_column_int64: (OpaquePointer?, Int32) -> sqlite3_int64
        #if canImport(SQLite3)
        sqlite3_column_int64 = SQLite3.sqlite3_column_int64
        #else
        sqlite3_column_int64 = loadFunction("sqlite3_column_int64")
        #endif
        return sqlite3_column_int64(stmt, columnIndex)
    }

    func sqlite3_column_double(_ stmt: OpaquePointer, _ columnIndex: Int32) -> Double {
        let sqlite3_column_double: (OpaquePointer?, Int32) -> Double
        #if canImport(SQLite3)
        sqlite3_column_double = SQLite3.sqlite3_column_double
        #else
        sqlite3_column_double = loadFunction("sqlite3_column_double")
        #endif
        return sqlite3_column_double(stmt, columnIndex)
    }

    func sqlite3_column_text(_ stmt: OpaquePointer, _ columnIndex: Int32) -> sqlite3_uint8_ptr? {
        let sqlite3_column_text: (OpaquePointer?, Int32) -> UnsafePointer<UInt8>?
        #if canImport(SQLite3)
        sqlite3_column_text = SQLite3.sqlite3_column_text
        #else
        sqlite3_column_text = loadFunction("sqlite3_column_text")
        #endif
        return sqlite3_column_text(stmt, columnIndex)
    }

    func sqlite3_column_blob(_ stmt: OpaquePointer, _ columnIndex: Int32) -> UnsafeRawPointer? {
        let sqlite3_column_blob: (OpaquePointer?, Int32) -> UnsafeRawPointer?
        #if canImport(SQLite3)
        sqlite3_column_blob = SQLite3.sqlite3_column_blob
        #else
        sqlite3_column_blob = loadFunction("sqlite3_column_blob")
        #endif
        return sqlite3_column_blob(stmt, columnIndex)
    }

    func sqlite3_column_bytes(_ stmt: OpaquePointer, _ columnIndex: Int32) -> Int32 {
        let sqlite3_column_bytes: (OpaquePointer?, Int32) -> Int32
        #if canImport(SQLite3)
        sqlite3_column_bytes = SQLite3.sqlite3_column_bytes
        #else
        sqlite3_column_bytes = loadFunction("sqlite3_column_bytes")
        #endif
        return sqlite3_column_bytes(stmt, columnIndex)
    }

    func sqlite3_backup_init(_ destDb: OpaquePointer, _ destName: String, _ sourceDb: OpaquePointer?, _ sourceName: String) -> OpaquePointer {
        let sqlite3_backup_init: (OpaquePointer?, UnsafePointer<CChar>?, OpaquePointer?, UnsafePointer<CChar>?) -> OpaquePointer?
        #if canImport(SQLite3)
        sqlite3_backup_init = SQLite3.sqlite3_backup_init
        #else
        sqlite3_backup_init = loadFunction("sqlite3_backup_init")
        #endif
        return sqlite3_backup_init(destDb, destName, sourceDb, sourceName)!
    }

    func sqlite3_backup_step(_ backup: OpaquePointer, _ pages: Int32) -> Int32 {
        let sqlite3_backup_step: (OpaquePointer?, Int32) -> Int32
        #if canImport(SQLite3)
        sqlite3_backup_step = SQLite3.sqlite3_backup_step
        #else
        sqlite3_backup_step = loadFunction("sqlite3_backup_step")
        #endif
        return sqlite3_backup_step(backup, pages)
    }

    func sqlite3_backup_finish(_ backup: OpaquePointer) -> Int32 {
        let sqlite3_backup_finish: (OpaquePointer?) -> Int32
        #if canImport(SQLite3)
        sqlite3_backup_finish = SQLite3.sqlite3_backup_finish
        #else
        sqlite3_backup_finish = loadFunction("sqlite3_backup_finish")
        #endif
        return sqlite3_backup_finish(backup)
    }

    func sqlite3_backup_remaining(_ backup: OpaquePointer) -> Int32 {
        let sqlite3_backup_remaining: (OpaquePointer?) -> Int32
        #if canImport(SQLite3)
        sqlite3_backup_remaining = SQLite3.sqlite3_backup_remaining
        #else
        sqlite3_backup_remaining = loadFunction("sqlite3_backup_remaining")
        #endif
        return sqlite3_backup_remaining(backup)
    }

    func sqlite3_backup_pagecount(_ backup: OpaquePointer) -> Int32 {
        let sqlite3_backup_pagecount: (OpaquePointer?) -> Int32
        #if canImport(SQLite3)
        sqlite3_backup_pagecount = SQLite3.sqlite3_backup_pagecount
        #else
        sqlite3_backup_pagecount = loadFunction("sqlite3_backup_pagecount")
        #endif
        return sqlite3_backup_pagecount(backup)
    }

    func sqlite3_initialize() -> Int32 {
        let sqlite3_initialize: () -> Int32
        #if canImport(SQLite3)
        sqlite3_initialize = SQLite3.sqlite3_initialize
        #else
        sqlite3_initialize = loadFunction("sqlite3_initialize")
        #endif
        return sqlite3_initialize()
    }

    func sqlite3_shutdown() -> Int32 {
        let sqlite3_shutdown: () -> Int32
        #if canImport(SQLite3)
        sqlite3_shutdown = SQLite3.sqlite3_shutdown
        #else
        sqlite3_shutdown = loadFunction("sqlite3_shutdown")
        #endif
        return sqlite3_shutdown()
    }

    func sqlite3_libversion() -> sqlite3_cstring_ptr? {
        let sqlite3_libversion: () -> UnsafePointer<CChar>?
        #if canImport(SQLite3)
        sqlite3_libversion = SQLite3.sqlite3_libversion
        #else
        sqlite3_libversion = loadFunction("sqlite3_libversion")
        #endif
        return sqlite3_libversion()
    }

    func sqlite3_libversion_number() -> Int32 {
        let sqlite3_libversion_number: () -> Int32
        #if canImport(SQLite3)
        sqlite3_libversion_number = SQLite3.sqlite3_libversion_number
        #else
        sqlite3_libversion_number = loadFunction("sqlite3_libversion_number")
        #endif
        return sqlite3_libversion_number()
    }

    func sqlite3_extended_result_codes(_ db: OpaquePointer, _ on: Int32) -> Int32 {
        let sqlite3_extended_result_codes: (OpaquePointer?, Int32) -> Int32
        #if canImport(SQLite3)
        sqlite3_extended_result_codes = SQLite3.sqlite3_extended_result_codes
        #else
        sqlite3_extended_result_codes = loadFunction("sqlite3_extended_result_codes")
        #endif
        return sqlite3_extended_result_codes(db, on)
    }

    func sqlite3_free(_ ptr: sqlite3_pointer_type) {
        let sqlite3_free: (UnsafeMutableRawPointer?) -> Void
        #if canImport(SQLite3)
        sqlite3_free = SQLite3.sqlite3_free
        #else
        sqlite3_free = loadFunction("sqlite3_free")
        #endif
        return sqlite3_free(ptr)
    }

    func sqlite3_db_mutex(_ db: OpaquePointer?) -> OpaquePointer? {
        let sqlite3_db_mutex: (OpaquePointer?) -> OpaquePointer?
        #if canImport(SQLite3)
        sqlite3_db_mutex = SQLite3.sqlite3_db_mutex
        #else
        sqlite3_db_mutex = loadFunction("sqlite3_db_mutex")
        #endif
        return sqlite3_db_mutex(db)
    }

    func sqlite3_mutex_free(_ lock: OpaquePointer?) {
        let sqlite3_mutex_free: (OpaquePointer?) -> Void
        #if canImport(SQLite3)
        sqlite3_mutex_free = SQLite3.sqlite3_mutex_free
        #else
        sqlite3_mutex_free = loadFunction("sqlite3_mutex_free")
        #endif
        return sqlite3_mutex_free(lock)
    }

    func sqlite3_mutex_enter(_ lock: OpaquePointer?) {
        let sqlite3_mutex_enter: (OpaquePointer?) -> Void
        #if canImport(SQLite3)
        sqlite3_mutex_enter = SQLite3.sqlite3_mutex_enter
        #else
        sqlite3_mutex_enter = loadFunction("sqlite3_mutex_enter")
        #endif
        return sqlite3_mutex_enter(lock)
    }

    func sqlite3_mutex_leave(_ lock: OpaquePointer?) {
        let sqlite3_mutex_leave: (OpaquePointer?) -> Void
        #if canImport(SQLite3)
        sqlite3_mutex_leave = SQLite3.sqlite3_mutex_leave
        #else
        sqlite3_mutex_leave = loadFunction("sqlite3_mutex_leave")
        #endif
        return sqlite3_mutex_leave(lock)
    }

    func sqlite3_update_hook(_ db: OpaquePointer?, _ callback: sqlite3_update_hook?, _ pArg: UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer? {
        let sqlite3_update_hook: (OpaquePointer?, (@convention(c) (UnsafeMutableRawPointer?, Int32, UnsafePointer<CChar>?, UnsafePointer<CChar>?, sqlite3_int64) -> Void)?, UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer?
        #if canImport(SQLite3)
        sqlite3_update_hook = SQLite3.sqlite3_update_hook
        #else
        sqlite3_update_hook = loadFunction("sqlite3_update_hook")
        #endif
        return sqlite3_update_hook(db, callback, pArg)
    }

    func sqlite3_trace_v2(_ db: OpaquePointer?, _ mask: sqlite3_unsigned, _ callback: sqlite3_trace_hook?, _ pCtx: UnsafeMutableRawPointer?) -> Int32 {
        let sqlite3_trace_v2: (OpaquePointer?, UInt32, (@convention(c) (UInt32, UnsafeMutableRawPointer?, UnsafeMutableRawPointer?, UnsafeMutableRawPointer?) -> Int32)?, UnsafeMutableRawPointer?) -> Int32
        #if canImport(SQLite3)
        sqlite3_trace_v2 = SQLite3.sqlite3_trace_v2
        #else
        sqlite3_trace_v2 = loadFunction("sqlite3_trace_v2")
        #endif
        return sqlite3_trace_v2(db, mask, callback, pCtx)
    }

    private func loadFunction<T>(_ name: String) -> T {
        //fatalError("### LOADING: \(name)")
        //let handle = dlopen(nil, RTLD_NOW)
        //let symbol = dlsym(handle, name)
        let symbol = dlsym(RTLD_DEFAULT, name)
        print("### LOADING: \(name): handle=\(handle) \(symbol)")
        //fatalError("### LOADING: \(name): handle=\(handle) \(symbol)")
        return unsafeBitCast(symbol, to: T.self)
    }
}
#endif

