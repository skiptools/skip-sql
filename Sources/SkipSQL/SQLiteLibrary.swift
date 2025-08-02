// Copyright 2023–2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
#if SKIP
import SkipFFI

public typealias NativeLibrary = com.sun.jna.Library
public typealias NativeCallback = com.sun.jna.Callback

public typealias sqlite3_openarg = UnsafeMutableRawPointer
public typealias sqlite3_cstring_ptr = OpaquePointer
public typealias sqlite3_cstring_mutptr = OpaquePointer
public typealias sqlite3_uint8_ptr = OpaquePointer
public typealias sqlite_error_ptr = UnsafeMutableRawPointer
public typealias sqlite3_destructor_type = Int64
public typealias sqlite3_callback = UnsafeMutableRawPointer

public typealias UnsafeRawPointer = OpaquePointer
public typealias sqlite_tail_ptr = UnsafeMutableRawPointer

//public typealias sqlite3_pointer_type = UnsafeMutableRawPointer
public typealias sqlite3_pointer_type = OpaquePointer

public typealias sqlite3_unsigned = Int32 // JNA has no UInt understanding

#else
public typealias NativeLibrary = AnyObject
public typealias NativeCallback = AnyObject

public typealias sqlite3_openarg = UnsafeMutablePointer<OpaquePointer?> // UnsafeMutableRawPointer?
public typealias sqlite3_cstring_ptr = UnsafePointer<CChar>
public typealias sqlite3_cstring_mutptr = UnsafeMutablePointer<CChar>
public typealias sqlite3_uint8_ptr = UnsafePointer<UInt8>

public typealias sqlite_error_ptr = UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>
//typealias sqlite3_destructor_type = (@convention(c) (UnsafeMutableRawPointer?) -> Void)
public typealias sqlite_tail_ptr = UnsafeMutablePointer<UnsafePointer<CChar>?>

public typealias sqlite3_unsigned = UInt32
public typealias sqlite3_pointer_type = UnsafeMutableRawPointer
#endif

public protocol SQLiteLibrary : NativeLibrary {
    func sqlite3_sleep(_ duration: Int32) -> Int32

    // Database Connection API
    func sqlite3_open(_ filename: String, _ ppDb: sqlite3_openarg?) -> Int32
    func sqlite3_open_v2(_ filename: String, _ ppDb: sqlite3_openarg?, _ flags: Int32, _ vfs: String?) -> Int32
    func sqlite3_close(_ db: OpaquePointer) -> Int32
    func sqlite3_errcode(_ db: OpaquePointer) -> Int32
    func sqlite3_errmsg(_ db: OpaquePointer) -> sqlite3_cstring_ptr?
    func sqlite3_last_insert_rowid(_ db: OpaquePointer) -> Int64
    func sqlite3_total_changes(_ db: OpaquePointer) -> Int32
    func sqlite3_changes(_ db: OpaquePointer) -> Int32
    func sqlite3_interrupt(_ db: OpaquePointer)

    func sqlite3_exec(_ db: OpaquePointer, _ sql: String, _ callback: sqlite3_callback?, _ pArg: UnsafeMutableRawPointer?, _ errmsg: sqlite_error_ptr?) -> Int32
    func sqlite3_prepare_v2(_ db: OpaquePointer, _ sql: String, _ nBytes: Int32, _ ppStmt: sqlite3_openarg, _ tail: sqlite_tail_ptr?) -> Int32

    // Statement API
    func sqlite3_step(_ stmt: OpaquePointer) -> Int32
    func sqlite3_finalize(_ stmt: OpaquePointer) -> Int32
    func sqlite3_reset(_ stmt: OpaquePointer) -> Int32
    func sqlite3_column_count(_ stmt: OpaquePointer) -> Int32
    func sqlite3_bind_parameter_count(_ stmnt: OpaquePointer) -> Int32
    func sqlite3_bind_parameter_name(_ stmnt: OpaquePointer, _ columnIndex: Int32) -> sqlite3_cstring_ptr?
    func sqlite3_bind_parameter_index(_ stmnt: OpaquePointer, _ name: String) -> Int32
    func sqlite3_clear_bindings(_ stmnt: OpaquePointer) -> Int32

    func sqlite3_column_name(_ stmt: OpaquePointer!, _ columnIndex: Int32) -> sqlite3_cstring_ptr?

    // Unavailable in Android's sqlite build
    //func sqlite3_column_table_name(_ stmt: OpaquePointer, _ columnIndex: Int32) -> sqlite3_cstring_ptr?

