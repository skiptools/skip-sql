// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org
@testable import SkipSQL
import XCTest
import Foundation
#if !SKIP
import struct Foundation.Data // for disambiguation
import struct Foundation.Date // for disambiguation
import struct Foundation.URL // for disambiguation
#endif

// SKIP INSERT: @org.junit.runner.RunWith(androidx.test.ext.junit.runners.AndroidJUnit4::class)
// SKIP INSERT: @org.robolectric.annotation.Config(manifest=org.robolectric.annotation.Config.NONE, sdk = [33])
@available(macOS 13, macCatalyst 16, iOS 16, tvOS 16, watchOS 8, *)
final class SQLContextTests: XCTestCase {
    func testCheckSQLVersion() throws {
        let version = try SQLContext().query(sql: "SELECT sqlite_version()").nextRow(close: true)
        #if SKIP
        XCTAssertEqual("3.32.2", version?.first?.textValue) // 3.31.1 on Android 11 (API level 30)
        #else
        XCTAssertEqual("3.39.5", version?.first?.textValue)
        #endif
    }

    func testSkipSQL() throws {
        //var random = PseudoRandomNumberGenerator(seed: 1234)
        //let rnd = (0...999999).randomElement(using: &random)!
        let rnd = 1
        let dbname = "/tmp/demosql_\(rnd).db"

        print("connecting to: " + dbname)
        let conn = try SQLContext(dbname)

        let version = try conn.query(sql: "select sqlite_version()").nextRow(close: true)?.first?.textValue
        print("SQLite version: " + (version ?? "")) // Kotlin: 3.28.0 Swift: 3.39.5

        XCTAssertEqual(try conn.query(sql: "SELECT 1.0").nextRow(close: true)?.first?.floatValue, 1.0)
        XCTAssertEqual(try conn.query(sql: "SELECT 'ABC'").nextRow(close: true)?.first?.textValue, "ABC")
        XCTAssertEqual(try conn.query(sql: "SELECT lower('ABC')").nextRow(close: true)?.first?.textValue, "abc")
        XCTAssertEqual(try conn.query(sql: "SELECT 3.0/2.0, 4.0*2.5").nextRow(close: true)?.last?.floatValue, 10.0)

        XCTAssertEqual(try conn.query(sql: "SELECT ?", params: [SQLValue.text("ABC")]).nextRow(close: true)?.first?.textValue, "ABC")
        XCTAssertEqual(try conn.query(sql: "SELECT upper(?), lower(?)", params: [SQLValue.text("ABC"), SQLValue.text("XYZ")]).nextRow(close: true)?.last?.textValue, "xyz")

        #if !SKIP
        XCTAssertEqual(try conn.query(sql: "SELECT ?", params: [SQLValue.float(1.5)]).nextRow(close: true)?.first?.floatValue, 1.5) // compiles but AssertionError in Kotlin
        #endif
        
        XCTAssertEqual(try conn.query(sql: "SELECT 1").nextRow(close: true)?.first?.integerValue, Int64(1))

        do {
            try conn.execute(sql: "DROP TABLE FOO")
        } catch {
            // exception expected when re-running on existing database
        }

        try conn.execute(sql: "CREATE TABLE FOO (NAME VARCHAR, NUM INTEGER, DBL FLOAT)")
        for i in 1...10 {
            try conn.execute(sql: "INSERT INTO FOO VALUES(?, ?, ?)", params: [SQLValue.text("NAME_" + i.description), SQLValue.integer(Int64(i)), SQLValue.float(Double(i))])
        }

        let cursor = try conn.query(sql: "SELECT * FROM FOO")
        let colcount = cursor.columnCount
        print("columns: \(colcount)")
        XCTAssertEqual(colcount, 3)

        var row = 0
        let consoleWidth = 45

        while try cursor.next() {
            if row == 0 {
                // header and border rows
                try print(cursor.rowText(header: false, values: false, width: consoleWidth))
                try print(cursor.rowText(header: true, values: false, width: consoleWidth))
                try print(cursor.rowText(header: false, values: false, width: consoleWidth))
            }

            try print(cursor.rowText(header: false, values: true, width: consoleWidth))

            row += 1

            try XCTAssertEqual(cursor.getColumnName(column: 0), "NAME")
            try XCTAssertEqual(cursor.getColumnType(column: 0), ColumnType.text)
            try XCTAssertEqual(cursor.getString(column: 0), "NAME_\(row)")

            try XCTAssertEqual(cursor.getColumnName(column: 1), "NUM")
            try XCTAssertEqual(cursor.getColumnType(column: 1), ColumnType.integer)
            try XCTAssertEqual(cursor.getInt64(column: 1), Int64(row))

            try XCTAssertEqual(cursor.getColumnName(column: 2), "DBL")
            try XCTAssertEqual(cursor.getColumnType(column: 2), ColumnType.float)
            try XCTAssertEqual(cursor.getDouble(column: 2), Double(row))
        }

        try print(cursor.rowText(header: false, values: false, width: consoleWidth))

        try cursor.close()
        XCTAssertEqual(cursor.closed, true)

        try conn.execute(sql: "DROP TABLE FOO")

        conn.close()
        XCTAssertEqual(conn.closed, true)

        // .init not being resolved for some reason…

        // let dataFile: Data = try Data.init(contentsOfFile: dbname)
        // XCTAssertEqual(dataFile.count > 1024) // 8192 on Darwin, 12288 for Android

        // 'removeItem(at:)' is deprecated: URL paths not yet implemented in Kotlin
        //try FileManager.default.removeItem(at: URL(fileURLWithPath: dbname, isDirectory: false))

        try FileManager.default.removeItem(atPath: dbname)
    }

