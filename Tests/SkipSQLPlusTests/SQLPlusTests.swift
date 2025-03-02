// Copyright 2023–2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
import XCTest
#if canImport(OSLog)
import OSLog
#endif
import Foundation
import SkipSQL
import SkipSQLPlus

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
        XCTAssertEqual([SQLValue.text("3.46.1")], try sqlplus.query(sql: "SELECT sqlite_version()").first)
        XCTAssertEqual([SQLValue.text("ATOMIC_INTRINSICS=1")], try sqlplus.query(sql: "PRAGMA compile_options").first)
        XCTAssertEqual([SQLValue.text("4.6.1 community")], try sqlplus.query(sql: "PRAGMA cipher_version").first)
        //XCTAssertEqual([SQLValue.text("PRAGMA cipher_default_kdf_iter = 256000")], try sqlplus.query(sql: "PRAGMA cipher_default_settings").first)
        //XCTAssertEqual([SQLValue.text("XXX")], try sqlplus.query(sql: "PRAGMA cipher_provider").first)
        //XCTAssertEqual([SQLValue.text("XXX")], try sqlplus.query(sql: "PRAGMA cipher_provider_version").first)
    }

    func testSQLiteJSON() throws {
        let sqlplus = SQLContext(configuration: .plus)
        // The $[#] path feature in the JSON functions was added in version 3.31.0
        XCTAssertEqual([SQLValue.text("3.46.1")], try sqlplus.query(sql: "SELECT sqlite_version()").first)

        try sqlplus.exec(sql: #"CREATE TABLE users (id INTEGER PRIMARY KEY, profile JSON)"#)

        try sqlplus.exec(sql: #"INSERT INTO users (id, profile) VALUES (1, ?)"#, parameters: [.text(#"{"name": "Alice", "age": 30}"#)])
        try sqlplus.exec(sql: #"INSERT INTO users (id, profile) VALUES (2, ?)"#, parameters: [.text(#"{"name": "Bob", "age": 25}"#)])

        let j1 = try sqlplus.query(sql: "SELECT json_extract(profile, '$.name') as name FROM users WHERE id = ?", parameters: [.integer(1)]).first
        XCTAssertEqual([.text("Alice")], j1)

        let j2 = try sqlplus.query(sql: "SELECT json_extract(profile, '$.name') as name, json_extract(profile, '$.age') as age FROM users WHERE id = ?", parameters: [.integer(2)]).first
        XCTAssertEqual([.text("Bob"), .integer(25)], j2)

        XCTAssertEqual([.text("[1]")], try sqlplus.query(sql: "SELECT JSON_QUOTE(JSON('[1]'))").first)
        XCTAssertEqual([.integer(0)], try sqlplus.query(sql: "SELECT JSON_VALID('{\"x\":35')").first)
        XCTAssertEqual([.text("array")], try sqlplus.query(sql: "SELECT JSON_TYPE('{\"a\":[2,3.5,true,false,null,\"x\"]}', '$.a')").first)
        XCTAssertEqual([.text("[1,3,4]")], try sqlplus.query(sql: "SELECT JSON_REMOVE('[0,1,2,3,4]', '$[2]','$[0]')").first)
        XCTAssertEqual([.text("[1,3,4]")], try sqlplus.query(sql: "SELECT JSON_REMOVE('[0,1,2,3,4]', '$[2]','$[0]')").first)
        XCTAssertEqual([.text("{\"a\":1,\"b\":2,\"c\":3,\"d\":4}")], try sqlplus.query(sql: "SELECT JSON_PATCH('{\"a\":1,\"b\":2}','{\"c\":3,\"d\":4}')").first)
        XCTAssertEqual([.text("{\"c\":{\"e\":5}}")], try sqlplus.query(sql: "SELECT JSON_OBJECT('c', JSON('{\"e\":5}'))").first)
        XCTAssertEqual([.text("{\"a\":99,\"c\":4}")], try sqlplus.query(sql: "SELECT JSON_SET('{\"a\":2,\"c\":4}', '$.a', 99)").first)
        XCTAssertEqual([.text("{\"a\":99,\"c\":4}")], try sqlplus.query(sql: "SELECT JSON_REPLACE('{\"a\":2,\"c\":4}', '$.a', 99)").first)
        XCTAssertEqual([.text("[1,2,3,4,99]")], try sqlplus.query(sql: "SELECT JSON_INSERT('[1,2,3,4]','$[#]',99)").first)
        XCTAssertEqual([.text("[[4,5],2]")], try sqlplus.query(sql: "SELECT JSON_EXTRACT('{\"a\":2,\"c\":[4,5]}','$.c','$.a')").first)
        XCTAssertEqual([.integer(3)], try sqlplus.query(sql: "SELECT JSON_ARRAY_LENGTH('{\"one\":[1,2,3]}', '$.one')").first)
        XCTAssertEqual([.integer(4)], try sqlplus.query(sql: "SELECT JSON_ARRAY_LENGTH('[1,2,3,4]')").first)
        XCTAssertEqual([.text("[1,2,\"3\",4]")], try sqlplus.query(sql: "SELECT JSON_ARRAY(1, 2, '3', 4)").first)
        XCTAssertEqual([.text("{\"a\":1,\"b\":2,\"c\":3,\"d\":4}")], try sqlplus.query(sql: "SELECT JSON_PATCH('{\"a\":1,\"b\":2}', '{\"c\":3,\"d\":4}')").first)
    }

    func testSQLCipher() throws {
        func createDB(key: String?, plaintextHeader: Int? = nil, string: String) throws -> Data {
            let dbPath = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("db")

            logger.log("testEncryption: checking db: \(dbPath.path)")
            let db = try SQLContext(path: dbPath.path, flags: [.create, .readWrite], configuration: .plus)
            if let key = key {
                _ = try db.query(sql: "PRAGMA key = '\(key)'")
            }
            if let plaintextHeader = plaintextHeader {
                _ = try db.query(sql: "PRAGMA cipher_plaintext_header_size = \(plaintextHeader)")
            }

            //_ = try db.query(sql: #"PRAGMA cipher_plaintext_header_size = 32"#)
            //_ = try db.query(sql: #"PRAGMA cipher_salt = "x'01010101010101010101010101010101'""#)
            //_ = try db.query(sql: #"PRAGMA user_version = 1; -- force header write"#)

            try db.exec(sql: #"CREATE TABLE SOME_TABLE(col)"#)
            try db.exec(sql: #"INSERT INTO SOME_TABLE(col) VALUES(?)"#, parameters: [.text(string)])

            try db.close()

            let dbContents = try Data(contentsOf: dbPath)
            return dbContents
        }

        let str = "SOME_STRING"
        let data1 = try createDB(key: nil, string: str)
        let data2 = try createDB(key: "passkey", string: str)
        let data3 = try createDB(key: "passkey", plaintextHeader: 32, string: str)

        // check the header of the database file
        // an encrypted data (that does not use PRAGMA cipher_plaintext_header_size = X) should not contains the standard sqlite header
        let sqliteHeader = "SQLite format 3"
        XCTAssertEqual(sqliteHeader.utf8.hex(), "53514c69746520666f726d61742033")

        XCTAssertTrue(data1.hex().hasPrefix(sqliteHeader.utf8.hex()), "unencrypted database should have contained the SQLite header")
        XCTAssertFalse(data2.hex().hasPrefix(sqliteHeader.utf8.hex()), "encrypted database should not have contained the SQLite header")
        XCTAssertTrue(data3.hex().hasPrefix(sqliteHeader.utf8.hex()), "encrypted database should have contained the SQLite header when using cipher_plaintext_header_size")

        XCTAssertTrue(data1.hex().contains(str.utf8.hex()), "unencrypted database should have contained the test string")
        XCTAssertFalse(data2.hex().contains(str.utf8.hex()), "encrypted database should not have contained the test string")
        XCTAssertFalse(data3.hex().contains(str.utf8.hex()), "encrypted database should not have contained the test string")


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
