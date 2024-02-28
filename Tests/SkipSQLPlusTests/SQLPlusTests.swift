// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org
import XCTest
import OSLog
import Foundation
import SkipSQL
import SkipSQLPlus

// SKIP INSERT: @org.junit.runner.RunWith(androidx.test.ext.junit.runners.AndroidJUnit4::class)
final class SQLPlusTests: XCTestCase {
    let logger: Logger = Logger(subsystem: "skip.sql", category: "SQLPlusTests")

    func testSQLPlus() throws {
        let sqlplus = SQLContext(configuration: .plus)
        _ = try sqlplus.query(sql: "SELECT 1")
        _ = try sqlplus.query(sql: "SELECT CURRENT_TIMESTAMP")
        _ = try sqlplus.query(sql: "PRAGMA compile_options")

        // ensure that FTS works
        _ = try sqlplus.query(sql: "CREATE VIRTUAL TABLE \"documents\" USING fts5(content)")

        let stmnt = try sqlplus.prepare(sql: "SELECT 1")
        XCTAssertEqual("SELECT 1", stmnt.sql)

        XCTAssertEqual(0, stmnt.parameterCount)
        try stmnt.close()

        // the locally built SQLite version (contrast with the macOS version 3.43.2)
        XCTAssertEqual([SQLValue.text("3.44.2")], try sqlplus.query(sql: "SELECT sqlite_version();").first)
        XCTAssertEqual([SQLValue.text("ATOMIC_INTRINSICS=1")], try sqlplus.query(sql: "PRAGMA compile_options").first)
        XCTAssertEqual([SQLValue.text("4.5.6 community")], try sqlplus.query(sql: "PRAGMA cipher_version").first)
        //XCTAssertEqual([SQLValue.text("PRAGMA cipher_default_kdf_iter = 256000;")], try sqlplus.query(sql: "PRAGMA cipher_default_settings").first)
        //XCTAssertEqual([SQLValue.text("XXX")], try sqlplus.query(sql: "PRAGMA cipher_provider").first)
        //XCTAssertEqual([SQLValue.text("XXX")], try sqlplus.query(sql: "PRAGMA cipher_provider_version").first)
    }

    func testSQLCipher() throws {
        func createDB(key: String?, string: String) throws -> Data {
            let dbPath = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("db")

            logger.log("testEncryption: checking db: \(dbPath.path)")
            let db = try SQLContext(path: dbPath.path, flags: [.create, .readWrite], configuration: .plus)
            if let key = key {
                _ = try db.query(sql: "PRAGMA key = '\(key)'")
            }

            //_ = try db.query(sql: #"PRAGMA cipher_plaintext_header_size = 32"#)
            //_ = try db.query(sql: #"PRAGMA cipher_salt = "x'01010101010101010101010101010101'""#)
            //_ = try db.query(sql: #"PRAGMA user_version = 1; -- force header write"#)

            try db.exec(sql: #"CREATE TABLE SOME_TABLE(col);"#)
            try db.exec(sql: #"INSERT INTO SOME_TABLE(col) VALUES(?);"#, parameters: [.text(string)])

            try db.close()

            let dbContents = try Data(contentsOf: dbPath)
            return dbContents
        }

        let str = "SOME_STRING"
        let data1 = try createDB(key: nil, string: str)
        let data2 = try createDB(key: "passkey", string: str)

        // check the header of the database file
        // an encrypted data (that does not use PRAGMA cipher_plaintext_header_size = X) should not contains the standard sqlite header
        let sqliteHeader = "SQLite format 3"
        XCTAssertEqual(sqliteHeader.utf8.hex(), "53514c69746520666f726d61742033")

        XCTAssertTrue(data1.hex().hasPrefix(sqliteHeader.utf8.hex()), "unencrypted database should have contained the SQLite header")
        XCTAssertFalse(data2.hex().hasPrefix(sqliteHeader.utf8.hex()), "encrypted database should not have contained the SQLite header")

        XCTAssertTrue(data1.hex().contains(str.utf8.hex()), "unencrypted database should have contained the test string")
        XCTAssertFalse(data2.hex().contains(str.utf8.hex()), "encrypted database should not have contained the test string")


    }
}

extension Sequence where Element == UInt8 {
    /// Convert this sequence of bytes into a hex string
    public func hex() -> String {
        #if SKIP
        // java.util.IllegalFormatConversionException: x != kotlin.UByte
        //map { String(format: "%02x", $0) }.joined()
        // This declaration needs opt-in. Its usage must be marked with '@kotlin.ExperimentalStdlibApi' or '@OptIn(kotlin.ExperimentalStdlibApi::class)'
        //kotlin.ByteArray(self).toHexString()
        map { String(format: "%02x", Int($0)) }.joined()
        #else
        map { String(format: "%02x", $0) }.joined()
        #endif
    }
}