    func testConnection() throws {
        let url: URL = URL.init(fileURLWithPath: "/tmp/testConnection.db", isDirectory: false)
        let conn: SQLContext = try SQLContext.open(url: url)
        //XCTAssertEqual(1.0, try conn.query(sql: "SELECT 1.0").singleValue()?.floatValue)
        //XCTAssertEqual(3.5, try conn.query(sql: "SELECT 1.0 + 2.5").singleValue()?.floatValue)
        conn.close()
    }
}

#if !SKIP

#if os(Linux)
import CSQLite
#else
import SQLite3
#endif

/// An *experimental* SQLite VFS implementation that accesses a remote database via HTTP range requests to fetch individual pages of the database.
///
/// Inspired by: https://github.com/phiresky/sql.js-httpvfs
/// See also: https://github.com/mlin/sqlite_web_vfs
public struct SQLHTTPVFS {
    public static let version: Int32 = 1
    public static let name = "HTTPVFS"

    public static func register(default: Bool = false) throws {
        let register_success = sqlite3_vfs_register(&httpvfs, `default` ? 1 : 0)
        if register_success != SQLITE_OK {
            throw CocoaError(.featureUnsupported)
        }

        // make sure we can find the VFS
        let httpvfs2 = sqlite3_vfs_find(SQLHTTPVFS.name)

        if httpvfs2 == nil {
            throw CocoaError(.featureUnsupported)
        }

        if httpvfs.zName != httpvfs2?.pointee.zName {
            throw CocoaError(.featureUnsupported)
        }
    }

    static var httpvfs = sqlite3_vfs(iVersion: SQLHTTPVFS.version,
                                     szOsFile: 0,
                                     mxPathname: 1024 * 10,
                                     pNext: nil,
                                     zName: SQLHTTPVFS.name.withCString(strdup),
                                     pAppData: nil,
                                     xOpen: xOpen,
                                     xDelete: xDelete,
                                     xAccess: xAccess,
                                     xFullPathname: xFullPathname,
                                     xDlOpen: xDlOpen,
                                     xDlError: xDlError,
                                     xDlSym: xDlSym,
                                     xDlClose: xDlClose,
                                     xRandomness: xRandomness,
                                     xSleep: xSleep,
                                     xCurrentTime: xCurrentTime,
                                     xGetLastError: xGetLastError,
                                     xCurrentTimeInt64: xCurrentTimeInt64,
                                     xSetSystemCall: xSetSystemCall,
                                     xGetSystemCall: xGetSystemCall,
                                     xNextSystemCall: xNextSystemCall)


