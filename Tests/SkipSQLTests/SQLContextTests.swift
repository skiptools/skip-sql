// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org
import XCTest
import OSLog
import Foundation
import SkipSQL

// SKIP INSERT: @org.junit.runner.RunWith(androidx.test.ext.junit.runners.AndroidJUnit4::class)
final class SQLiteTests: XCTestCase {
    let logger: Logger = Logger(subsystem: "skip.sql", category: "SQLiteTests")

    func testSQLite() throws {
        let sqlite = try SQLContext()

        _ = try sqlite.query(sql: "SELECT 1")
        _ = try sqlite.query(sql: "SELECT CURRENT_TIMESTAMP")
        _ = try sqlite.query(sql: "PRAGMA compile_options")

        var updates = 0
        sqlite.onUpdate { action, rowid, dbname, tblname in
            self.logger.info("update hook: \(action.rawValue) \(rowid) \(dbname).\(tblname)")
            updates += 1
        }

        try sqlite.exec(sql: "CREATE TABLE SQLTYPES(TXT TEXT, NUM NUMERIC, INT INTEGER, DBL REAL, BLB BLOB)")

        XCTAssertEqual(0, updates)
        try sqlite.exec(sql: "INSERT INTO SQLTYPES VALUES('ABC', 1.1, 1, 2.2, X'78797A')")
        XCTAssertEqual(1, updates)

        //try sqlite.exec(sql: "")

        /// Expect that the SQL statement will fail with the given error message
        func expectFail(sql: String, message: String) throws {
            do {
                try sqlite.exec(sql: sql)
                XCTFail("SQL Statement should not have succeeed")
            } catch let error as SQLError {
                XCTAssertEqual(message, error.msg)
            }
        }

        try expectFail(sql: "SELECT X", message: "no such column: X")
        try expectFail(sql: "CREATE TABLE", message: "incomplete input")
        try expectFail(sql: "Q", message: #"near "Q": syntax error"#)

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

        stmnt.reset()
        XCTAssertTrue(try stmnt.next())
        XCTAssertFalse(try stmnt.next())

        stmnt.reset()
        XCTAssertTrue(try stmnt.next())
        XCTAssertFalse(try stmnt.next())

        stmnt.close()

        /// Issues a count query
        func count(distinct: Bool = false, columns: String = "*", table: String) throws -> SQLValue? {
            try sqlite.prepare(sql: "SELECT COUNT(\(distinct ? "DISTINCT" : "") \(columns)) FROM \"\(table)\"").nextValues(close: true)?.first
        }

        try sqlite.mutex {
            XCTAssertEqual(.integer(1), try count(table: "SQLTYPES"))
        }

        // interrupt a transaction to issue a rollback, an make sure the row wasn't inserted
        try? sqlite.transaction {
            try sqlite.exec(sql: "INSERT INTO SQLTYPES VALUES('ZZZ', 1.1, 1, 2.2, X'78797A')")
            try sqlite.exec(sql: "skip_sql_throws_error_and_issues_rollback()")
        }

        XCTAssertEqual(.integer(1), try count(table: "SQLTYPES"))

        // now really insert the row and try some more queries
        try sqlite.transaction {
            //try sqlite.exec(sql: "INSERT INTO SQLTYPES VALUES('XYZ', 1.1, 1, 3.3, X'78797A')")
            try sqlite.exec(sql: "INSERT INTO SQLTYPES VALUES(?, ?, ?, ?, ?)", parameters: [.text("XYZ"), .float(1.1), .integer(1), .float(3.3), .blob(Data())])
        }

        XCTAssertEqual(SQLValue.integer(2), try count(table: "SQLTYPES"))
        XCTAssertEqual(SQLValue.integer(1), try count(distinct: true, columns: "NUM", table: "SQLTYPES"))

        do {
            let numquery = try sqlite.prepare(sql: "SELECT COUNT(*) FROM SQLTYPES WHERE DBL >= ?")
            try numquery.bind(.float(2.0), at: 1)
            XCTAssertEqual(SQLValue.integer(2), try numquery.nextValues(close: false)?.first)

            numquery.reset()
            try numquery.bind(.float(3.0), at: 1)
            XCTAssertEqual(SQLValue.integer(1), try numquery.nextValues(close: false)?.first)

            numquery.close()
        }

        do {
            for value in [
                SQLValue.integer(Int64(9)),
                SQLValue.float(9.9),
                SQLValue.float(Double.pi),
                SQLValue.text(""),
                SQLValue.text("ABCXYZ123"),
                //SQLValue.blob(Data()),
                SQLValue.blob(Data([UInt8(0x01), UInt8(0x02)])),
            ] {
                XCTAssertEqual(value, try sqlite.query(sql: "SELECT ?", parameters: [value]).first?.first)
            }
        }

        do {
            let squery = try sqlite.prepare(sql: "SELECT TXT FROM SQLTYPES")
            defer { squery.close() }
            XCTAssertTrue(try squery.next())
            XCTAssertEqual("ABC", squery.string(at: 0))
            XCTAssertTrue(try squery.next())
            XCTAssertEqual("XYZ", squery.string(at: 0))
        }

        do {
            let strquery = try sqlite.prepare(sql: "SELECT COUNT(*) FROM SQLTYPES WHERE TXT = ?")
            defer { strquery.close() }

            try strquery.bind(parameters: [.text("XYZ")])
            XCTAssertEqual(SQLValue.integer(1), try strquery.nextValues(close: false)?.first)

            strquery.reset()
            try strquery.bind(parameters: [.text("QRS")])
            XCTAssertEqual(SQLValue.integer(0), try strquery.nextValues(close: false)?.first)

            strquery.reset()
            try strquery.bind(parameters: [.text("ABC")])
            XCTAssertEqual(SQLValue.integer(1), try strquery.nextValues(close: false)?.first)

        }

        do {
            let blbquery = try sqlite.prepare(sql: "SELECT COUNT(*) FROM SQLTYPES WHERE BLB = ?")

            try blbquery.bind(.blob(Data()), at: 1)
            XCTAssertEqual(SQLValue.integer(1), try blbquery.nextValues(close: false)?.first)

            blbquery.reset()
            try blbquery.bind(.blob(Data([UInt8(0x78), UInt8(0x79), UInt8(0x7A)])), at: 1)
            XCTAssertEqual(SQLValue.integer(1), try blbquery.nextValues(close: false)?.first)

            blbquery.reset()
            // bind a 1mb param
            try blbquery.bind(.blob(Data(Array(repeating: UInt8(0x78), count: 1024 * 1024))), at: 1)
            XCTAssertEqual(SQLValue.integer(0), try blbquery.nextValues(close: false)?.first)

            blbquery.close()
        }

        // XCTAssertEqual(1, try sqlite.exec(sql: "DELETE FROM SQLTYPES LIMIT 1")) // Android fail: SQLiteLog: (1) near "LIMIT": syntax error in "DELETE FROM SQLTYPES LIMIT 1"
        // XCTAssertEqual(.integer(1), try count(table: "SQLTYPES"))

        try sqlite.exec(sql: "DELETE FROM SQLTYPES")
        XCTAssertEqual(SQLValue.integer(0), try count(table: "SQLTYPES"))

        try sqlite.exec(sql: "DROP TABLE SQLTYPES")

        sqlite.close() // make sure statements are closed or: "unable to close due to unfinalized statements or unfinished backups"

        XCTAssertEqual(3, updates)
    }

    func testSQLitePerformance() throws {
        let dir = URL.temporaryDirectory
        let dbpath = dir.appendingPathComponent("testSQLitePerformance-\(UUID().uuidString).db").path
        let sqlite = try SQLContext(path: dbpath, flags: [.create, .readWrite])
        defer { sqlite.close() }

        try sqlite.exec(sql: "CREATE TABLE BIGTABLE (STRING TEXT)")

        let startTime = Date.now
        logger.log("writing to db: \(dbpath)")
        let rows = 1_000_000
        let insert = try sqlite.prepare(sql: "INSERT INTO BIGTABLE VALUES (?)")
        defer { insert.close() }
        try sqlite.transaction {
            for _ in 1...rows {
                try insert.update(parameters: [.text(UUID().uuidString)])
            }
        }
        let t = Date.now.timeIntervalSince(startTime)
        logger.log("wrote \(rows) rows to db in \(t): \(dbpath)")
    }
}
