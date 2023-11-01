// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org
import XCTest
import OSLog
import Foundation
import SkipSQL

final class SQLiteTests: XCTestCase {
    let logger: Logger = Logger(subsystem: "skip.sql", category: "SQLiteTests")

    func testSQLite() throws {
        let sqlite = try SQLContext()

        try sqlite.exec(sql: "SELECT 1")
        try sqlite.exec(sql: "SELECT CURRENT_TIMESTAMP")
        try sqlite.exec(sql: "PRAGMA compile_options")

        try sqlite.exec(sql: "CREATE TABLE SQLTYPES(TXT TEXT, NUM NUMERIC, INT INTEGER, DBL REAL, BLB BLOB)")
        try sqlite.exec(sql: "INSERT INTO SQLTYPES VALUES('ABC', 1.1, 1, 2.2, 'XYZ')")
        do {
            let stmnt = try sqlite.prepare(sql: "SELECT * FROM SQLTYPES")
            XCTAssertEqual(["TXT", "NUM", "INT", "DBL", "BLB"], stmnt.columnNames)
            // XCTAssertEqual(Set(["SQLTYPES"]), Set(stmnt.columnTables)) // unavailable on Android
            XCTAssertEqual(["TEXT", "NUMERIC", "INTEGER", "REAL", "BLOB"], stmnt.columnTypes)
            XCTAssertEqual([nil, nil, nil, nil, nil], stmnt.stringValues())
            XCTAssertTrue(try stmnt.next())
            XCTAssertEqual(["ABC", "1.1", "1", "2.2", "XYZ"], stmnt.stringValues())
            XCTAssertFalse(try stmnt.next())
            XCTAssertEqual([nil, nil, nil, nil, nil], stmnt.stringValues())
            try stmnt.close()
        }
        try sqlite.exec(sql: "DROP TABLE SQLTYPES")

        try sqlite.close() // make sure statements are closed or: "unable to close due to unfinalized statements or unfinished backups"
    }
}