    private static var _globalVFSFiles: VFSFile? = nil

    private static let xOpen: @convention(c) (_ vfs: UnsafeMutablePointer<sqlite3_vfs>?, _ zName: UnsafePointer<CChar>?, _ file: UnsafeMutablePointer<sqlite3_file>?, _ flags: Int32, _ pOutFlags: UnsafeMutablePointer<Int32>?) -> Int32 = { vfs, zName, file, flags, pOutFlags in
        check(vfs: vfs)
        SQLContext.logger.info("xOpen: \(zName.flatMap(String.init(cString:)) ?? "") flags: \(flags)")


        guard let zName = zName else {
            SQLContext.logger.warning("xOpen: cannot open empy path")
            return SQLITE_NOTFOUND
        }

        do {
            let fileHandle = try FileHandle(forReadingFrom: URL(fileURLWithFileSystemRepresentation: zName, isDirectory: false, relativeTo: nil))
            var vfsFile = VFSFile(handle: fileHandle)
            _globalVFSFiles = vfsFile

//            let vfsFilePointer = UnsafeMutablePointer<VFSFile>.allocate(capacity: 1)
//            vfsFilePointer.initialize(to: vfsFile)
//
//            vfsFilePointer.withMemoryRebound(to: sqlite3_file.self, capacity: 1) {
//                file!.pointee = $0.pointee
//            }

            file!.pointee = vfsFile.file

            return SQLITE_OK
        } catch {
            SQLContext.logger.warning("xOpen: error: \(error)")
            return SQLITE_NOTFOUND
        }
    }

    struct VFSFile {
        var file: sqlite3_file = sqlite3_file(pMethods: &impl)
        let handle: FileHandle
        var number = 12345

        private static func withFileHandle(_ file: UnsafeMutablePointer<sqlite3_file>?, block: (FileHandle) throws -> (Int32)) -> Int32 {
            do {
//                try file!.withMemoryRebound(to: VFSFile.self, capacity: 1) {
//                    assert($0.pointee.number == 12345, "sqlite3_file VFSFile: \($0.pointee.number) \($0.pointee.handle.fileDescriptor)")
//
//                    try block($0.pointee.handle)
//                }

                if let _globalVFSFiles = _globalVFSFiles {
                    return try block(_globalVFSFiles.handle)
                } else {
                    fatalError("no VFS")
                }
            } catch {
                SQLContext.logger.info("withFileHandle error: \(error)")
                return SQLITE_ERROR
            }
        }

        //private static var _implMethods = sqlite3_io_methods()

