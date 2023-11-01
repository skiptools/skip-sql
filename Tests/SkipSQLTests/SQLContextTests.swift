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

        try sqlite.exec(sql: "CREATE TABLE SQLTYPES(TXT TEXT, NUM NUMERIC, INT INTEGER, DBL REAL, BLB BLOB)")
        try sqlite.exec(sql: "INSERT INTO SQLTYPES VALUES('ABC', 1.1, 1, 2.2, 'XYZ')")
        do {
            let stmnt = try sqlite.prepare(sql: "SELECT * FROM SQLTYPES")
            XCTAssertEqual(["TXT", "NUM", "INT", "DBL", "BLB"], stmnt.columnNames)
            XCTAssertEqual(Set(["SQLTYPES"]), Set(stmnt.columnTables))
            XCTAssertTrue(try stmnt.next())
            XCTAssertFalse(try stmnt.next())
            try stmnt.close()
        }
        try sqlite.exec(sql: "DROP TABLE SQLTYPES")

        try sqlite.close() // make sure statements are closed or: "unable to close due to unfinalized statements or unfinished backups"
    }
}

//// SKIP INSERT: @org.junit.runner.RunWith(androidx.test.ext.junit.runners.AndroidJUnit4::class)
//// SKIP INSERT: @org.robolectric.annotation.Config(manifest=org.robolectric.annotation.Config.NONE, sdk = [33])
//@available(macOS 13, macCatalyst 16, iOS 16, tvOS 16, watchOS 8, *)
//final class SQLContextTests: XCTestCase {
//    let logger: Logger = Logger(subsystem: "skip.sql", category: "SQLContextTests")
//
//    func testCheckSQLVersion() throws {
//        let version = try SQLContext().query(sql: "SELECT sqlite_version()").nextRow(close: true)
//        #if SKIP
//        // 3.31.1 on Android 11 (API level 30)
//        // 3.22.0 on API level 29
//        //XCTAssertEqual("3.32.2", version?.first?.textValue) 
//        #else
//        XCTAssertEqual("3.39.5", version?.first?.textValue)
//        #endif
//    }
//
//    func testSkipSQL() throws {
//        //var random = PseudoRandomNumberGenerator(seed: 1234)
//        //let rnd = (0...999999).randomElement(using: &random)!
//        let rnd = 1
//        let dbname = "\(NSTemporaryDirectory())/demosql_\(rnd).db"
//
//        print("connecting to: " + dbname)
//        let conn = try SQLContext(dbname)
//
//        let version = try conn.query(sql: "select sqlite_version()").nextRow(close: true)?.first?.textValue
//        print("SQLite version: " + (version ?? "")) // Kotlin: 3.28.0 Swift: 3.39.5
//
//        XCTAssertEqual(try conn.query(sql: "SELECT 1.0").nextRow(close: true)?.first?.floatValue, 1.0)
//        XCTAssertEqual(try conn.query(sql: "SELECT 'ABC'").nextRow(close: true)?.first?.textValue, "ABC")
//        XCTAssertEqual(try conn.query(sql: "SELECT lower('ABC')").nextRow(close: true)?.first?.textValue, "abc")
//        XCTAssertEqual(try conn.query(sql: "SELECT 3.0/2.0, 4.0*2.5").nextRow(close: true)?.last?.floatValue, 10.0)
//
//        XCTAssertEqual(try conn.query(sql: "SELECT ?", params: [SQLValue.text("ABC")]).nextRow(close: true)?.first?.textValue, "ABC")
//        XCTAssertEqual(try conn.query(sql: "SELECT upper(?), lower(?)", params: [SQLValue.text("ABC"), SQLValue.text("XYZ")]).nextRow(close: true)?.last?.textValue, "xyz")
//
//        #if !SKIP
//        XCTAssertEqual(try conn.query(sql: "SELECT ?", params: [SQLValue.float(1.5)]).nextRow(close: true)?.first?.floatValue, 1.5) // compiles but AssertionError in Kotlin
//        #endif
//        
//        XCTAssertEqual(try conn.query(sql: "SELECT 1").nextRow(close: true)?.first?.integerValue, Int64(1))
//
//        do {
//            try conn.execute(sql: "DROP TABLE FOO")
//        } catch {
//            // exception expected when re-running on existing database
//        }
//
//        try conn.execute(sql: "CREATE TABLE FOO (NAME VARCHAR, NUM INTEGER, DBL FLOAT)")
//        for i in 1...10 {
//            try conn.execute(sql: "INSERT INTO FOO VALUES(?, ?, ?)", params: [SQLValue.text("NAME_" + i.description), SQLValue.integer(Int64(i)), SQLValue.float(Double(i))])
//        }
//
//        let cursor = try conn.query(sql: "SELECT * FROM FOO")
//        let colcount = cursor.columnCount
//        print("columns: \(colcount)")
//        XCTAssertEqual(colcount, 3)
//
//        var row = 0
//        let consoleWidth = 45
//
//        while try cursor.next() {
//            if row == 0 {
//                // header and border rows
//                try print(cursor.rowText(header: false, values: false, width: consoleWidth))
//                try print(cursor.rowText(header: true, values: false, width: consoleWidth))
//                try print(cursor.rowText(header: false, values: false, width: consoleWidth))
//            }
//
//            try print(cursor.rowText(header: false, values: true, width: consoleWidth))
//
//            row += 1
//
//            try XCTAssertEqual(cursor.getColumnName(column: 0), "NAME")
//            try XCTAssertEqual(cursor.getColumnType(column: 0), ColumnType.text)
//            try XCTAssertEqual(cursor.getString(column: 0), "NAME_\(row)")
//
//            try XCTAssertEqual(cursor.getColumnName(column: 1), "NUM")
//            try XCTAssertEqual(cursor.getColumnType(column: 1), ColumnType.integer)
//            try XCTAssertEqual(cursor.getInt64(column: 1), Int64(row))
//
//            try XCTAssertEqual(cursor.getColumnName(column: 2), "DBL")
//            try XCTAssertEqual(cursor.getColumnType(column: 2), ColumnType.float)
//            try XCTAssertEqual(cursor.getDouble(column: 2), Double(row))
//        }
//
//        try print(cursor.rowText(header: false, values: false, width: consoleWidth))
//
//        try cursor.close()
//        XCTAssertEqual(cursor.closed, true)
//
//        try conn.execute(sql: "DROP TABLE FOO")
//
//        conn.close()
//        XCTAssertEqual(conn.closed, true)
//
//        // .init not being resolved for some reason…
//
//        // let dataFile: Data = try Data.init(contentsOfFile: dbname)
//        // XCTAssertEqual(dataFile.count > 1024) // 8192 on Darwin, 12288 for Android
//
//        // 'removeItem(at:)' is deprecated: URL paths not yet implemented in Kotlin
//        //try FileManager.default.removeItem(at: URL(fileURLWithPath: dbname, isDirectory: false))
//
//        try FileManager.default.removeItem(atPath: dbname)
//    }
//
//    func testConnection() throws {
//        let url: URL = URL.init(fileURLWithPath: "\(NSTemporaryDirectory())/testConnection.db", isDirectory: false)
//        let conn: SQLContext = try SQLContext.open(url: url)
//        //XCTAssertEqual(1.0, try conn.query(sql: "SELECT 1.0").singleValue()?.floatValue)
//        //XCTAssertEqual(3.5, try conn.query(sql: "SELECT 1.0 + 2.5").singleValue()?.floatValue)
//        conn.close()
//    }
//}
