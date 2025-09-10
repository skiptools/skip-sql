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
///
/// The version of this library will vary between OS version, so some features (e.g., JSON support) might not be available.
final class SQLiteCLibrary : SQLiteLibrary {
    static let shared = SQLiteCLibrary()

    init() {
    }

    private static let _sqlite3_sleep: (Int32) -> Int32 = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_sleep
        #else
        loadFunction("sqlite3_sleep")
        #endif
    }()

    func sqlite3_sleep(_ duration: Int32) -> Int32 {
        return Self._sqlite3_sleep(duration)
    }

    private static let _sqlite3_open: (UnsafePointer<CChar>?, UnsafeMutablePointer<OpaquePointer?>?) -> Int32 = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_open
        #else
        loadFunction("sqlite3_open")
        #endif
    }()

    func sqlite3_open(_ filename: String, _ ppDb: sqlite3_openarg?) -> Int32 {
        return Self._sqlite3_open(filename, ppDb)
    }

    private static let _sqlite3_open_v2: (UnsafePointer<CChar>?, UnsafeMutablePointer<OpaquePointer?>?, Int32, UnsafePointer<CChar>?) -> Int32 = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_open_v2
        #else
        loadFunction("sqlite3_open_v2")
        #endif
    }()

    func sqlite3_open_v2(_ filename: String, _ ppDb: sqlite3_openarg?, _ flags: Int32, _ vfs: String?) -> Int32 {
        return Self._sqlite3_open_v2(filename, ppDb, flags, vfs)
    }

    private static let _sqlite3_close: (OpaquePointer?) -> Int32 = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_close
        #else
        loadFunction("sqlite3_close")
        #endif
    }()

    func sqlite3_close(_ db: OpaquePointer) -> Int32 {
        return Self._sqlite3_close(db)
    }

    private static let _sqlite3_errcode: (OpaquePointer?) -> Int32 = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_errcode
        #else
        loadFunction("sqlite3_errcode")
        #endif
    }()

    func sqlite3_errcode(_ db: OpaquePointer) -> Int32 {
        return Self._sqlite3_errcode(db)
    }

    private static let _sqlite3_errmsg: (OpaquePointer?) -> UnsafePointer<CChar>? = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_errmsg
        #else
        loadFunction("sqlite3_errmsg")
        #endif
    }()

    func sqlite3_errmsg(_ db: OpaquePointer) -> sqlite3_cstring_ptr? {
        return Self._sqlite3_errmsg(db)
    }

    private static let _sqlite3_last_insert_rowid: (OpaquePointer?) -> sqlite3_int64 = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_last_insert_rowid
        #else
        loadFunction("sqlite3_last_insert_rowid")
        #endif
    }()

    func sqlite3_last_insert_rowid(_ db: OpaquePointer) -> Int64 {
        return Self._sqlite3_last_insert_rowid(db)
    }

    private static let _sqlite3_total_changes: (OpaquePointer?) -> Int32 = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_total_changes
        #else
        loadFunction("sqlite3_total_changes")
        #endif
    }()

    func sqlite3_total_changes(_ db: OpaquePointer) -> Int32 {
        return Self._sqlite3_total_changes(db)
    }

    private static let _sqlite3_changes: (OpaquePointer?) -> Int32 = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_changes
        #else
        loadFunction("sqlite3_changes")
        #endif
    }()

    func sqlite3_changes(_ db: OpaquePointer) -> Int32 {
        return Self._sqlite3_changes(db)
    }

    private static let _sqlite3_interrupt: (OpaquePointer?) -> Void = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_interrupt
        #else
        loadFunction("sqlite3_interrupt")
        #endif
    }()

    func sqlite3_interrupt(_ db: OpaquePointer) {
        return Self._sqlite3_interrupt(db)
    }

    private static let _sqlite3_exec: (OpaquePointer?, UnsafePointer<CChar>?, (@convention(c) (UnsafeMutableRawPointer?, Int32, UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?, UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?) -> Int32)?, UnsafeMutableRawPointer?, UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?) -> Int32 = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_exec
        #else
        loadFunction("sqlite3_exec")
        #endif
    }()

    func sqlite3_exec(_ db: OpaquePointer, _ sql: String, _ callback: sqlite3_callback?, _ pArg: UnsafeMutableRawPointer?, _ errmsg: sqlite_error_ptr?) -> Int32 {
        return Self._sqlite3_exec(db, sql, callback, pArg, errmsg)
    }

    private static let _sqlite3_prepare_v2: (OpaquePointer?, UnsafePointer<CChar>?, Int32, UnsafeMutablePointer<OpaquePointer?>?, UnsafeMutablePointer<UnsafePointer<CChar>?>?) -> Int32 = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_prepare_v2
        #else
        loadFunction("sqlite3_prepare_v2")
        #endif
    }()

    func sqlite3_prepare_v2(_ db: OpaquePointer, _ sql: String, _ nBytes: Int32, _ ppStmt: sqlite3_openarg, _ tail: UnsafeMutablePointer<UnsafePointer<CChar>?>?) -> Int32 {
        return Self._sqlite3_prepare_v2(db, sql, nBytes, ppStmt, tail)
    }

    private static let _sqlite3_step: (OpaquePointer?) -> Int32 = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_step
        #else
        loadFunction("sqlite3_step")
        #endif
    }()

    func sqlite3_step(_ stmt: OpaquePointer) -> Int32 {
        return Self._sqlite3_step(stmt)
    }

    private static let _sqlite3_finalize: (OpaquePointer?) -> Int32 = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_finalize
        #else
        loadFunction("sqlite3_finalize")
        #endif
    }()

    func sqlite3_finalize(_ stmt: OpaquePointer) -> Int32 {
        return Self._sqlite3_finalize(stmt)
    }

    private static let _sqlite3_reset: (OpaquePointer?) -> Int32 = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_reset
        #else
        loadFunction("sqlite3_reset")
        #endif
    }()

    func sqlite3_reset(_ stmt: OpaquePointer) -> Int32 {
        return Self._sqlite3_reset(stmt)
    }

    private static let _sqlite3_column_count: (OpaquePointer?) -> Int32 = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_column_count
        #else
        loadFunction("sqlite3_column_count")
        #endif
    }()

    func sqlite3_column_count(_ stmt: OpaquePointer) -> Int32 {
        return Self._sqlite3_column_count(stmt)
    }

    private static let _sqlite3_bind_parameter_count: (OpaquePointer?) -> Int32 = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_bind_parameter_count
        #else
        loadFunction("sqlite3_bind_parameter_count")
        #endif
    }()

    func sqlite3_bind_parameter_count(_ stmnt: OpaquePointer) -> Int32 {
        return Self._sqlite3_bind_parameter_count(stmnt)
    }

    private static let _sqlite3_bind_parameter_name: (OpaquePointer?, Int32) -> UnsafePointer<CChar>? = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_bind_parameter_name
        #else
        loadFunction("sqlite3_bind_parameter_name")
        #endif
    }()

    func sqlite3_bind_parameter_name(_ stmnt: OpaquePointer, _ columnIndex: Int32) -> sqlite3_cstring_ptr? {
        return Self._sqlite3_bind_parameter_name(stmnt, columnIndex)
    }

    private static let _sqlite3_bind_parameter_index: (OpaquePointer?, UnsafePointer<CChar>?) -> Int32 = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_bind_parameter_index
        #else
        loadFunction("sqlite3_bind_parameter_index")
        #endif
    }()

    func sqlite3_bind_parameter_index(_ stmnt: OpaquePointer, _ name: String) -> Int32 {
        return Self._sqlite3_bind_parameter_index(stmnt, name)
    }

    private static let _sqlite3_clear_bindings: (OpaquePointer?) -> Int32 = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_clear_bindings
        #else
        loadFunction("sqlite3_clear_bindings")
        #endif
    }()

    func sqlite3_clear_bindings(_ stmnt: OpaquePointer) -> Int32 {
        return Self._sqlite3_clear_bindings(stmnt)
    }

    private static let _sqlite3_column_name: (OpaquePointer?, Int32) -> UnsafePointer<CChar>? = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_column_name
        #else
        loadFunction("sqlite3_column_name")
        #endif
    }()

    func sqlite3_column_name(_ stmt: OpaquePointer!, _ columnIndex: Int32) -> sqlite3_cstring_ptr? {
        return Self._sqlite3_column_name(stmt!, columnIndex)
    }

    private static let _sqlite3_column_decltype: (OpaquePointer?, Int32) -> UnsafePointer<CChar>? = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_column_decltype
        #else
        loadFunction("sqlite3_column_decltype")
        #endif
    }()

    func sqlite3_column_decltype(_ stmt: OpaquePointer, _ columnIndex: Int32) -> sqlite3_cstring_ptr? {
        return Self._sqlite3_column_decltype(stmt, columnIndex)
    }

    private static let _sqlite3_sql: (OpaquePointer?) -> UnsafePointer<CChar>? = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_sql
        #else
        loadFunction("sqlite3_sql")
        #endif
    }()

    func sqlite3_sql(_ stmt: OpaquePointer) -> sqlite3_cstring_ptr? {
        return Self._sqlite3_sql(stmt)
    }

    private static let _sqlite3_expanded_sql: (OpaquePointer?) -> UnsafeMutablePointer<CChar>? = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_expanded_sql
        #else
        loadFunction("sqlite3_expanded_sql")
        #endif
    }()

    func sqlite3_expanded_sql(_ stmt: OpaquePointer) -> sqlite3_cstring_mutptr? {
        return Self._sqlite3_expanded_sql(stmt)
    }

    private static let _sqlite3_db_handle: (OpaquePointer?) -> OpaquePointer? = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_db_handle
        #else
        loadFunction("sqlite3_db_handle")
        #endif
    }()

    func sqlite3_db_handle(_ stmt: OpaquePointer) -> OpaquePointer {
        return Self._sqlite3_db_handle(stmt)!
    }

    private static let _sqlite3_bind_null: (OpaquePointer?, Int32) -> Int32 = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_bind_null
        #else
        loadFunction("sqlite3_bind_null")
        #endif
    }()

    func sqlite3_bind_null(_ stmt: OpaquePointer, _ paramIndex: Int32) -> Int32 {
        return Self._sqlite3_bind_null(stmt, paramIndex)
    }

    private static let _sqlite3_bind_int: (OpaquePointer?, Int32, Int32) -> Int32 = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_bind_int
        #else
        loadFunction("sqlite3_bind_int")
        #endif
    }()

    func sqlite3_bind_int(_ stmt: OpaquePointer, _ paramIndex: Int32, _ value: Int32) -> Int32 {
        return Self._sqlite3_bind_int(stmt, paramIndex, value)
    }

    private static let _sqlite3_bind_int64: (OpaquePointer?, Int32, sqlite3_int64) -> Int32 = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_bind_int64
        #else
        loadFunction("sqlite3_bind_int64")
        #endif
    }()

    func sqlite3_bind_int64(_ stmt: OpaquePointer, _ paramIndex: Int32, _ value: Int64) -> Int32 {
        return Self._sqlite3_bind_int64(stmt, paramIndex, value)
    }

    private static let _sqlite3_bind_double: (OpaquePointer?, Int32, Double) -> Int32 = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_bind_double
        #else
        loadFunction("sqlite3_bind_double")
        #endif
    }()

    func sqlite3_bind_double(_ stmt: OpaquePointer, _ paramIndex: Int32, _ value: Double) -> Int32 {
        return Self._sqlite3_bind_double(stmt, paramIndex, value)
    }

    private static let _sqlite3_bind_text: (OpaquePointer?, Int32, UnsafePointer<CChar>?, Int32, (@convention(c) (UnsafeMutableRawPointer?) -> Void)?) -> Int32 = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_bind_text
        #else
        loadFunction("sqlite3_bind_text")
        #endif
    }()

    func sqlite3_bind_text(_ stmt: OpaquePointer, _ paramIndex: Int32, _ value: String, _ length: Int32, _ destructor: sqlite3_destructor_type) -> Int32 {
        return Self._sqlite3_bind_text(stmt, paramIndex, value, length, destructor)
    }

    private static let _sqlite3_bind_blob: (OpaquePointer?, Int32, UnsafeRawPointer?, Int32, (@convention(c) (UnsafeMutableRawPointer?) -> Void)?) -> Int32 = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_bind_blob
        #else
        loadFunction("sqlite3_bind_blob")
        #endif
    }()

    func sqlite3_bind_blob(_ stmt: OpaquePointer, _ paramIndex: Int32, _ value: UnsafeRawPointer?, _ length: Int32, _ destructor: sqlite3_destructor_type) -> Int32 {
        return Self._sqlite3_bind_blob(stmt, paramIndex, value, length, destructor)
    }

    private static let _sqlite3_bind_zeroblob: (OpaquePointer?, Int32, Int32) -> Int32 = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_bind_zeroblob
        #else
        loadFunction("sqlite3_bind_zeroblob")
        #endif
    }()

    func sqlite3_bind_zeroblob(_ stmt: OpaquePointer, _ paramIndex: Int32, _ length: Int32) -> Int32 {
        return Self._sqlite3_bind_zeroblob(stmt, paramIndex, length)
    }

    private static let _sqlite3_column_type: (OpaquePointer?, Int32) -> Int32 = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_column_type
        #else
        loadFunction("sqlite3_column_type")
        #endif
    }()

    func sqlite3_column_type(_ stmt: OpaquePointer, _ columnIndex: Int32) -> Int32 {
        return Self._sqlite3_column_type(stmt, columnIndex)
    }

    private static let _sqlite3_column_int: (OpaquePointer?, Int32) -> Int32 = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_column_int
        #else
        loadFunction("sqlite3_column_int")
        #endif
    }()

    func sqlite3_column_int(_ stmt: OpaquePointer, _ columnIndex: Int32) -> Int32 {
        return Self._sqlite3_column_int(stmt, columnIndex)
    }

    private static let _sqlite3_column_int64: (OpaquePointer?, Int32) -> sqlite3_int64 = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_column_int64
        #else
        loadFunction("sqlite3_column_int64")
        #endif
    }()

    func sqlite3_column_int64(_ stmt: OpaquePointer, _ columnIndex: Int32) -> Int64 {
        return Self._sqlite3_column_int64(stmt, columnIndex)
    }

    private static let _sqlite3_column_double: (OpaquePointer?, Int32) -> Double = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_column_double
        #else
        loadFunction("sqlite3_column_double")
        #endif
    }()

    func sqlite3_column_double(_ stmt: OpaquePointer, _ columnIndex: Int32) -> Double {
        return Self._sqlite3_column_double(stmt, columnIndex)
    }

    private static let _sqlite3_column_text: (OpaquePointer?, Int32) -> UnsafePointer<UInt8>? = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_column_text
        #else
        loadFunction("sqlite3_column_text")
        #endif
    }()

    func sqlite3_column_text(_ stmt: OpaquePointer, _ columnIndex: Int32) -> sqlite3_uint8_ptr? {
        return Self._sqlite3_column_text(stmt, columnIndex)
    }

    private static let _sqlite3_column_blob: (OpaquePointer?, Int32) -> UnsafeRawPointer? = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_column_blob
        #else
        loadFunction("sqlite3_column_blob")
        #endif
    }()

    func sqlite3_column_blob(_ stmt: OpaquePointer, _ columnIndex: Int32) -> UnsafeRawPointer? {
        return Self._sqlite3_column_blob(stmt, columnIndex)
    }

    private static let _sqlite3_column_bytes: (OpaquePointer?, Int32) -> Int32 = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_column_bytes
        #else
        loadFunction("sqlite3_column_bytes")
        #endif
    }()

    func sqlite3_column_bytes(_ stmt: OpaquePointer, _ columnIndex: Int32) -> Int32 {
        return Self._sqlite3_column_bytes(stmt, columnIndex)
    }

    private static let _sqlite3_backup_init: (OpaquePointer?, UnsafePointer<CChar>?, OpaquePointer?, UnsafePointer<CChar>?) -> OpaquePointer? = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_backup_init
        #else
        loadFunction("sqlite3_backup_init")
        #endif
    }()

    func sqlite3_backup_init(_ destDb: OpaquePointer, _ destName: String, _ sourceDb: OpaquePointer?, _ sourceName: String) -> OpaquePointer {
        return Self._sqlite3_backup_init(destDb, destName, sourceDb, sourceName)!
    }

    private static let _sqlite3_backup_step: (OpaquePointer?, Int32) -> Int32 = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_backup_step
        #else
        loadFunction("sqlite3_backup_step")
        #endif
    }()

    func sqlite3_backup_step(_ backup: OpaquePointer, _ pages: Int32) -> Int32 {
        return Self._sqlite3_backup_step(backup, pages)
    }

    private static let _sqlite3_backup_finish: (OpaquePointer?) -> Int32 = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_backup_finish
        #else
        loadFunction("sqlite3_backup_finish")
        #endif
    }()

    func sqlite3_backup_finish(_ backup: OpaquePointer) -> Int32 {
        return Self._sqlite3_backup_finish(backup)
    }

    private static let _sqlite3_backup_remaining: (OpaquePointer?) -> Int32 = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_backup_remaining
        #else
        loadFunction("sqlite3_backup_remaining")
        #endif
    }()

    func sqlite3_backup_remaining(_ backup: OpaquePointer) -> Int32 {
        return Self._sqlite3_backup_remaining(backup)
    }

    private static let _sqlite3_backup_pagecount: (OpaquePointer?) -> Int32 = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_backup_pagecount
        #else
        loadFunction("sqlite3_backup_pagecount")
        #endif
    }()

    func sqlite3_backup_pagecount(_ backup: OpaquePointer) -> Int32 {
        return Self._sqlite3_backup_pagecount(backup)
    }

    private static let _sqlite3_initialize: () -> Int32 = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_initialize
        #else
        loadFunction("sqlite3_initialize")
        #endif
    }()

    func sqlite3_initialize() -> Int32 {
        return Self._sqlite3_initialize()
    }

    private static let _sqlite3_shutdown: () -> Int32 = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_shutdown
        #else
        loadFunction("sqlite3_shutdown")
        #endif
    }()

    func sqlite3_shutdown() -> Int32 {
        return Self._sqlite3_shutdown()
    }

    private static let _sqlite3_libversion: () -> UnsafePointer<CChar>? = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_libversion
        #else
        loadFunction("sqlite3_libversion")
        #endif
    }()

    func sqlite3_libversion() -> sqlite3_cstring_ptr? {
        return Self._sqlite3_libversion()
    }

    private static let _sqlite3_libversion_number: () -> Int32 = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_libversion_number
        #else
        loadFunction("sqlite3_libversion_number")
        #endif
    }()

    func sqlite3_libversion_number() -> Int32 {
        return Self._sqlite3_libversion_number()
    }

    private static let _sqlite3_extended_result_codes: (OpaquePointer?, Int32) -> Int32 = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_extended_result_codes
        #else
        loadFunction("sqlite3_extended_result_codes")
        #endif
    }()

    func sqlite3_extended_result_codes(_ db: OpaquePointer, _ on: Int32) -> Int32 {
        return Self._sqlite3_extended_result_codes(db, on)
    }

    private static let _sqlite3_free: (UnsafeMutableRawPointer?) -> Void = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_free
        #else
        loadFunction("sqlite3_free")
        #endif
    }()

    func sqlite3_free(_ ptr: sqlite3_pointer_type) {
        return Self._sqlite3_free(ptr)
    }

    private static let _sqlite3_db_mutex: (OpaquePointer?) -> OpaquePointer? = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_db_mutex
        #else
        loadFunction("sqlite3_db_mutex")
        #endif
    }()

    func sqlite3_db_mutex(_ db: OpaquePointer?) -> OpaquePointer? {
        return Self._sqlite3_db_mutex(db)
    }

    private static let _sqlite3_mutex_free: (OpaquePointer?) -> Void = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_mutex_free
        #else
        loadFunction("sqlite3_mutex_free")
        #endif
    }()

    func sqlite3_mutex_free(_ lock: OpaquePointer?) {
        return Self._sqlite3_mutex_free(lock)
    }

    private static let _sqlite3_mutex_enter: (OpaquePointer?) -> Void = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_mutex_enter
        #else
        loadFunction("sqlite3_mutex_enter")
        #endif
    }()

    func sqlite3_mutex_enter(_ lock: OpaquePointer?) {
        return Self._sqlite3_mutex_enter(lock)
    }

    private static let _sqlite3_mutex_leave: (OpaquePointer?) -> Void = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_mutex_leave
        #else
        loadFunction("sqlite3_mutex_leave")
        #endif
    }()

    func sqlite3_mutex_leave(_ lock: OpaquePointer?) {
        return Self._sqlite3_mutex_leave(lock)
    }

    private static let _sqlite3_update_hook: (OpaquePointer?, (@convention(c) (UnsafeMutableRawPointer?, Int32, UnsafePointer<CChar>?, UnsafePointer<CChar>?, sqlite3_int64) -> Void)?, UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer? = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_update_hook
        #else
        loadFunction("sqlite3_update_hook")
        #endif
    }()

    func sqlite3_update_hook(_ db: OpaquePointer?, _ callback: sqlite3_update_hook?, _ pArg: UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer? {
        return Self._sqlite3_update_hook(db, callback, pArg)
    }

    private static let _sqlite3_trace_v2: (OpaquePointer?, UInt32, (@convention(c) (UInt32, UnsafeMutableRawPointer?, UnsafeMutableRawPointer?, UnsafeMutableRawPointer?) -> Int32)?, UnsafeMutableRawPointer?) -> Int32 = {
        #if canImport(SQLite3)
        SQLite3.sqlite3_trace_v2
        #else
        loadFunction("sqlite3_trace_v2")
        #endif
    }()

    func sqlite3_trace_v2(_ db: OpaquePointer?, _ mask: sqlite3_unsigned, _ callback: sqlite3_trace_hook?, _ pCtx: UnsafeMutableRawPointer?) -> Int32 {
        return Self._sqlite3_trace_v2(db, mask, callback, pCtx)
    }

    #if !canImport(SQLite3)
    private static func loadFunction<T>(_ name: String) -> T {
        #if canImport(Darwin)
        let RTLD_DEFAULT = UnsafeMutableRawPointer(bitPattern: -2)
        #else
        let RTLD_DEFAULT = UnsafeMutableRawPointer(bitPattern: 0)
        #endif

        let symbol = dlsym(RTLD_DEFAULT, name)
        if symbol == nil {
            fatalError("SQLiteCLibrary: unable to dlsym \(name)")
        }
        return unsafeBitCast(symbol, to: T.self)
    }
    #endif
}
#endif