        /// The IO methods for accessing the database; must be first in the struct so that the `VFSFile` memory layout is the same as `sqlite3_io_methods`
        private static var impl: sqlite3_io_methods = {
            sqlite3_io_methods(iVersion: SQLHTTPVFS.version) { (file: UnsafeMutablePointer<sqlite3_file>?) in
                SQLContext.logger.info("xClose")
                return withFileHandle(file) { handle in
                    try handle.close()
                    return SQLITE_OK
                }
            } xRead: { (file: UnsafeMutablePointer<sqlite3_file>?, zBuf: UnsafeMutableRawPointer?, iAmt: Int32, iOfst: sqlite3_int64) in
                SQLContext.logger.info("xRead: \(iOfst) \(iAmt)")
                return withFileHandle(file) { handle in
                    let SQLITE_IOERR_SHORT_READ = (SQLITE_IOERR | (2<<8)) // SQLITE_IOERR_SHORT_READ but not visible in Swift because it is a #define

                    try handle.seek(toOffset: UInt64(iOfst))
                    guard let data = try handle.read(upToCount: Int(iAmt)) else {
                        return SQLITE_IOERR_SHORT_READ
                    }
                    let buffer = UnsafeMutableRawPointer.allocate(byteCount: data.count, alignment: MemoryLayout<UInt8>.alignment)
                    data.withUnsafeBytes { bytes in
                        buffer.copyMemory(from: bytes, byteCount: data.count)
                    }

                    zBuf?.copyMemory(from: buffer, byteCount: data.count)
                    //buffer.deallocate()
                    return data.count < iAmt ? SQLITE_IOERR_SHORT_READ : SQLITE_OK
                }
            } xWrite: { (file: UnsafeMutablePointer<sqlite3_file>?, _: UnsafeRawPointer?, _: Int32, _: sqlite3_int64) in
                SQLContext.logger.info("xWrite")
                return SQLITE_READONLY
            } xTruncate: { (file: UnsafeMutablePointer<sqlite3_file>?, _: sqlite3_int64) in
                SQLContext.logger.info("xTruncate")
                return SQLITE_READONLY
            } xSync: { (file: UnsafeMutablePointer<sqlite3_file>?, _: Int32) in
                SQLContext.logger.info("xSync")
                return SQLITE_OK
            } xFileSize: { (file: UnsafeMutablePointer<sqlite3_file>?, size: UnsafeMutablePointer<sqlite3_int64>?) in
                return withFileHandle(file) { handle in
                    let currentOffset = handle.offsetInFile
                    // restore offset
                    defer { try? handle.seek(toOffset: UInt64(currentOffset)) }

                    let fileSize: UInt64 = try handle.seekToEnd()
                    SQLContext.logger.info("xFileSize: \(fileSize)")
                    size?.pointee = sqlite3_int64(fileSize)
                    return SQLITE_OK
                }
            } xLock: { (file: UnsafeMutablePointer<sqlite3_file>?, _: Int32) in
                SQLContext.logger.info("xLock")
                return SQLITE_OK
            } xUnlock: { (file: UnsafeMutablePointer<sqlite3_file>?, _: Int32) in
                SQLContext.logger.info("xUnlock")
                return SQLITE_OK
            } xCheckReservedLock: { (file: UnsafeMutablePointer<sqlite3_file>?, _: UnsafeMutablePointer<Int32>?) in
                SQLContext.logger.info("xCheckReservedLock")
                return SQLITE_OK
            } xFileControl: { (file: UnsafeMutablePointer<sqlite3_file>?, op: Int32, parg: UnsafeMutableRawPointer?) in
                SQLContext.logger.info("xFileControl: op=\(op)")
                return SQLITE_OK // No xFileControl() verbs are implemented by this VFS
            } xSectorSize: { (file: UnsafeMutablePointer<sqlite3_file>?) in
                SQLContext.logger.info("xSectorSize")
                return 0
            } xDeviceCharacteristics: { (file: UnsafeMutablePointer<sqlite3_file>?) in
                SQLContext.logger.info("xDeviceCharacteristics")
                return 0 // e.g., SQLITE_IOCAP_ATOMIC
            } xShmMap: { (file: UnsafeMutablePointer<sqlite3_file>?, _: Int32, _: Int32, _: Int32, _: UnsafeMutablePointer<UnsafeMutableRawPointer?>?) in
                SQLContext.logger.info("xShmMap")
                return SQLITE_OK
            } xShmLock: { (file: UnsafeMutablePointer<sqlite3_file>?, _: Int32, _: Int32, _: Int32) in
                SQLContext.logger.info("xShmLock")
                return SQLITE_OK
            } xShmBarrier: { (file: UnsafeMutablePointer<sqlite3_file>?) in
                SQLContext.logger.info("xShmBarrier")
            } xShmUnmap: { (file: UnsafeMutablePointer<sqlite3_file>?, _: Int32) in
                SQLContext.logger.info("xShmUnmap")
                return SQLITE_OK
            } xFetch: { (file: UnsafeMutablePointer<sqlite3_file>?, _: sqlite3_int64, _: Int32, _: UnsafeMutablePointer<UnsafeMutableRawPointer?>?) in
                SQLContext.logger.info("xFetch")
                return SQLITE_OK
            } xUnfetch: { (file: UnsafeMutablePointer<sqlite3_file>?, _: sqlite3_int64, _: UnsafeMutableRawPointer?) in
                SQLContext.logger.info("xUnfetch")
                return SQLITE_OK
            }
        }()
    }

