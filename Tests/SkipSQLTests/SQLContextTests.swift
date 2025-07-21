// Copyright 2023–2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
import XCTest
import OSLog
import Foundation
import SkipSQL

/*
 This test is shared between SkipSQLTests and SkipSQLPlusTests using a symbolic link.

 It uses the locally defined `SQLiteConfiguration.test` extension to
 select the SQLite library that should be used for the tests.
 */

final class SQLContextTests: XCTestCase {
    let logger: Logger = Logger(subsystem: "skip.sql", category: "SQLiteTests")

    func testSQLiteTrace() throws {
        let ctx = SQLContext(configuration: .test)

        // track executed SQL statements
        var sql: [String] = []
        ctx.trace { sql.append($0) }

        do {
            _ = try ctx.query(sql: "SELECT ?", parameters: [.text("ABC")])
            XCTAssertEqual("SELECT 'ABC'", sql.last)
        }

        ctx.trace(nil)
        try ctx.close()
    }

    func testSQLite() throws {
        let sqlite = SQLContext(configuration: .test)

        _ = try sqlite.query(sql: "SELECT 1")
        _ = try sqlite.query(sql: "SELECT CURRENT_TIMESTAMP")
        _ = try sqlite.query(sql: "PRAGMA compile_options")

#if os(macOS)
        //XCTAssertEqual([SQLValue.text("3.43.2")], try sqlite.query(sql: "SELECT sqlite_version()").first)
        XCTAssertEqual([SQLValue.text("ATOMIC_INTRINSICS=1")], try sqlite.query(sql: "PRAGMA compile_options").first)
#endif

        var updates = 0
        sqlite.onUpdate { action, rowid, dbname, tblname in
            self.logger.info("update hook: \(action.rawValue) \(rowid) \(dbname).\(tblname)")
            updates += 1
        }

        try sqlite.exec(sql: "CREATE TABLE DEMO_TABLE(TXT TEXT, NUM NUMERIC, INT INTEGER, DBL REAL, BLB BLOB)")

        XCTAssertEqual(0, updates)
        try sqlite.exec(sql: "INSERT INTO DEMO_TABLE VALUES('ABC', 1.1, 1, 2.2, X'78797A')")
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

        let stmnt = try sqlite.prepare(sql: "SELECT * FROM DEMO_TABLE")
        XCTAssertEqual(["TXT", "NUM", "INT", "DBL", "BLB"], stmnt.columnNames)
        // XCTAssertEqual(Set(["DEMO_TABLE"]), Set(stmnt.columnTables)) // unavailable on Android
        XCTAssertEqual(["TEXT", "NUMERIC", "INTEGER", "REAL", "BLOB"], stmnt.columnTypes)
        XCTAssertEqual([nil, nil, nil, nil, nil], stmnt.stringValues())
        XCTAssertTrue(try stmnt.next())
        XCTAssertEqual(["ABC", "1.1", "1", "2.2", "xyz"], stmnt.stringValues())

        XCTAssertEqual(.null, stmnt.type(at: -1)) // underflow
        XCTAssertEqual(.text, stmnt.type(at: 0))
        XCTAssertEqual(.real, stmnt.type(at: 1))
        XCTAssertEqual(.long, stmnt.type(at: 2))
        XCTAssertEqual(.real, stmnt.type(at: 3))
        //XCTAssertEqual(.blob, stmnt.type(at: 4))
        XCTAssertEqual(.null, stmnt.type(at: stmnt.columnCount + 1)) // overflow

        XCTAssertEqual(0.0, stmnt.real(at: -1)) // underflow
        XCTAssertEqual(0.0, stmnt.real(at: 0))
        XCTAssertEqual(1.1, stmnt.real(at: 1))
        XCTAssertEqual(1.0, stmnt.real(at: 2))
        XCTAssertEqual(2.2, stmnt.real(at: 3))
        XCTAssertEqual(0.0, stmnt.real(at: 4))
        XCTAssertEqual(0.0, stmnt.real(at: stmnt.columnCount + 1)) // overflow

        XCTAssertEqual(0, stmnt.long(at: -1))
        XCTAssertEqual(0, stmnt.long(at: 0))
        XCTAssertEqual(1, stmnt.long(at: 1))
        XCTAssertEqual(1, stmnt.long(at: 2))
        XCTAssertEqual(2, stmnt.long(at: 3))
        XCTAssertEqual(0, stmnt.long(at: 4))
        XCTAssertEqual(0, stmnt.long(at: stmnt.columnCount + 1))

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

        try stmnt.close()

        /// Issues a count query
        func count(distinct: Bool = false, columns: String = "*", table: String) throws -> SQLValue? {
            try sqlite.prepare(sql: "SELECT COUNT(\(distinct ? "DISTINCT " : "")\(columns)) FROM \"\(table)\"").nextValues(close: true)?.first
        }

        try sqlite.mutex {
            XCTAssertEqual(.long(1), try count(table: "DEMO_TABLE"))
        }

        // interrupt a transaction to issue a rollback, an make sure the row wasn't inserted
        try? sqlite.transaction {
            try sqlite.exec(sql: "INSERT INTO DEMO_TABLE VALUES('ZZZ', 1.1, 1, 2.2, X'78797A')")
            try sqlite.exec(sql: "skip_sql_throws_error_and_issues_rollback()")
        }

        XCTAssertEqual(.long(1), try count(table: "DEMO_TABLE"))

        // now really insert the row and try some more queries
        try sqlite.transaction {
            //try sqlite.exec(sql: "INSERT INTO DEMO_TABLE VALUES('XYZ', 1.1, 1, 3.3, X'78797A')")
            try sqlite.exec(sql: "INSERT INTO DEMO_TABLE VALUES(?, ?, ?, ?, ?)", parameters: [.text("XYZ"), .real(1.1), .long(1), .real(3.3), .blob(Data())])
        }

        XCTAssertEqual(SQLValue.long(2), try count(table: "DEMO_TABLE"))
        XCTAssertEqual(SQLValue.long(1), try count(distinct: true, columns: "NUM", table: "DEMO_TABLE"))

        do {
            let numquery = try sqlite.prepare(sql: "SELECT COUNT(*) FROM DEMO_TABLE WHERE DBL >= ?")
            try numquery.bind(.real(2.0), at: 1)
            XCTAssertEqual(SQLValue.long(2), try numquery.nextValues(close: false)?.first)

            numquery.reset()
            try numquery.bind(.real(3.0), at: 1)
            XCTAssertEqual(SQLValue.long(1), try numquery.nextValues(close: false)?.first)

            try numquery.close()
        }

        do {
            for value in [
                SQLValue.long(Int64(9)),
                SQLValue.real(9.9),
                SQLValue.real(Double.pi),
                SQLValue.text(""),
                SQLValue.text("ABCXYZ123"),
                //SQLValue.blob(Data()),
                SQLValue.blob(Data([UInt8(0x01), UInt8(0x02)])),
            ] {
                XCTAssertEqual(value, try sqlite.query(sql: "SELECT ?", parameters: [value]).first?.first)
            }
        }

        do {
            let squery = try sqlite.prepare(sql: "SELECT TXT FROM DEMO_TABLE")
            XCTAssertTrue(try squery.next())
            XCTAssertEqual("ABC", squery.text(at: 0))
            XCTAssertTrue(try squery.next())
            XCTAssertEqual("XYZ", squery.text(at: 0))
            try squery.close()
        }

        do {
            let strquery = try sqlite.prepare(sql: "SELECT COUNT(*) FROM DEMO_TABLE WHERE TXT = ?")

            try strquery.bind(parameters: [.text("XYZ")])
            XCTAssertEqual(SQLValue.long(1), try strquery.nextValues(close: false)?.first)

            strquery.reset()
            try strquery.bind(parameters: [.text("QRS")])
            XCTAssertEqual(SQLValue.long(0), try strquery.nextValues(close: false)?.first)

            strquery.reset()
            try strquery.bind(parameters: [.text("ABC")])
            XCTAssertEqual(SQLValue.long(1), try strquery.nextValues(close: false)?.first)

            try strquery.close()
        }

        do {
            let blbquery = try sqlite.prepare(sql: "SELECT COUNT(*) FROM DEMO_TABLE WHERE BLB = ?")

            try blbquery.bind(.blob(Data()), at: 1)
            XCTAssertEqual(SQLValue.long(1), try blbquery.nextValues(close: false)?.first)

            blbquery.reset()
            try blbquery.bind(.blob(Data([UInt8(0x78), UInt8(0x79), UInt8(0x7A)])), at: 1)
            XCTAssertEqual(SQLValue.long(1), try blbquery.nextValues(close: false)?.first)

            blbquery.reset()
            // bind a 1mb param
            try blbquery.bind(.blob(Data(Array(repeating: UInt8(0x78), count: 1024 * 1024))), at: 1)
            XCTAssertEqual(SQLValue.long(0), try blbquery.nextValues(close: false)?.first)

            try blbquery.close()
        }

        // XCTAssertEqual(1, try sqlite.exec(sql: "DELETE FROM DEMO_TABLE LIMIT 1")) // Android fail: SQLiteLog: (1) near "LIMIT": syntax error in "DELETE FROM DEMO_TABLE LIMIT 1"
        // XCTAssertEqual(.long(1), try count(table: "DEMO_TABLE"))

        try sqlite.exec(sql: "DELETE FROM DEMO_TABLE")
        XCTAssertEqual(SQLValue.long(0), try count(table: "DEMO_TABLE"))

        try sqlite.exec(sql: "DROP TABLE DEMO_TABLE")

        try sqlite.close() // make sure statements are closed or: "unable to close due to unfinalized statements or unfinished backups"

        XCTAssertEqual(3, updates)
    }