    //func sqlite3_column_origin_name(_ stmt: OpaquePointer, _ columnIndex: Int32) -> sqlite3_cstring_ptr?
    func sqlite3_column_decltype(_ stmt: OpaquePointer, _ columnIndex: Int32) -> sqlite3_cstring_ptr?

    func sqlite3_sql(_ stmt: OpaquePointer) -> sqlite3_cstring_ptr?
    func sqlite3_expanded_sql(_ stmt: OpaquePointer) -> sqlite3_cstring_mutptr?
    func sqlite3_db_handle(_ stmt: OpaquePointer) -> OpaquePointer

    // Parameter Binding
    func sqlite3_bind_null(_ stmt: OpaquePointer, _ paramIndex: Int32) -> Int32
    func sqlite3_bind_int(_ stmt: OpaquePointer, _ paramIndex: Int32, _ value: Int32) -> Int32
    func sqlite3_bind_int64(_ stmt: OpaquePointer, _ paramIndex: Int32, _ value: Int64) -> Int32
    func sqlite3_bind_double(_ stmt: OpaquePointer, _ paramIndex: Int32, _ value: Double) -> Int32
    func sqlite3_bind_text(_ stmt: OpaquePointer, _ paramIndex: Int32, _ value: String, _ length: Int32, _ destructor: sqlite3_destructor_type) -> Int32
    func sqlite3_bind_blob(_ stmt: OpaquePointer, _ paramIndex: Int32, _ value: UnsafeRawPointer?, _ length: Int32, _ destructor: sqlite3_destructor_type) -> Int32
    func sqlite3_bind_zeroblob(_ stmt: OpaquePointer, _ paramIndex: Int32, _ length: Int32) -> Int32


    // Column Value API
    func sqlite3_column_type(_ stmt: OpaquePointer, _ columnIndex: Int32) -> Int32
    func sqlite3_column_int(_ stmt: OpaquePointer, _ columnIndex: Int32) -> Int32
    func sqlite3_column_int64(_ stmt: OpaquePointer, _ columnIndex: Int32) -> Int64
    func sqlite3_column_double(_ stmt: OpaquePointer, _ columnIndex: Int32) -> Double
    func sqlite3_column_text(_ stmt: OpaquePointer, _ columnIndex: Int32) -> sqlite3_uint8_ptr?
    func sqlite3_column_blob(_ stmt: OpaquePointer, _ columnIndex: Int32) -> UnsafeRawPointer?
    func sqlite3_column_bytes(_ stmt: OpaquePointer, _ columnIndex: Int32) -> Int32

    // Backup API
    func sqlite3_backup_init(_ destDb: OpaquePointer, _ destName: String, _ sourceDb: OpaquePointer?, _ sourceName: String) -> OpaquePointer
    func sqlite3_backup_step(_ backup: OpaquePointer, _ pages: Int32) -> Int32
    func sqlite3_backup_finish(_ backup: OpaquePointer) -> Int32
    func sqlite3_backup_remaining(_ backup: OpaquePointer) -> Int32
    func sqlite3_backup_pagecount(_ backup: OpaquePointer) -> Int32

    // Other Functions
    func sqlite3_initialize() -> Int32
    func sqlite3_shutdown() -> Int32
    func sqlite3_libversion_number() -> Int32

    //func sqlite3_config(option: Int32, values: Object...) -> Int32
    func sqlite3_extended_result_codes(_ db: OpaquePointer, _ on: Int32) -> Int32
    #if SKIP
    // otherwise: 'sqlite3_free' hides member of supertype 'SQLiteLibrary' and needs an 'override' modifier.
    func sqlite3_free(_ ptr: OpaquePointer)
    #else
    func sqlite3_free(_ ptr: sqlite3_pointer_type)
    #endif

    // Locks
    func sqlite3_db_mutex(_ db: OpaquePointer?) -> OpaquePointer?
    func sqlite3_mutex_free(_ lock: OpaquePointer?)
    func sqlite3_mutex_enter(_ lock: OpaquePointer?)
    func sqlite3_mutex_leave(_ lock: OpaquePointer?)
    //func int sqlite3_mutex_try(sqlite3_mutex*);

    func sqlite3_update_hook(_ db: OpaquePointer?, _ callback: sqlite3_update_hook?, _ pArg: UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer?

    func sqlite3_trace_v2(_ db: OpaquePointer?, _ mask: sqlite3_unsigned, _ callback: sqlite3_trace_hook?, _ pCtx: UnsafeMutableRawPointer?) -> Int32
}