    private static func check(vfs: UnsafeMutablePointer<sqlite3_vfs>?) {
        assert(vfs?.pointee.zName == httpvfs.zName)
    }

    // MARK: sqlite_file functions



    // MARK: VFS Function

    private static let xFullPathname: @convention(c) (_ vfs: UnsafeMutablePointer<sqlite3_vfs>?, _ zName: UnsafePointer<CChar>?, _ nOut: Int32, _ zOut: UnsafeMutablePointer<CChar>?) -> Int32 = { vfs, zName, nOut, zOut in
        check(vfs: vfs)
        SQLContext.logger.info("xFullPathname: \(zName.flatMap(String.init(cString:)) ?? "")")
        // just copy the name directly from the source to the destination
        if let zName = zName, let zOut = zOut {
            var i = 0
            while zName[i] != 0 {
                zOut[i] = zName[i]
                i += 1
            }
            zOut[i] = 0
        }

        return SQLITE_OK
    }


    /// Query the file-system to see if the named file exists, is readable or is both readable and writable.
    private static let xAccess: @convention(c) (_ vfs: UnsafeMutablePointer<sqlite3_vfs>?, _ zName: UnsafePointer<CChar>?, _ flags: Int32, _ pResOut: UnsafeMutablePointer<Int32>?) -> Int32 = { vfs, zName, flags, pResOut in
        SQLContext.logger.info("xAccess: \(zName.flatMap(String.init(cString:)) ?? "") flags: \(flags)")
        check(vfs: vfs)
        guard let zName = zName else {
            return SQLITE_IOERR
        }
        let url = URL(fileURLWithFileSystemRepresentation: zName, isDirectory: false, relativeTo: nil)

        switch flags {
        case SQLITE_ACCESS_EXISTS:
            pResOut?.pointee = FileManager.default.fileExists(atPath: url.path) ? 1 : 0
        case SQLITE_ACCESS_READ:
            pResOut?.pointee = FileManager.default.isReadableFile(atPath: url.path) ? 1 : 0
        case SQLITE_ACCESS_READWRITE:
            pResOut?.pointee = FileManager.default.isWritableFile(atPath: url.path) ? 1 : 0
        default:
            break
        }
        return SQLITE_OK
    }

    /// Delete the file identified by argument zPath. If the dirSync parameter is non-zero, then ensure the file-system modification to delete the file has been synced to disk before returning.
    private static let xDelete: @convention(c) (_ vfs: UnsafeMutablePointer<sqlite3_vfs>?, _ zName: UnsafePointer<CChar>?, _ dirSync: Int32) -> Int32 = { vfs, zName, dirSync in
        SQLContext.logger.info("xDelete: \(zName.flatMap(String.init(cString:)) ?? "") dirSync: \(dirSync)")
        check(vfs: vfs)
        return SQLITE_OK
    }

    private static let xDlOpen: @convention(c) (_ vfs: UnsafeMutablePointer<sqlite3_vfs>?, _ zFilename: UnsafePointer<CChar>?) -> UnsafeMutableRawPointer? = { vfs, zFilename in
        SQLContext.logger.info("xDlOpen")
        check(vfs: vfs)
        return nil
    }