    func testSQLiteNamedParameters() throws {
        let ctx = SQLContext(configuration: .test)

        do {
            let stmnt = try ctx.prepare(sql: "SELECT 1")
            XCTAssertEqual("SELECT 1", stmnt.sql)

            XCTAssertEqual(0, stmnt.parameterCount)
            try stmnt.close()
        }

        do {
            // implicit positional parameter
            let stmnt = try ctx.prepare(sql: "SELECT ?")
            XCTAssertEqual(1, stmnt.parameterCount)
            try stmnt.close()
        }

        do {
            // explicit positional parameter
            let stmnt = try ctx.prepare(sql: "SELECT ?1")
            XCTAssertEqual(1, stmnt.parameterCount)
            try stmnt.close()
        }

        do {
            // named parameter
            let stmnt = try ctx.prepare(sql: "SELECT :q")
            XCTAssertEqual(1, stmnt.parameterCount)
            try stmnt.close()
        }

        do {
            // mixed named and positional parameter syntax: https://www.sqlite.org/lang_expr.html#parameters
            let stmnt = try ctx.prepare(sql: "SELECT 0, ?, ?2, :AAA, @AAA, $AAA, 'AAA'")
            XCTAssertEqual(5, stmnt.parameterCount)
            XCTAssertEqual([nil, "?2", ":AAA", "@AAA", "$AAA"], stmnt.parameterNames)
            try stmnt.close()
        }

        do {
            // out of order positional parameters
            XCTAssertEqual([SQLValue.text("ONE"), .text("TWO")], try ctx.query(sql: "SELECT ?2, ?1", parameters: [.text("TWO"), .text("ONE")]).first)
        }

        try ctx.close()
    }

