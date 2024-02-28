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

    func testSQLite() throws {
        let sqlplus = SQLContext(SQLite3: SQLPlusLibrary())
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

    }
}
