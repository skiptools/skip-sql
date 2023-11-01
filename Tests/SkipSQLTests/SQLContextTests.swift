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
        try sqlite.exec(sql: "INSERT INTO SQLTYPES VALUES('ABC', 1.1, 1, 2.2, X'78797A')")

        do {
            let stmnt = try sqlite.prepare(sql: "SELECT * FROM SQLTYPES")
            XCTAssertEqual(["TXT", "NUM", "INT", "DBL", "BLB"], stmnt.columnNames)
            // XCTAssertEqual(Set(["SQLTYPES"]), Set(stmnt.columnTables)) // unavailable on Android
            XCTAssertEqual(["TEXT", "NUMERIC", "INTEGER", "REAL", "BLOB"], stmnt.columnTypes)
            XCTAssertEqual([nil, nil, nil, nil, nil], stmnt.stringValues())
            XCTAssertTrue(try stmnt.next())
            XCTAssertEqual(["ABC", "1.1", "1", "2.2", "xyz"], stmnt.stringValues())

            XCTAssertEqual(.null, stmnt.type(at: -1)) // underflow
            XCTAssertEqual(.text, stmnt.type(at: 0))
            XCTAssertEqual(.float, stmnt.type(at: 1))
            XCTAssertEqual(.integer, stmnt.type(at: 2))
            XCTAssertEqual(.float, stmnt.type(at: 3))
            //XCTAssertEqual(.blob, stmnt.type(at: 4))
            XCTAssertEqual(.null, stmnt.type(at: stmnt.columnCount + 1)) // overflow

            XCTAssertEqual(0.0, stmnt.double(at: -1)) // underflow
            XCTAssertEqual(0.0, stmnt.double(at: 0))
            XCTAssertEqual(1.1, stmnt.double(at: 1))
            XCTAssertEqual(1.0, stmnt.double(at: 2))
            XCTAssertEqual(2.2, stmnt.double(at: 3))
            XCTAssertEqual(0.0, stmnt.double(at: 4))
            XCTAssertEqual(0.0, stmnt.double(at: stmnt.columnCount + 1)) // overflow

            XCTAssertEqual(0, stmnt.integer(at: -1))
            XCTAssertEqual(0, stmnt.integer(at: 0))
            XCTAssertEqual(1, stmnt.integer(at: 1))
            XCTAssertEqual(1, stmnt.integer(at: 2))
            XCTAssertEqual(2, stmnt.integer(at: 3))
            XCTAssertEqual(0, stmnt.integer(at: 4))
            XCTAssertEqual(0, stmnt.integer(at: stmnt.columnCount + 1))

            XCTAssertEqual(nil, stmnt.blob(at: -1))
            XCTAssertEqual("ABC".data(using: .utf8), stmnt.blob(at: 0))
            XCTAssertEqual("1.1".data(using: .utf8), stmnt.blob(at: 1))
            XCTAssertEqual("1".data(using: .utf8), stmnt.blob(at: 2))
            XCTAssertEqual("2.2".data(using: .utf8), stmnt.blob(at: 3))
            XCTAssertEqual("xyz".data(using: .utf8), stmnt.blob(at: 4))
            XCTAssertEqual(nil, stmnt.blob(at: stmnt.columnCount + 1))

            XCTAssertFalse(try stmnt.next())
            XCTAssertEqual([nil, nil, nil, nil, nil], stmnt.stringValues())
            try stmnt.close()
        }

        /// Issues a count query
        func count(distinct: Bool = false, columns: String = "*", table: String) throws -> SQLValue? {
            try sqlite.prepare(sql: "SELECT COUNT(\(distinct ? "DISTINCT" : "") \(columns)) FROM \"\(table)\"").nextValues(close: true)?.first
        }

        XCTAssertEqual(.integer(1), try count(table: "SQLTYPES"))

        // interrupt a transaction to issue a rollback, an make sure the row wasn't inserted
        try? sqlite.transaction {
            try sqlite.exec(sql: "INSERT INTO SQLTYPES VALUES('ABC', 1.1, 1, 2.2, X'78797A')")
            try sqlite.exec(sql: "illegal_sql_throws_error_and_issues_rollback()")
        }

        XCTAssertEqual(.integer(1), try count(table: "SQLTYPES"))


        // now really insert the row and try some more queries
        try sqlite.transaction {
            try sqlite.exec(sql: "INSERT INTO SQLTYPES VALUES('ABC', 1.1, 1, 2.2, X'78797A')")
        }
        XCTAssertEqual(.integer(2), try count(table: "SQLTYPES"))
        XCTAssertEqual(.integer(1), try count(distinct: true, columns: "NUM", table: "SQLTYPES"))

        try sqlite.exec(sql: "DROP TABLE SQLTYPES")

        try sqlite.close() // make sure statements are closed or: "unable to close due to unfinalized statements or unfinished backups"
    }
}