    func testSQLiteInterrupt() async throws {
        let ctx = SQLContext(configuration: .test)

        let stmnt = try ctx.prepare(sql: """
            WITH RECURSIVE SlowQuery AS (
              SELECT 'a' AS val
              UNION ALL
              SELECT val || 'a' FROM SlowQuery WHERE length(val) < 1000000
            )
            SELECT length(val) FROM SlowQuery
            """)


        for _ in 1...1000 { // iterate through the first bunch of rows
            XCTAssertTrue(try stmnt.next())
            XCTAssertNotEqual(0, stmnt.long(at: 0))
        }

        for _ in 1...5 { // try a few rounds of statement cancellation
            Task.detached { // cancel the query after 500ms
                try await Task.sleep(nanoseconds: 500 * 1_000_000)
                ctx.interrupt()
            }

            do {
                while try stmnt.next() {
                    XCTAssertNotEqual(0, stmnt.long(at: 0))
                }
                XCTFail("should have been interrupted before iterating over all the rows")
            } catch let e as SQLError {
                XCTAssertEqual(9, e.code)
                XCTAssertEqual("interrupted", e.msg)
            }

            stmnt.reset() // need to reset before trying the statement again
        }

        try stmnt.close()
        try ctx.close()
    }

    func testSQLitePerformance() throws {
        let dir = URL.temporaryDirectory
        let dbpath = dir.appendingPathComponent("testSQLitePerformance-\(UUID().uuidString).db").path
        let sqlite = try SQLContext(path: dbpath, flags: [.create, .readWrite], configuration: .test)

        try sqlite.exec(sql: "CREATE TABLE BIGTABLE (STRING TEXT)")

        let startTime = Date.now
        logger.log("writing to db: \(dbpath)")
        let rows = 1_000_000
        let insert = try sqlite.prepare(sql: "INSERT INTO BIGTABLE VALUES (?)")
        try sqlite.transaction {
            for _ in 1...rows {
                try insert.update(parameters: [.text(UUID().uuidString)])
            }
        }
        try insert.close()
        let t = Date.now.timeIntervalSince(startTime)
        logger.log("wrote \(rows) rows to db in \(t): \(dbpath)")
        try sqlite.close()
    }

