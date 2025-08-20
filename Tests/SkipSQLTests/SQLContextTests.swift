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
            _ = try ctx.selectAll(sql: "SELECT ?", parameters: [.text("ABC")])
            XCTAssertEqual("SELECT 'ABC'", sql.last)
        }

        ctx.trace(nil)
        try ctx.close()
    }

    func testSQLiteVersion() throws {
        let sqlite = SQLContext(configuration: .test)
        sqlite.trace { sql in
            self.logger.info("SQL: \(sql)")
        }
        logger.info("connected to SQLite version: \(sqlite.versionNumber)")

        XCTAssertEqual(0, sqlite.userVersion)
        sqlite.userVersion += 1
        XCTAssertEqual(1, sqlite.userVersion)
    }

    func testSQLite() throws {
        let sqlite = SQLContext(configuration: .test)
        logger.info("connected to SQLite version: \(sqlite.versionNumber)")

        _ = try sqlite.selectAll(sql: "SELECT 1")
        _ = try sqlite.selectAll(sql: "SELECT CURRENT_TIMESTAMP")
        _ = try sqlite.selectAll(sql: "PRAGMA compile_options")

#if os(macOS)
        //XCTAssertEqual([SQLValue.text("3.43.2")], try sqlite.selectAll(sql: "SELECT sqlite_version()").first)
        XCTAssertEqual([SQLValue.text("ATOMIC_INTRINSICS=1")], try sqlite.selectAll(sql: "PRAGMA compile_options").first)
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
                XCTAssertEqual(value, try sqlite.selectAll(sql: "SELECT ?", parameters: [value]).first?.first)
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

    func testDateTypes() throws {
        let ctx = SQLContext(configuration: .test)
        var statements: [String] = []
        ctx.trace { sql in
            self.logger.info("SQL: \(sql)")
            statements.append(sql)
        }

        for ddl in SQLDateAsText.table.createTableSQL() + SQLDateAsReal.table.createTableSQL() {
            try ctx.exec(ddl)
        }

        let date = Date(timeIntervalSince1970: 1754550000.0)
        let ob1 = try ctx.insert(SQLDateAsText(date: date))
        let _ = ob1
        XCTAssertEqual(#"INSERT INTO "SQL_DATE_AS_TEXT" ("DATE") VALUES ('2025-08-07T07:00:00Z')"#, statements.last)

        let ob2 = try ctx.insert(SQLDateAsReal(date: date))
        let _ = ob2
        XCTAssertEqual(#"INSERT INTO "SQL_DATE_AS_REAL" ("DATE") VALUES (1754550000.0)"#, statements.last)

        // test date/time functions on each of the types
        // https://sqlite.org/lang_datefunc.html#overview
        for tableName in [SQLDateAsText.table.name, SQLDateAsReal.table.name] {
            func fmt(_ formatSpecifier: String) throws -> SQLValue {
                try ctx.selectAll(sql: "SELECT strftime('\(formatSpecifier)', DATE, 'auto') FROM \(tableName)").first?.first ?? .null
            }
            // FIXME: some of these fail on the Android emulator for a non-SkipSQLPlus vendored builds
            if !ctx.isSQLPlus {
                throw XCTSkip("some date/time functions fail with vendored SQLite")
            }

            try XCTAssertEqual(SQLValue("07"), fmt("%d")) // day of month: 01-31
            try XCTAssertEqual(SQLValue(" 7"), fmt("%e")) // day of month without leading zero: 1-31
            try XCTAssertEqual(SQLValue("00.000"), fmt("%f")) // fractional seconds: SS.SSS
            try XCTAssertEqual(SQLValue("2025-08-07"), fmt("%F")) // ISO 8601 date: YYYY-MM-DD
            try XCTAssertEqual(SQLValue("2025"), fmt("%G")) // ISO 8601 year corresponding to %V
            try XCTAssertEqual(SQLValue("25"), fmt("%g")) // 2-digit ISO 8601 year corresponding to %V
            try XCTAssertEqual(SQLValue("07"), fmt("%H")) // hour: 00-24
            try XCTAssertEqual(SQLValue("07"), fmt("%I")) // hour for 12-hour clock: 01-12
            try XCTAssertEqual(SQLValue("219"), fmt("%j")) // day of year: 001-366
            try XCTAssertEqual(SQLValue("2460894.791666667"), fmt("%J")) // Julian day number (fractional)
            try XCTAssertEqual(SQLValue(" 7"), fmt("%k")) // hour without leading zero: 0-24
            try XCTAssertEqual(SQLValue(" 7"), fmt("%l")) // %I without leading zero: 1-12
            try XCTAssertEqual(SQLValue("08"), fmt("%m")) // month: 01-12
            try XCTAssertEqual(SQLValue("00"), fmt("%M")) // minute: 00-59
            try XCTAssertEqual(SQLValue("AM"), fmt("%p")) // "AM" or "PM" depending on the hour
            try XCTAssertEqual(SQLValue("am"), fmt("%P")) // "am" or "pm" depending on the hour
            try XCTAssertEqual(SQLValue("07:00"), fmt("%R")) // ISO 8601 time: HH:MM
            try XCTAssertEqual(SQLValue("1754550000"), fmt("%s")) // seconds since 1970-01-01
            try XCTAssertEqual(SQLValue("00"), fmt("%S")) // seconds: 00-59
            try XCTAssertEqual(SQLValue("07:00:00"), fmt("%T")) // ISO 8601 time: HH:MM:SS
            try XCTAssertEqual(SQLValue("31"), fmt("%U")) // week of year (00-53) - week 01 starts on the first Sunday
            try XCTAssertEqual(SQLValue("4"), fmt("%u")) // day of week 1-7 with Monday==1
            try XCTAssertEqual(SQLValue("32"), fmt("%V")) // ISO 8601 week of year
            try XCTAssertEqual(SQLValue("4"), fmt("%w")) // day of week 0-6 with Sunday==0
            try XCTAssertEqual(SQLValue("31"), fmt("%W")) // week of year (00-53) - week 01 starts on the first Monday
            try XCTAssertEqual(SQLValue("2025"), fmt("%Y")) // year: 0000-9999
        }
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
            XCTAssertEqual([SQLValue.text("ONE"), .text("TWO")], try ctx.selectAll(sql: "SELECT ?2, ?1", parameters: [.text("TWO"), .text("ONE")]).first)
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

        XCTAssertEqual("UTF-8", sqlite.encoding)

        XCTAssertFalse(sqlite.foreignKeysEnabled)
        sqlite.foreignKeysEnabled = true
        XCTAssertTrue(sqlite.foreignKeysEnabled)

        var blob = "XYZ".data(using: .utf8)
        XCTAssertEqual("x'58595a'", SQLValue(blob).literalValue)

        func check(count expectedCount: Int, _ predicate: SQLPredicate? = nil, alias: String? = nil, sql: String? = nil) throws {
            let resultSet = try sqlite.query(DemoTable.self, alias: alias).where(predicate).eval()
            defer { resultSet.close() }
            let instances = try resultSet.load()
            XCTAssertEqual(expectedCount, instances.count)
            if let sql {
                XCTAssertEqual(sql, statements.last)
            }
        }

        func checkJoin(count expectedCount: Int, _ predicate: SQLPredicate? = nil, alias: String? = nil, sql: String? = nil) throws {
            let resultSet = try sqlite.query(DemoJoinTable.self, alias: alias).where(predicate).eval()
            defer { resultSet.close() }
            let instances = try resultSet.load()
            XCTAssertEqual(expectedCount, instances.count)
            if let sql {
                XCTAssertEqual(sql, statements.last)
            }
        }

        func count(distinct: Bool = false, columns: String = "*", table: String) throws -> SQLValue? {
            try sqlite.prepare(sql: "SELECT COUNT(\(distinct ? "DISTINCT" : "") \(columns)) FROM \"\(table)\"").nextValues(close: true)?.first
        }

        for ddl in DemoTable.table.createTableSQL(withIndexes: false) {
            try sqlite.exec(ddl)
        }
        let createDemoTableSQL = #"CREATE TABLE "DEMO_TABLE" ("ID" INTEGER PRIMARY KEY, "TXT" TEXT UNIQUE NOT NULL, "NUM" REAL, "INT" INTEGER NOT NULL, "DBL" REAL DEFAULT 3.141592653589793, "BLB" BLOB)"#
        XCTAssertEqual(createDemoTableSQL, statements.last)

        try check(count: 0)

        do {
            let tables = try sqlite.tables()
            XCTAssertEqual(1, tables.count)
            XCTAssertEqual(tables.dropFirst(0).first, TableInfo(type: "table", name: DemoTable.table.name, tbl_name: DemoTable.table.name, rootpage: 2, sql: createDemoTableSQL))
            // XCTAssertEqual(tables.dropFirst(1).first, TableInfo(type: "index", name: "sqlite_autoindex_DEMO_TABLE_1", tbl_name: DemoTable.table.name, rootpage: 3, sql: nil)) // if we didn't filter on tables…
            // XCTAssertEqual(tables.dropFirst(2).first, TableInfo(type: "table", name: "sqlite_sequence", tbl_name: "sqlite_sequence", rootpage: 4, sql: "CREATE TABLE sqlite_sequence(name,seq)")) // if the primary key were autoincrement this sequence table would have been added

            let columns = try sqlite.columns(for: DemoTable.table.name)
            XCTAssertEqual(6, columns.count)
            XCTAssertEqual(columns.dropFirst(0).first, ColumnInfo(cid: 0, name: "ID", type: "INTEGER", notnull: 0, dflt_value: .null, pk: 1))
            XCTAssertEqual(columns.dropFirst(1).first, ColumnInfo(cid: 1, name: "TXT", type: "TEXT", notnull: 1, dflt_value: .null, pk: 0))
            XCTAssertEqual(columns.dropFirst(2).first, ColumnInfo(cid: 2, name: "NUM", type: "REAL", notnull: 0, dflt_value: .null, pk: 0))
            XCTAssertEqual(columns.dropFirst(3).first, ColumnInfo(cid: 3, name: "INT", type: "INTEGER", notnull: 1, dflt_value: .null, pk: 0))
            XCTAssertEqual(columns.dropFirst(4).first, ColumnInfo(cid: 4, name: "DBL", type: "REAL", notnull: 0, dflt_value: .text("3.141592653589793"), pk: 0)) // FIXME: dflt_value should probably be a .real, but would require us to use sqlite3_column_value
            XCTAssertEqual(columns.dropFirst(5).first, ColumnInfo(cid: 5, name: "BLB", type: "BLOB", notnull: 0, dflt_value: .null, pk: 0))
        }

        var ob = DemoTable(txt: "ABC", num: 12.3, int: 456, dbl: 7.89, blb: blob)
        try sqlite.inserted(&ob)
        XCTAssertEqual(#"INSERT INTO "DEMO_TABLE" ("TXT", "NUM", "INT", "DBL", "BLB") VALUES ('ABC', 12.3, 456, 7.89, x'58595a')"#, statements.last)
        XCTAssertEqual(1, sqlite.changes, "insert should report a change")

        ob.int *= 2
        ob.num = ob.num! * 2.0
        blob = "1234567890".data(using: .utf8)
        ob.blb = blob
        try sqlite.update(ob)
        XCTAssertEqual(#"UPDATE "DEMO_TABLE" SET "TXT" = 'ABC', "NUM" = 24.6, "INT" = 912, "DBL" = 7.89, "BLB" = x'31323334353637383930' WHERE "ID" = 1"#, statements.last)
        XCTAssertEqual(1, sqlite.changes, "update with changed fields should report a change")

        let ob1 = ob
        XCTAssertEqual(1, ob.id, "primary key should have been assigned")
        let initialInstance = ob

        try check(count: 1)

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
        let ob2 = ob
        XCTAssertEqual(2, ob.id, "primary key should have been assigned")
        XCTAssertEqual(Double.pi, ob.dbl, "default value should have been assigned")

        XCTAssertEqual(SQLValue.long(2), try count(table: "DEMO_TABLE"))

        // now manually set the ID to ensure that it is used

        ob.txt = "HIJ"
        ob.id = 6
        try sqlite.inserted(&ob)
        let ob6 = ob
        XCTAssertEqual(6, ob.id, "manual primary key specification should have been used")

        ob.txt = "KLM"
        ob.id = nil // auto-assign the next row
        try sqlite.inserted(&ob)
        let ob7 = ob
        let _ = ob7
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
        let ob4 = ob

        XCTAssertEqual(SQLValue.long(5), try count(table: "DEMO_TABLE"))

        do {
            let cursor = try sqlite.cursor(DemoTable.selectSQL())

            // if we don't close the cursor before dropping the table, results in the error in Kotlin (GC'd):
            // SQLite error code 6: database table is locked
            defer { cursor.close() }

            let initialRow = try initialInstance.encodedRow()
            let bindings = DemoTable.table.columns.map({ initialRow[$0] ?? .null })
            let rowValues = try cursor.makeIterator().next()?.get()
            XCTAssertEqual(bindings, rowValues)
        }

        // now try a cursored read of database instances
        do {
            let cursor = try sqlite.query(DemoTable.self).eval()

            // if we don't close the cursor before dropping the table, results in the error in Kotlin (GC'd):
            // SQLite error code 6: database table is locked
            defer { cursor.close() }

            XCTAssertEqual(initialInstance, try? cursor.makeIterator().next()?.get())
        }

        // inserting autoincrement primary key
        var ob8 = DemoTable(txt: "", int: 999)
        try sqlite.inserted(&ob8, refresh: true)

        do {
            let idRanges = try sqlite.selectAll(sql: "SELECT GROUP_CONCAT(ROWID, ',') AS ids FROM DEMO_TABLE")
            XCTAssertEqual("8,1,2,6,7,4", idRanges.first?.first?.textValue)
        }

        do {
            // check limit/offset queries
            XCTAssertEqual(1, try sqlite.query(DemoTable.self).limit(1).eval().load().count)
            XCTAssertEqual(#"SELECT "ID", "TXT", "NUM", "INT", "DBL", "BLB" FROM "DEMO_TABLE" LIMIT 1"#, statements.last)
            XCTAssertEqual(2, try sqlite.query(DemoTable.self).limit(100, offset: 4).eval().load().count)
            XCTAssertEqual(#"SELECT "ID", "TXT", "NUM", "INT", "DBL", "BLB" FROM "DEMO_TABLE" LIMIT 100 OFFSET 4"#, statements.last)
        }

        try check(count: 1, .equals(DemoTable.txt, SQLValue("ABC")),
                  sql: #"SELECT "ID", "TXT", "NUM", "INT", "DBL", "BLB" FROM "DEMO_TABLE" WHERE "TXT" = 'ABC'"#)
        try check(count: 1, .equals(DemoTable.txt.alias("t0"), SQLValue("ABC")), alias: "t0",
                  sql: #"SELECT t0."ID", t0."TXT", t0."NUM", t0."INT", t0."DBL", t0."BLB" FROM "DEMO_TABLE" AS t0 WHERE t0."TXT" = 'ABC'"#)

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
                  sql: #"SELECT "ID", "TXT", "NUM", "INT", "DBL", "BLB" FROM "DEMO_TABLE" WHERE "BLB" = x'31323334353637383930'"#)
        try check(count: 5, .equals(DemoTable.dbl, SQLValue(Double.pi)),
                  sql: #"SELECT "ID", "TXT", "NUM", "INT", "DBL", "BLB" FROM "DEMO_TABLE" WHERE "DBL" = 3.14159265358979"#)

        for ddl in DemoRelation.table.createTableSQL(withIndexes: false) {
            try sqlite.exec(ddl)
        }
        XCTAssertEqual(#"CREATE TABLE "DEMO_RELATION" ("PK" INTEGER PRIMARY KEY AUTOINCREMENT, "FK" INTEGER, "INFO" TEXT UNIQUE NOT NULL, FOREIGN KEY ("FK") REFERENCES "DEMO_TABLE"("ID") ON DELETE SET NULL)"#, statements.last)

        for ddl in DemoJoinTable.table.createTableSQL(withIndexes: false) {
            try sqlite.exec(ddl)
        }
        XCTAssertEqual(#"CREATE TABLE "DEMO_JOIN_TABLE" ("ID1" INTEGER NOT NULL, "ID2" INTEGER NOT NULL, PRIMARY KEY ("ID1", "ID2"), FOREIGN KEY ("ID1") REFERENCES "DEMO_TABLE"("ID") ON DELETE CASCADE, FOREIGN KEY ("ID2") REFERENCES "DEMO_TABLE"("ID") ON DELETE CASCADE)"#, statements.last)

        try DemoTable.table.createIndexSQL().forEach {
            try sqlite.exec($0)
        }
        XCTAssertEqual(#"CREATE INDEX "IDX_DBL" ON "DEMO_TABLE"("DBL")"#, statements.last)

        let joinOb1 = try sqlite.insert(DemoJoinTable(id1: 1, id2: 1))
        let joinOb2 = try sqlite.insert(DemoJoinTable(id1: 2, id2: 4))
        let joinOb3 = try XCTUnwrap(ob4.addManyToManyRelation(instance: ob6, to: sqlite)) // same as: try sqlite.insert(DemoJoinTable(id1: 4, id2: 6))

        do {
            XCTAssertEqual(try ob1.manyToManyRelation(in: sqlite), [ob1])
            XCTAssertEqual(#"SELECT t0."ID", t0."TXT", t0."NUM", t0."INT", t0."DBL", t0."BLB", t1."ID1", t1."ID2", t2."ID", t2."TXT", t2."NUM", t2."INT", t2."DBL", t2."BLB" FROM "DEMO_TABLE" AS t0 INNER JOIN "DEMO_JOIN_TABLE" AS t1 ON t0."ID" = t1."ID1" INNER JOIN "DEMO_TABLE" AS t2 ON t2."ID" = t1."ID2" WHERE t0."ID" = 1"#, statements.last)
            XCTAssertEqual(try ob2.manyToManyRelation(in: sqlite), [ob4])
            XCTAssertEqual(try ob4.manyToManyRelation(in: sqlite), [ob6])
        }

        do { // a single query with where, order, and limit clauses
            let singleQuery = try sqlite.query(DemoTable.self, alias: "t0")
                .where(DemoTable.num.greaterThan(SQLValue(1)))
                .where(DemoTable.txt.notLike(SQLValue("x")))
                .orderBy(DemoTable.num)
                .limit(999)
                .eval()
            defer { singleQuery.close() }
            let singleQueryResults = try singleQuery.load()
            XCTAssertEqual(4, singleQueryResults.count)
            XCTAssertEqual(ob1, singleQueryResults.first)
            XCTAssertEqual(#"SELECT t0."ID", t0."TXT", t0."NUM", t0."INT", t0."DBL", t0."BLB" FROM "DEMO_TABLE" AS t0 WHERE ("NUM" > 1 AND "TXT" NOT LIKE 'x') ORDER BY "NUM" ASC LIMIT 999"#, statements.last)
        }

        do { // a single aliased query
            let singleQuery = try sqlite.query(DemoTable.self, alias: "t0").eval()
            defer { singleQuery.close() }
            let singleQueryResults = try singleQuery.load()
            XCTAssertEqual(6, singleQueryResults.count)
            XCTAssertEqual(ob1, singleQueryResults.first)
            XCTAssertEqual(#"SELECT t0."ID", t0."TXT", t0."NUM", t0."INT", t0."DBL", t0."BLB" FROM "DEMO_TABLE" AS t0"#, statements.last)
        }

        do { // a cross join
            let crossJoin = try sqlite.query(DemoTable.self, alias: "t0")
                .join(DemoJoinTable.self, alias: "t1", kind: .cross, on: nil)
                .eval()
            defer { crossJoin.close() }
            let crossJoinResults = try crossJoin.load()
            XCTAssertEqual(6 * 3, crossJoinResults.count)
            XCTAssertEqual(ob1, crossJoinResults.first?.0)
            XCTAssertEqual(joinOb1, crossJoinResults.first?.1)
            XCTAssertEqual(#"SELECT t0."ID", t0."TXT", t0."NUM", t0."INT", t0."DBL", t0."BLB", t1."ID1", t1."ID2" FROM "DEMO_TABLE" AS t0 CROSS JOIN "DEMO_JOIN_TABLE" AS t1"#, statements.last)
        }

        do { // a two-way inner join
            let joined2 = try sqlite.query(DemoTable.self, alias: "t0")
                .join(DemoJoinTable.self, alias: "t1", kind: .inner, on: DemoJoinTable.id1)
                .orderBy(DemoTable.id.alias("t0"), order: .descending)
                .orderBy(DemoTable.txt.alias("t0"), order: .ascending)
                .eval()
            defer { joined2.close() }
            let joined2Results = try joined2.load()
            XCTAssertEqual(3, joined2Results.count)
            XCTAssertEqual(ob1, joined2Results.last?.0)
            XCTAssertEqual(joinOb1, joined2Results.last?.1)
            XCTAssertEqual(#"SELECT t0."ID", t0."TXT", t0."NUM", t0."INT", t0."DBL", t0."BLB", t1."ID1", t1."ID2" FROM "DEMO_TABLE" AS t0 INNER JOIN "DEMO_JOIN_TABLE" AS t1 ON t0."ID" = t1."ID1" ORDER BY t0."ID" DESC, t0."TXT" ASC"#, statements.last)
        }

        do { // a two-way inner join with a condition
            let joined2 = try sqlite.query(DemoTable.self, alias: "t0")
                .join(DemoJoinTable.self, alias: "t1", kind: .inner, on: DemoJoinTable.id1)
                .orderBy(DemoTable.int.alias("t0"))
                .where(DemoTable.txt.alias("t0").equals(SQLValue("ABC")))
                .orderBy(DemoTable.txt.alias("t0"), order: .descending)
                .eval()

            defer { joined2.close() }
            let joined2Results = try joined2.load()
            XCTAssertEqual(1, joined2Results.count)
            XCTAssertEqual(ob1, joined2Results.first?.0)
            XCTAssertEqual(joinOb1, joined2Results.first?.1)
            XCTAssertEqual(#"SELECT t0."ID", t0."TXT", t0."NUM", t0."INT", t0."DBL", t0."BLB", t1."ID1", t1."ID2" FROM "DEMO_TABLE" AS t0 INNER JOIN "DEMO_JOIN_TABLE" AS t1 ON t0."ID" = t1."ID1" WHERE t0."TXT" = 'ABC' ORDER BY t0."INT" ASC, t0."TXT" DESC"#, statements.last)
        }

        do { // a two-way inner join without aliases
            let joined2 = try sqlite.query(DemoTable.self)
                .join(DemoJoinTable.self, kind: .inner, on: DemoJoinTable.id1)
                .where(DemoTable.txt.equals(SQLValue("ABC")))
                .eval()
            defer { joined2.close() }
            let joined2Results = try joined2.load()
            XCTAssertEqual(1, joined2Results.count)
            XCTAssertEqual(ob1, joined2Results.first?.0)
            XCTAssertEqual(joinOb1, joined2Results.first?.1)
            XCTAssertEqual(#"SELECT "ID", "TXT", "NUM", "INT", "DBL", "BLB", "ID1", "ID2" FROM "DEMO_TABLE" INNER JOIN "DEMO_JOIN_TABLE" ON "DEMO_TABLE"."ID" = "DEMO_JOIN_TABLE"."ID1" WHERE "TXT" = 'ABC'"#, statements.last)
        }

        do { // a two-way inner join without aliases (to the other foreign key)
            let joined2 = try sqlite.query(DemoTable.self)
                .join(DemoJoinTable.self, kind: .inner, on: DemoJoinTable.id2)
                .eval()
            defer { joined2.close() }
            let joined2Results = try joined2.load()
            XCTAssertEqual(3, joined2Results.count)
            XCTAssertEqual(ob1, joined2Results.first?.0)
            XCTAssertEqual(joinOb1, joined2Results.first?.1)
            XCTAssertEqual(#"SELECT "ID", "TXT", "NUM", "INT", "DBL", "BLB", "ID1", "ID2" FROM "DEMO_TABLE" INNER JOIN "DEMO_JOIN_TABLE" ON "DEMO_TABLE"."ID" = "DEMO_JOIN_TABLE"."ID2""#, statements.last)
        }

        if sqlite.supports(feature: .rightJoin) { // a three-way RIGHT/LEFT join
            let rightLeftJoined = try sqlite.query(DemoTable.self, alias: "t0")
                .join(DemoJoinTable.self, alias: "t1", kind: .right, on: DemoJoinTable.id1)
                .join(DemoTable.self, alias: "t2", kind: .left, on: DemoJoinTable.id2)
                .eval()
            defer { rightLeftJoined.close() }
            let rightLeftJoinedResults = try rightLeftJoined.load()
            XCTAssertEqual(3, rightLeftJoinedResults.count)
            XCTAssertEqual(ob1, rightLeftJoinedResults.first?.0)
            XCTAssertEqual(joinOb1, rightLeftJoinedResults.first?.1)
            XCTAssertEqual(joinOb2, rightLeftJoinedResults.dropLast().last?.1)
            XCTAssertEqual(joinOb3, rightLeftJoinedResults.last?.1)
            XCTAssertEqual(ob1, rightLeftJoinedResults.first?.2)

            XCTAssertEqual(#"SELECT t0."ID", t0."TXT", t0."NUM", t0."INT", t0."DBL", t0."BLB", t1."ID1", t1."ID2", t2."ID", t2."TXT", t2."NUM", t2."INT", t2."DBL", t2."BLB" FROM "DEMO_TABLE" AS t0 RIGHT OUTER JOIN "DEMO_JOIN_TABLE" AS t1 ON t0."ID" = t1."ID1" LEFT OUTER JOIN "DEMO_TABLE" AS t2 ON t2."ID" = t1."ID2""#, statements.last)
        }

        if sqlite.supports(feature: .rightJoin) { // a three-way LEFT/RIGHT join (where some items will be expected to be nil)
            let leftRightJoined = try sqlite.query(DemoTable.self, alias: "t0")
                .join(DemoJoinTable.self, alias: "t1", kind: .left, on: DemoJoinTable.id1)
                .join(DemoTable.self, alias: "t2", kind: .right, on: DemoJoinTable.id2)
                .where(DemoTable.int.alias("t2").isNotNull())
                .eval()
            defer { leftRightJoined.close() }
            let leftRightJoinedResults = try leftRightJoined.load()
            XCTAssertEqual(6, leftRightJoinedResults.count)
            XCTAssertEqual(ob1, leftRightJoinedResults.first?.0)
            XCTAssertEqual(joinOb1, leftRightJoinedResults.first?.1)
            XCTAssertEqual(ob1, leftRightJoinedResults.first?.2)

            XCTAssertEqual(nil, leftRightJoinedResults.last?.0)
            XCTAssertEqual(nil, leftRightJoinedResults.last?.1)
            XCTAssertEqual(ob8, leftRightJoinedResults.last?.2)
            XCTAssertEqual(#"SELECT t0."ID", t0."TXT", t0."NUM", t0."INT", t0."DBL", t0."BLB", t1."ID1", t1."ID2", t2."ID", t2."TXT", t2."NUM", t2."INT", t2."DBL", t2."BLB" FROM "DEMO_TABLE" AS t0 LEFT OUTER JOIN "DEMO_JOIN_TABLE" AS t1 ON t0."ID" = t1."ID1" RIGHT OUTER JOIN "DEMO_TABLE" AS t2 ON t2."ID" = t1."ID2" WHERE t2."INT" IS NOT NULL"#, statements.last)
        }

        if sqlite.supports(feature: .fullOuterJoin) { // a three-way full outer join
            let leftRightJoined = try sqlite.query(DemoTable.self, alias: "t0")
                .join(DemoJoinTable.self, alias: "t1", kind: .full, on: DemoJoinTable.id1)
                .join(DemoTable.self, alias: "t2", kind: .full, on: DemoJoinTable.id2)
                .eval()
            defer { leftRightJoined.close() }
            let leftRightJoinedResults = try leftRightJoined.load()
            XCTAssertEqual(9, leftRightJoinedResults.count)
            XCTAssertEqual(ob1, leftRightJoinedResults.first?.0)
            XCTAssertEqual(joinOb1, leftRightJoinedResults.first?.1)
            XCTAssertEqual(ob1, leftRightJoinedResults.first?.2)

            XCTAssertEqual(nil, leftRightJoinedResults.last?.0)
            XCTAssertEqual(nil, leftRightJoinedResults.last?.1)
            XCTAssertEqual(ob8, leftRightJoinedResults.last?.2)
            XCTAssertEqual(#"SELECT t0."ID", t0."TXT", t0."NUM", t0."INT", t0."DBL", t0."BLB", t1."ID1", t1."ID2", t2."ID", t2."TXT", t2."NUM", t2."INT", t2."DBL", t2."BLB" FROM "DEMO_TABLE" AS t0 FULL OUTER JOIN "DEMO_JOIN_TABLE" AS t1 ON t0."ID" = t1."ID1" FULL OUTER JOIN "DEMO_TABLE" AS t2 ON t2."ID" = t1."ID2""#, statements.last)
        }

        // 1-to-many relation
        var relOb = DemoRelation(fk: ob1.id, info: "XYZ")
        XCTAssertEqual(true, try relOb.isNewInstance)
        relOb = try sqlite.insert(relOb)
        XCTAssertEqual(false, try relOb.isNewInstance)
        XCTAssertEqual(Int64(1), relOb.pk)
        XCTAssertEqual([relOb], try ob1.oneToManyRelation(in: sqlite), "relation fetch should have returned relations")

        try check(count: 6)
        try checkJoin(count: 3)

        try sqlite.delete(instances: [ob1])

        XCTAssertEqual(ob1.id, relOb.fk)
        try sqlite.refresh(&relOb)
        XCTAssertEqual(nil, relOb.fk, "delete should have nulled the foreign key relation")

        try check(count: 5)
        try checkJoin(count: 2) // delete should have cascaded to join table

        try sqlite.delete(instances: [XCTUnwrap(sqlite.fetch(DemoTable.self, id: SQLValue(4)))])
        try checkJoin(count: 0) // ID 4 has 2 join rows which should have both cascaded

        try sqlite.delete(instances: [joinOb1, joinOb2, joinOb3]) // delete with compound primary key (already deleted, but we are just checking the SQL)
        if sqlite.supports(feature: .rowValueInSyntax) {
            XCTAssertEqual(#"DELETE FROM "DEMO_JOIN_TABLE" WHERE ("ID1", "ID2") IN ((1, 1), (2, 4), (4, 6))"#, statements.last)
        } else {
            XCTAssertEqual(#"DELETE FROM "DEMO_JOIN_TABLE" WHERE (("ID1" = 1 AND "ID2" = 1) OR ("ID1" = 2 AND "ID2" = 4) OR ("ID1" = 4 AND "ID2" = 6))"#, statements.last)
        }
        XCTAssertEqual(0, sqlite.changes, "delete with no matching instances should not have reported changes")

        do {
            try sqlite.insert(joinOb1) // referenced tables do not exist
            XCTFail("insert join table with non-existant references should have failed")
        } catch let error as SQLError {
            // expected
            XCTAssertEqual("FOREIGN KEY constraint failed", error.msg)
        }

        try check(count: 4)

        let remaining = try sqlite.query(DemoTable.self).orderBy(DemoTable.id, order: .descending).orderBy(DemoTable.txt, order: .ascending).eval().load()
        XCTAssertEqual(#"SELECT "ID", "TXT", "NUM", "INT", "DBL", "BLB" FROM "DEMO_TABLE" ORDER BY "ID" DESC, "TXT" ASC"#, statements.last)

        try sqlite.delete(instances: remaining)
        XCTAssertEqual(#"DELETE FROM "DEMO_TABLE" WHERE "ID" IN (8, 7, 6, 2)"#, statements.last)
        XCTAssertEqual(4, sqlite.changes, "delete should have reported changes")

        try check(count: 0)

        try sqlite.exec(DemoJoinTable.table.dropTableSQL())
        try sqlite.exec(DemoTable.table.dropTableSQL())
    }

    func testMultipleSchemas() throws {
        let sqlite = SQLContext(configuration: .test)
        var statements: [String] = []
        sqlite.trace { sql in
            self.logger.info("SQL: \(sql)")
            statements.append(sql)
        }


        try (DemoTable.table.createTableSQL(withIndexes: true)).forEach {
            try sqlite.exec($0)
        }
        try sqlite.exec(sql: "attach database :memory as schema2")
        try (DemoTable.table.createTableSQL(inSchema: "schema2", withIndexes: true)).forEach {
            try sqlite.exec($0)
        }
        try sqlite.exec(sql: "attach database :memory as schema3")
        try (DemoTable.table.createTableSQL(inSchema: "schema3", withIndexes: true)).forEach {
            try sqlite.exec($0)
        }

        let ob1 = try sqlite.insert(DemoTable(txt: "unique", int: 1, dbl: 123.45))
        XCTAssertEqual(#"INSERT INTO "DEMO_TABLE" ("TXT", "INT", "DBL") VALUES ('unique', 1, 123.45)"#, statements.last)

        let ob2 = try sqlite.insert(DemoTable(txt: "unique", int: 1, dbl: 678.90), inSchema: "schema2")
        XCTAssertEqual(#"INSERT INTO "schema2"."DEMO_TABLE" ("TXT", "INT", "DBL") VALUES ('unique', 1, 678.9)"#, statements.last)

        let ob3 = try sqlite.insert(DemoTable(txt: "unique", int: 1, dbl: 555.00), inSchema: "schema3")
        XCTAssertEqual(#"INSERT INTO "schema3"."DEMO_TABLE" ("TXT", "INT", "DBL") VALUES ('unique', 1, 555.0)"#, statements.last)

        // now join across the schemas with a custom join predicate
        let joined = try sqlite.query(DemoTable.self, alias: "t0")
            .join(DemoTable.self, alias: "t1", schema: "schema2", kind: .inner, on: DemoTable.int.alias("t0").equals(DemoTable.int.alias("t1")))
            .join(DemoTable.self, alias: "t2", schema: "schema3", kind: .inner, on: DemoTable.int.alias("t1").equals(DemoTable.int.alias("t2")))
            .eval()
            .load()
        XCTAssertEqual(#"SELECT t0."ID", t0."TXT", t0."NUM", t0."INT", t0."DBL", t0."BLB", t1."ID", t1."TXT", t1."NUM", t1."INT", t1."DBL", t1."BLB", t2."ID", t2."TXT", t2."NUM", t2."INT", t2."DBL", t2."BLB" FROM "DEMO_TABLE" AS t0 INNER JOIN "schema2"."DEMO_TABLE" AS t1 ON t0."INT" = t1."INT" INNER JOIN "schema3"."DEMO_TABLE" AS t2 ON t1."INT" = t2."INT""#, statements.last)

        XCTAssertEqual(ob1, joined.first?.0)
        XCTAssertEqual(ob2, joined.first?.1)
        XCTAssertEqual(ob3, joined.first?.2)

        // also test custom rows
        let customq = try sqlite.query(SQLCustomRow.self)
            .eval()
            .load()
        XCTAssertEqual(#"SELECT "TXT", "INT" FROM "DEMO_TABLE""#, statements.last)
        XCTAssertEqual("unique", customq.first?.row[DemoTable.txt]?.textValue)
    }

    /// An example of a type that maps to a custom row with a subset of columns from the `DemoTable` type
    struct SQLCustomRow : SQLCodable {
        static var table: SQLTable = SQLTable(name: DemoTable.table.name, columns: [DemoTable.txt, DemoTable.int])

        let row: SQLRow

        init(row: SQLRow, context: SQLContext) throws {
            self.row = row
        }

        func encode(row: inout SQLRow) throws {
            row = self.row
        }
    }

    func testSQLRefType() throws {
        let sqlite = SQLContext(configuration: .test)
        var statements: [String] = []
        sqlite.trace { sql in
            self.logger.info("SQL: \(sql)")
            statements.append(sql)
        }

        try (SQLRefType.table.createTableSQL(withIndexes: true)).forEach {
            try sqlite.exec($0)
        }

        let ref = try SQLRefType(context: sqlite, str: "ABC")
        XCTAssertEqual(1, ref.rowid)
        XCTAssertEqual(#"INSERT INTO "SQL_REF" ("STR") VALUES ('ABC')"#, statements.last)

        ref.str += ref.str
        XCTAssertEqual(#"UPDATE "SQL_REF" SET "STR" = 'ABCABC' WHERE "ROWID" = 1"#, statements.last)

        ref.str += ref.str
        XCTAssertEqual(#"UPDATE "SQL_REF" SET "STR" = 'ABCABCABCABC' WHERE "ROWID" = 1"#, statements.last)

        try ref.delete()
        XCTAssertEqual(#"DELETE FROM "SQL_REF" WHERE "ROWID" = 1"#, statements.last)

        let ref2 = try SQLRefType(context: sqlite, str: "ABC")
        XCTAssertEqual(2, ref2.rowid, "autoincrement rowid should not have been reused after delete")

        let ref3 = try SQLRefType(context: sqlite, str: "ABC")
        XCTAssertEqual(3, ref3.rowid)

        try sqlite.exec(SQLRefType.table.dropTableSQL())
    }
}

extension SQLContext {
    var isSQLPlus: Bool {
        (try? selectAll(sql: "PRAGMA cipher_version").first?.first?.textValue) != nil
    }
}

/// A struct that can read and write its values to the `DEMO_TABLE` table.
public struct DemoTable : SQLCodable, Equatable {
    public var id: Int64?
    static let id = SQLColumn(name: "ID", type: .long, primaryKey: true)

    public var txt: String?
    static let txt = SQLColumn(name: "TXT", type: .text, unique: true, nullable: false, index: SQLIndex(name: "IDX_TXT"))

    public var num: Double?
    static let num = SQLColumn(name: "NUM", type: .real)

    public var int: Int
    static let int = SQLColumn(name: "INT", type: .long, nullable: false)

    public var dbl: Double?
    static let dbl = SQLColumn(name: "DBL", type: .real, defaultValue: SQLValue(Double.pi), index: SQLIndex(name: "IDX_DBL", unique: false))

    public var blb: Data?
    static let blb = SQLColumn(name: "BLB", type: .blob)

    public static let table = SQLTable(name: "DEMO_TABLE", columns: [id, txt, num, int, dbl, blb])

    public init(id: Int64? = nil, txt: String? = nil, num: Double? = nil, int: Int, dbl: Double? = nil, blb: Data? = nil) {
        self.id = id
        self.txt = txt
        self.num = num
        self.int = int
        self.dbl = dbl
        self.blb = blb
    }

    public init(row: SQLRow, context: SQLContext) throws {
        self.id = try Self.id.longValueRequired(in: row)
        self.txt = try Self.txt.textValueRequired(in: row)
        self.num = Self.num.realValue(in: row)
        self.int = try Int(Self.int.longValueRequired(in: row))
        self.dbl = Self.dbl.realValue(in: row)
        self.blb = Self.blb.blobValue(in: row)
    }

    public func encode(row: inout SQLRow) throws {
        row[Self.id] = SQLValue(self.id)
        row[Self.txt] = SQLValue(self.txt)
        row[Self.num] = SQLValue(self.num)
        row[Self.int] = SQLValue(self.int)
        row[Self.dbl] = SQLValue(self.dbl)
        row[Self.blb] = SQLValue(self.blb)
    }
}

public extension DemoTable {
    /// Fetches the one-to-many relationship for this instance
    func oneToManyRelation(in context: SQLContext) throws -> [DemoRelation] {
        try context.query(DemoRelation.self).where(DemoRelation.fk.equals(SQLValue(self.id))).eval().load()
    }

    /// Fetches the many-to-many relationship for this instance
    func manyToManyRelation(in context: SQLContext) throws -> [DemoTable] {
        let values: [(DemoTable?, DemoJoinTable?, DemoTable?)] = try context.query(DemoTable.self, alias: "t0")
            .join(DemoJoinTable.self, alias: "t1", kind: .inner, on: DemoJoinTable.id1)
            .join(DemoTable.self, alias: "t2", kind: .inner, on: DemoJoinTable.id2)
            .where(DemoTable.id.alias("t0").equals(SQLValue(self.id)))
            .eval()
            .load()

        return values.compactMap(\.2)
    }

    /// Adds the given instance to the many-many relationship table
    internal func addManyToManyRelation(instance: DemoTable, to context: SQLContext) throws -> DemoJoinTable? {
        if let id1 = self.id, let id2 = instance.id {
            return try context.insert(DemoJoinTable(id1: id1, id2: id2))
        } else {
            return nil
        }
    }

    /// Removes the given instance from the many-many relationship table
    func removeManyToManyRelation(instance: DemoTable, from context: SQLContext) throws {
        try context.delete(DemoJoinTable.self, where: DemoJoinTable.id1.equals(SQLValue(self.id)).and(DemoJoinTable.id2.equals(SQLValue(instance.id))))
    }
}

public struct DemoRelation : SQLCodable, Equatable {
    public let pk: Int64
    static let pk = SQLColumn(name: "PK", type: .long, primaryKey: true, autoincrement: true)

    public let fk: Int64?
    static let fk = SQLColumn(name: "FK", type: .long, references: SQLForeignKey(table: DemoTable.table, column: DemoTable.id, onDelete: .setNull))

    public var info: String
    static let info = SQLColumn(name: "INFO", type: .text, unique: true, nullable: false, index: SQLIndex(name: "IDX_TXT"))

    public static let table = SQLTable(name: "DEMO_RELATION", columns: [pk, fk, info])

    public init(pk: Int64 = 0, fk: Int64? = nil, info: String) {
        self.pk = pk
        self.fk = fk
        self.info = info
    }

    public init(row: SQLRow, context: SQLContext) throws {
        self.pk = try Self.pk.longValueRequired(in: row)
        self.fk = Self.fk.longValue(in: row)
        self.info = try Self.info.textValueRequired(in: row)
    }

    public func encode(row: inout SQLRow) throws {
        row[Self.pk] = SQLValue(self.pk)
        row[Self.fk] = SQLValue(self.fk)
        row[Self.info] = SQLValue(self.info)
    }
}

/// A type that can read and write its values to the `DEMO_TABLE` table.
open class DemoJoinTableBase : SQLCodable {
    public let id1: Int64
    static let id1 = SQLColumn(name: "ID1", type: .long, primaryKey: true, nullable: false, references: SQLForeignKey(table: DemoTable.table, column: DemoTable.id, onDelete: .cascade))

    public let id2: Int64
    static let id2 = SQLColumn(name: "ID2", type: .long, primaryKey: true, nullable: false, references: SQLForeignKey(table: DemoTable.table, column: DemoTable.id, onDelete: .cascade))

    public static let table = SQLTable(name: "DEMO_JOIN_TABLE", columns: [id1, id2])

    public init(id1: Int64, id2: Int64) {
        self.id1 = id1
        self.id2 = id2
    }

    public required init(row: SQLRow, context: SQLContext) throws {
        self.id1 = try Self.id1.longValueRequired(in: row)
        self.id2 = try Self.id2.longValueRequired(in: row)
    }

    public func encode(row: inout SQLRow) throws {
        row[Self.id1] = SQLValue(self.id1)
        row[Self.id2] = SQLValue(self.id2)
    }
}

extension DemoJoinTable : Equatable {
    public static func == (lhs: DemoJoinTable, rhs: DemoJoinTable) -> Bool {
        lhs.id1 == rhs.id1 && lhs.id2 == rhs.id2
    }
}

/// Demonstration that subclassing works with SQLCodable (although you can't add any properties or override the table for the type with new columns)
internal final class DemoJoinTable : DemoJoinTableBase {
//    public override init(id1: Int64, id2: Int64) {
//        super.init(id1: id1, id2: id2)
//    }

//    public required init(row: SQLRow, in context: SQLContext) throws {
//        try super.init(row: row)
//    }

}

/// An example of a type that maintains its own context
public class SQLRefType : SQLCodable {
    private let context: SQLContext

    fileprivate var rowid: Int64
    static let rowid = SQLColumn(name: "ROWID", type: .long, primaryKey: true, autoincrement: true)

    public var str: String { didSet { try? update() } }
    static let str = SQLColumn(name: "STR", type: .text, nullable: false, index: SQLIndex(name: "IDX_TXT"))

    public static let table = SQLTable(name: "SQL_REF", columns: [rowid, str])

    /// Create a new instance and insert it into the database
    public init(context: SQLContext, str: String) throws {
        self.rowid = 0 // zero means it is unassigned
        self.context = context
        self.str = str
        try context.insert(self)
        self.rowid = context.lastInsertRowID // fetched the inserted ID from the database
    }

    public required init(row: SQLRow, context: SQLContext) throws {
        self.context = context
        self.rowid = try Self.rowid.longValueRequired(in: row)
        self.str = try Self.str.textValueRequired(in: row)
    }

    public func encode(row: inout SQLRow) throws {
        row[Self.rowid] = SQLValue(self.rowid)
        row[Self.str] = SQLValue(self.str)
    }

    public func update() throws {
        try context.update(self)
    }

    public func delete() throws {
        try context.delete(instances: [self])
    }
}

public protocol SQLDateType : SQLCodable {
    var date: Date { get set }
}

public struct SQLDateAsText : SQLCodable, SQLDateType {
    public var rowid: Int64
    static let rowid = SQLColumn(name: "ROWID", type: .long, primaryKey: true, autoincrement: true)

    public var date: Date
    static let date = SQLColumn(name: "DATE", type: .text)

    public static let table = SQLTable(name: "SQL_DATE_AS_TEXT", columns: [rowid, date])

    public init(date: Date) {
        self.rowid = 0
        self.date = date
    }

    public init(row: SQLRow, context: SQLContext) throws {
        self.rowid = try Self.rowid.longValueRequired(in: row)
        self.date = try Self.date.dateValueRequired(in: row)
    }

    public func encode(row: inout SQLRow) throws {
        row[Self.rowid] = SQLValue(self.rowid)
        row[Self.date] = SQLValue(self.date.ISO8601Format())
    }
}

public struct SQLDateAsReal : SQLCodable, SQLDateType {
    public var rowid: Int64
    static let rowid = SQLColumn(name: "ROWID", type: .long, primaryKey: true, autoincrement: true)

    public var date: Date
    static let date = SQLColumn(name: "DATE", type: .real)

    public static let table = SQLTable(name: "SQL_DATE_AS_REAL", columns: [rowid, date])

    public init(date: Date) {
        self.rowid = 0
        self.date = date
    }

    public init(row: SQLRow, context: SQLContext) throws {
        self.rowid = try Self.rowid.longValueRequired(in: row)
        self.date = try Self.date.dateValueRequired(in: row)
    }

    public func encode(row: inout SQLRow) throws {
        row[Self.rowid] = SQLValue(self.rowid)
        row[Self.date] = SQLValue(self.date.timeIntervalSince1970)
    }
}