    private static let xDlError: @convention(c) (_ vfs: UnsafeMutablePointer<sqlite3_vfs>?, _ nByte: Int32, _ zErrMsg: UnsafeMutablePointer<CChar>?) -> Void = { vfs, nByte, zErrMsg in
        SQLContext.logger.info("xDlError")
        check(vfs: vfs)
    }

    private static let xDlSym: @convention(c) (_ vfs: UnsafeMutablePointer<sqlite3_vfs>?, _ ptr: UnsafeMutableRawPointer?, _ zSymbol: UnsafePointer<CChar>?) -> (@convention(c) () -> Void)? = { vfs, ptr, zSymbol in
        SQLContext.logger.info("xDlSym")
        check(vfs: vfs)
        return nil
    }

    private static let xDlClose: @convention(c) (_ vfs: UnsafeMutablePointer<sqlite3_vfs>?, _ ptr: UnsafeMutableRawPointer?) -> Void = { vfs, ptr in
        SQLContext.logger.info("xDlClose")
        check(vfs: vfs)
    }

    private static let xRandomness: @convention(c) (_ vfs: UnsafeMutablePointer<sqlite3_vfs>?, _ nByte: Int32, _ zOut: UnsafeMutablePointer<CChar>?) -> Int32 = { vfs, nByte, zOut in
        SQLContext.logger.info("xRandomness")
        check(vfs: vfs)
        return SQLITE_OK
    }

    private static let xSleep: @convention(c) (_ vfs: UnsafeMutablePointer<sqlite3_vfs>?, _ microseconds: Int32) -> Int32 = { vfs, microseconds in
        SQLContext.logger.info("xSleep")
        check(vfs: vfs)
        return SQLITE_OK
    }

    private static let xCurrentTime: @convention(c) (_ vfs: UnsafeMutablePointer<sqlite3_vfs>?, _ t: UnsafeMutablePointer<Double>?) -> Int32 = { vfs, t in
        SQLContext.logger.info("xCurrentTime")
        check(vfs: vfs)
        return SQLITE_OK
    }

    private static let xGetLastError: @convention(c) (_ vfs: UnsafeMutablePointer<sqlite3_vfs>?, _ p1: Int32, _ p2: UnsafeMutablePointer<CChar>?) -> Int32 = { vfs, p1, p2 in
        SQLContext.logger.info("xGetLastError")
        check(vfs: vfs)
        return SQLITE_OK
    }

    private static let xCurrentTimeInt64: @convention(c) (_ vfs: UnsafeMutablePointer<sqlite3_vfs>?, _ t: UnsafeMutablePointer<sqlite3_int64>?) -> Int32 = { vfs, t in
        SQLContext.logger.info("xCurrentTimeInt64")
        check(vfs: vfs)
        return SQLITE_OK
    }

    private static let xSetSystemCall: @convention(c) (_ vfs: UnsafeMutablePointer<sqlite3_vfs>?, _ p1: UnsafePointer<CChar>?, _ p2: sqlite3_syscall_ptr?) -> Int32 = { vfs, p1, p2 in
        SQLContext.logger.info("xSetSystemCall")
        check(vfs: vfs)
        return SQLITE_OK
    }

    private static let xGetSystemCall: @convention(c) (_ vfs: UnsafeMutablePointer<sqlite3_vfs>?, _ p1: UnsafePointer<CChar>?) -> sqlite3_syscall_ptr? = { vfs, p1 in
        SQLContext.logger.info("xGetSystemCall")
        check(vfs: vfs)
        return nil
    }

    private static let xNextSystemCall: @convention(c) (_ vfs: UnsafeMutablePointer<sqlite3_vfs>?, _ p1: UnsafePointer<CChar>?) -> UnsafePointer<CChar>? = { vfs, p1 in
        SQLContext.logger.info("xNextSystemCall")
        check(vfs: vfs)
        return nil
    }
}

#endif