    func testSQLCodable() throws {
        let sqlite = SQLContext(configuration: .test)
        var statements: [String] = []
        sqlite.trace { sql in
            self.logger.info("SQL: \(sql)")
            statements.append(sql)
        }

        let blob = "XYZ".data(using: .utf8)
        XCTAssertEqual("x'58595a'", SQLValue(blob).literalValue)

        func count(distinct: Bool = false, columns: String = "*", table: String) throws -> SQLValue? {
            try sqlite.prepare(sql: "SELECT COUNT(\(distinct ? "DISTINCT" : "") \(columns)) FROM \"\(table)\"").nextValues(close: true)?.first
        }

        try sqlite.exec(DemoTable.createSQL())
        var ob = DemoTable(txt: "ABC", num: 12.3, int: 456, dbl: 7.89, blb: blob)
        try sqlite.inserted(&ob)
        XCTAssertEqual(1, ob.id, "primary key should have been assigned")
        let initialInstance = ob

        XCTAssertEqual(SQLValue.long(1), try count(table: "DEMO_TABLE"))
        try XCTAssertNotNil(sqlite.fetch(DemoTable.self, id: SQLValue(1)))
        try XCTAssertNil(sqlite.fetch(DemoTable.self, id: SQLValue(9999)))

        ob.id = nil // need to manually clear the ID so it doesn't attempt to set it in the instance
        do {
            try sqlite.inserted(&ob)
            XCTFail("insert duplicate TXT column should have failed")
        } catch let error as SQLError {
            // expected
            XCTAssertEqual("UNIQUE constraint failed: DEMO_TABLE.TXT", error.msg)
        }

        ob.txt = "DEF"
        ob.dbl = nil
        try sqlite.inserted(&ob, refresh: true)
        XCTAssertEqual(2, ob.id, "primary key should have been assigned")
        XCTAssertEqual(Double.pi, ob.dbl, "default value should have been assigned")

        XCTAssertEqual(SQLValue.long(2), try count(table: "DEMO_TABLE"))

        // now manually set the ID to ensure that it is used

        ob.txt = "HIJ"
        ob.id = 6
        try sqlite.inserted(&ob)
        XCTAssertEqual(6, ob.id, "manual primary key specification should have been used")

        ob.txt = "KLM"
        ob.id = nil // auto-assign the next row
        try sqlite.inserted(&ob)
        XCTAssertEqual(7, ob.id)

        ob.txt = "NMO"
        ob.num = nil
        ob.id = 4
        try sqlite.insert(ob, upsert: false)

        ob.txt = "ZZZ"
        do {
            try sqlite.insert(ob, upsert: false)
            XCTFail("insert duplicate PK should have failed")
        } catch let error as SQLError {
            // expected
            XCTAssertEqual("UNIQUE constraint failed: DEMO_TABLE.ID", error.msg)
        }

        // try again as an upsert
        try sqlite.insert(ob, upsert: true)

        XCTAssertEqual(SQLValue.long(5), try count(table: "DEMO_TABLE"))

        do {
            let cursor = try sqlite.cursor(DemoTable.selectSQL())

            // if we don't close the cursor before dropping the table, results in the error in Kotlin (GC'd):
            // SQLite error code 6: database table is locked
            defer { cursor.close() }

            let bindings = try DemoTable.columns.map({ try initialInstance.binding(forColumn: $0) })
            let rowValues = try cursor.makeIterator().next()?.get()
            XCTAssertEqual(bindings, rowValues)
        }

        // now try a cursored read of database instances
        do {
            //let cursor = try DemoTable.select(context: sqlite)
            let cursor = try sqlite.select(DemoTable.self)

            // if we don't close the cursor before dropping the table, results in the error in Kotlin (GC'd):
            // SQLite error code 6: database table is locked
            defer { cursor.close() }

            XCTAssertEqual(initialInstance, try? cursor.makeIterator().next()?.get())
        }

        // inserting autoincrement primary key
        try sqlite.insert(DemoTable(txt: "", int: 999))

        do {
            let idRanges = try sqlite.query(sql: "SELECT GROUP_CONCAT(ROWID, ',') AS ids FROM DEMO_TABLE")
            XCTAssertEqual("8,1,2,6,7,4", idRanges.first?.first?.textValue)
        }

        func check(count expectedCount: Int, _ predicate: SQLPredicate, alias: String? = nil, sql: String? = nil) throws {
            let resultSet = try sqlite.query(DemoTable.self, alias: alias, with: [predicate])
            defer { resultSet.close() }
            var count = 0
            let cursor = resultSet.makeIterator()
            while let row = cursor.next() {
                let instance = try row.get() // instantiate the type from the row
                count += 1
                let _ = instance
                //logger.log("got instance: \(instance.id ?? 0)")
            }
            XCTAssertEqual(expectedCount, count)
            if let sql {
                XCTAssertEqual(sql, statements.last)
            }
        }

        try check(count: 1, .equals(DemoTable.txt, SQLValue("ABC")),
                  sql: #"SELECT "ID", "TXT", "NUM", "INT", "DBL", "BLB" FROM "DEMO_TABLE" WHERE "TXT" = 'ABC'"#)
        try check(count: 1, .equals(DemoTable.txt.alias("t0"), SQLValue("ABC")), alias: "t0",
                  sql: #"SELECT t0."ID", t0."TXT", t0."NUM", t0."INT", t0."DBL", t0."BLB" FROM "DEMO_TABLE" t0 WHERE t0."TXT" = 'ABC'"#)

        try check(count: 5, .notEquals(DemoTable.txt, SQLValue("ABC")),
                  sql: #"SELECT "ID", "TXT", "NUM", "INT", "DBL", "BLB" FROM "DEMO_TABLE" WHERE "TXT" <> 'ABC'"#)
        try check(count: 5, .not(.equals(DemoTable.txt, SQLValue("ABC"))),
                  sql: #"SELECT "ID", "TXT", "NUM", "INT", "DBL", "BLB" FROM "DEMO_TABLE" WHERE NOT ("TXT" = 'ABC')"#)

        try check(count: 2, .isNull(DemoTable.num),
                  sql: #"SELECT "ID", "TXT", "NUM", "INT", "DBL", "BLB" FROM "DEMO_TABLE" WHERE "NUM" IS NULL"#)
        try check(count: 4, .isNotNull(DemoTable.num),
                  sql: #"SELECT "ID", "TXT", "NUM", "INT", "DBL", "BLB" FROM "DEMO_TABLE" WHERE "NUM" IS NOT NULL"#)
        try check(count: 4, .not(.isNull(DemoTable.num)),
                  sql: #"SELECT "ID", "TXT", "NUM", "INT", "DBL", "BLB" FROM "DEMO_TABLE" WHERE NOT ("NUM" IS NULL)"#)
        try check(count: 2, .not(.isNotNull(DemoTable.num)),
                  sql: #"SELECT "ID", "TXT", "NUM", "INT", "DBL", "BLB" FROM "DEMO_TABLE" WHERE NOT ("NUM" IS NOT NULL)"#)
        try check(count: 2, .equals(DemoTable.num, SQLValue.null),
                  sql: #"SELECT "ID", "TXT", "NUM", "INT", "DBL", "BLB" FROM "DEMO_TABLE" WHERE "NUM" IS NULL"#)
        try check(count: 4, .notEquals(DemoTable.num, SQLValue.null),
                  sql: #"SELECT "ID", "TXT", "NUM", "INT", "DBL", "BLB" FROM "DEMO_TABLE" WHERE "NUM" IS NOT NULL"#)

        try check(count: 3, .in(DemoTable.txt, [SQLValue("ABC"), SQLValue("DEF"), SQLValue("HIJ"), SQLValue("NONE")]),
                  sql: #"SELECT "ID", "TXT", "NUM", "INT", "DBL", "BLB" FROM "DEMO_TABLE" WHERE "TXT" IN ('ABC', 'DEF', 'HIJ', 'NONE')"#)
        try check(count: 6, .equals(DemoTable.txt, DemoTable.txt),
                  sql: #"SELECT "ID", "TXT", "NUM", "INT", "DBL", "BLB" FROM "DEMO_TABLE" WHERE "TXT" = "TXT""#)

        try check(count: 6, .equals(SQLValue("ABC"), SQLValue("ABC")),
                  sql: #"SELECT "ID", "TXT", "NUM", "INT", "DBL", "BLB" FROM "DEMO_TABLE" WHERE 'ABC' = 'ABC'"#)

        try check(count: 6, .equals(SQLValue.null, SQLValue.null),
                  sql: #"SELECT "ID", "TXT", "NUM", "INT", "DBL", "BLB" FROM "DEMO_TABLE" WHERE NULL IS NULL"#)
        try check(count: 0, .notEquals(SQLValue.null, SQLValue.null),
                  sql: #"SELECT "ID", "TXT", "NUM", "INT", "DBL", "BLB" FROM "DEMO_TABLE" WHERE NULL IS NOT NULL"#)

        try check(count: 4, .lessThan(DemoTable.dbl, DemoTable.num),
                  sql: #"SELECT "ID", "TXT", "NUM", "INT", "DBL", "BLB" FROM "DEMO_TABLE" WHERE "DBL" < "NUM""#)
        try check(count: 4, .not(.lessThan(DemoTable.num, DemoTable.dbl)),
                  sql: #"SELECT "ID", "TXT", "NUM", "INT", "DBL", "BLB" FROM "DEMO_TABLE" WHERE NOT ("NUM" < "DBL")"#)
        try check(count: 4, .greaterThan(DemoTable.num, DemoTable.dbl),
                  sql: #"SELECT "ID", "TXT", "NUM", "INT", "DBL", "BLB" FROM "DEMO_TABLE" WHERE "NUM" > "DBL""#)

        try check(count: 3, .or([.isNull(DemoTable.num), .equals(DemoTable.txt, SQLValue("ABC"))]),
                  sql: #"SELECT "ID", "TXT", "NUM", "INT", "DBL", "BLB" FROM "DEMO_TABLE" WHERE ("NUM" IS NULL OR "TXT" = 'ABC')"#)
        try check(count: 3, DemoTable.num.isNull().or(DemoTable.txt.equals(SQLValue("ABC"))),
                  sql: #"SELECT "ID", "TXT", "NUM", "INT", "DBL", "BLB" FROM "DEMO_TABLE" WHERE ("NUM" IS NULL OR "TXT" = 'ABC')"#)


        try check(count: 1, DemoTable.num.isNull().and(DemoTable.txt.greaterThanOrEqual(SQLValue("G"))),
                  sql: #"SELECT "ID", "TXT", "NUM", "INT", "DBL", "BLB" FROM "DEMO_TABLE" WHERE ("NUM" IS NULL AND "TXT" >= 'G')"#)

        try check(count: 5, .equals(DemoTable.blb, SQLValue(blob)),
                  sql: #"SELECT "ID", "TXT", "NUM", "INT", "DBL", "BLB" FROM "DEMO_TABLE" WHERE "BLB" = x'58595a'"#)
        try check(count: 5, .equals(DemoTable.dbl, SQLValue(Double.pi)),
                  sql: #"SELECT "ID", "TXT", "NUM", "INT", "DBL", "BLB" FROM "DEMO_TABLE" WHERE "DBL" = 3.14159265358979"#)

        try sqlite.exec(DemoTable.dropSQL())
    }
}

/// A struct that can read and write its values to the `DEMO_TABLE` table.
public struct DemoTable : SQLCodable, Equatable {
    public static var tableName = "DEMO_TABLE"

    /// All the columns defined for this table
    public static var columns: [SQLColumn] {
        [id, txt, num, int, dbl, blb]
    }

    public var id: Int64?
    static let id = SQLColumn(name: "ID", type: .long, primaryKey: true, autoincrement: true)

    public var txt: String?
    static let txt = SQLColumn(name: "TXT", type: .text, unique: true, nullable: false)

    public var num: Double?
    static let num = SQLColumn(name: "NUM", type: .real)

    public var int: Int
    static let int = SQLColumn(name: "INT", type: .long, nullable: false)

    public var dbl: Double?
    static let dbl = SQLColumn(name: "DBL", type: .real, defaultValue: SQLValue(Double.pi))

    public var blb: Data?
    static let blb = SQLColumn(name: "BLB", type: .blob)

    /// Returns a `SQLValue` for the specified `SQLColumn`
    public func binding(forColumn column: SQLColumn) throws -> SQLValue {
        switch column {
        case Self.id: return SQLValue(self.id)
        case Self.txt: return SQLValue(self.txt)
        case Self.num: return SQLValue(self.num)
        case Self.int: return SQLValue(self.int)
        case Self.dbl: return SQLValue(self.dbl)
        case Self.blb: return SQLValue(self.blb)
        default: throw SQLBindingError.unknownColumn(column)
        }
    }

    /// Updates the value of the given column with the given value
    public mutating func update(column: SQLColumn, value: SQLValue) throws {
        switch column {
        case Self.id: self.id = value.longValue
        case Self.txt: self.txt = value.textValue
        case Self.num: self.num = value.realValue
        case Self.int: self.int = .init(try SQLBindingError.checkNonNull(value.longValue, column))
        case Self.dbl: self.dbl = value.realValue
        case Self.blb: self.blb = value.blobValue
        default: throw SQLBindingError.unknownColumn(column)
        }
    }

    /// Create an instance of this type from the given row values
    public static func create(withRow row: [SQLValue], fromColumns: [SQLColumn]? = nil) throws -> Self {
        try DemoTable(withRow: row, fromColumns: fromColumns)
    }

    init(withRow row: [SQLValue], fromColumns: [SQLColumn]? = nil) throws {
        self.int = 0 // need to initialize any non-nil instances with placeholder values
        let columns = fromColumns ?? Self.columns
        if row.count != columns.count {
            throw SQLBindingError.columnValuesMismatch(row.count, columns.count)
        }
        for (value, column) in zip(row, columns) {
            try update(column: column, value: value)
        }
    }

    public init(id: Int64? = nil, txt: String? = nil, num: Double? = nil, int: Int, dbl: Double? = nil, blb: Data? = nil) {
        self.id = id
        self.txt = txt
        self.num = num
        self.int = int
        self.dbl = dbl
        self.blb = blb
    }
}
