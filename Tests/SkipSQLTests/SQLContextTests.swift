// Copyright 2023–2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
import XCTest
import OSLog
import Foundation
import SkipSQL
#if SKIP
import kotlin.reflect.full.__
#endif

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
            XCTAssertEqual(.long(1), try count(table: "SQLTYPES"))
        }

        // interrupt a transaction to issue a rollback, an make sure the row wasn't inserted
        try? sqlite.transaction {
            try sqlite.exec(sql: "INSERT INTO SQLTYPES VALUES('ZZZ', 1.1, 1, 2.2, X'78797A')")
            try sqlite.exec(sql: "skip_sql_throws_error_and_issues_rollback()")
        }

        XCTAssertEqual(.long(1), try count(table: "SQLTYPES"))

        // now really insert the row and try some more queries
        try sqlite.transaction {
            //try sqlite.exec(sql: "INSERT INTO SQLTYPES VALUES('XYZ', 1.1, 1, 3.3, X'78797A')")
            try sqlite.exec(sql: "INSERT INTO SQLTYPES VALUES(?, ?, ?, ?, ?)", parameters: [.text("XYZ"), .real(1.1), .long(1), .real(3.3), .blob(Data())])
        }

        XCTAssertEqual(SQLValue.long(2), try count(table: "SQLTYPES"))
        XCTAssertEqual(SQLValue.long(1), try count(distinct: true, columns: "NUM", table: "SQLTYPES"))

        do {
            let numquery = try sqlite.prepare(sql: "SELECT COUNT(*) FROM SQLTYPES WHERE DBL >= ?")
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
            let squery = try sqlite.prepare(sql: "SELECT TXT FROM SQLTYPES")
            XCTAssertTrue(try squery.next())
            XCTAssertEqual("ABC", squery.text(at: 0))
            XCTAssertTrue(try squery.next())
            XCTAssertEqual("XYZ", squery.text(at: 0))
            try squery.close()
        }

        do {
            let strquery = try sqlite.prepare(sql: "SELECT COUNT(*) FROM SQLTYPES WHERE TXT = ?")

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
            let blbquery = try sqlite.prepare(sql: "SELECT COUNT(*) FROM SQLTYPES WHERE BLB = ?")

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

        // XCTAssertEqual(1, try sqlite.exec(sql: "DELETE FROM SQLTYPES LIMIT 1")) // Android fail: SQLiteLog: (1) near "LIMIT": syntax error in "DELETE FROM SQLTYPES LIMIT 1"
        // XCTAssertEqual(.long(1), try count(table: "SQLTYPES"))

        try sqlite.exec(sql: "DELETE FROM SQLTYPES")
        XCTAssertEqual(SQLValue.long(0), try count(table: "SQLTYPES"))

        try sqlite.exec(sql: "DROP TABLE SQLTYPES")

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

    func testMiniORM() throws {
        let sqlite = SQLContext(configuration: .test)
        sqlite.trace { self.logger.info("SQL: \($0)") }

        func count(distinct: Bool = false, columns: String = "*", table: String) throws -> SQLValue? {
            try sqlite.prepare(sql: "SELECT COUNT(\(distinct ? "DISTINCT" : "") \(columns)) FROM \"\(table)\"").nextValues(close: true)?.first
        }

        try sqlite.exec(SQLTYPES.createSQL())
        var ob = SQLTYPES(txt: "ABC", num: 12.3, int: 456, dbl: 7.89, blb: "XYZ".data(using: .utf8))
        try sqlite.inserted(&ob)
        XCTAssertEqual(1, ob.id, "primary key should have been assigned")
        let initialInstance = ob

        XCTAssertEqual(SQLValue.long(1), try count(table: "SQLTYPES"))

        ob.txt = "DEF"
        ob.id = nil // need to manually clear the ID so it doesn't attempt to set it in the instance
        try sqlite.inserted(&ob)
        XCTAssertEqual(2, ob.id, "primary key should have been assigned")

        XCTAssertEqual(SQLValue.long(2), try count(table: "SQLTYPES"))

        // now manually set the ID to ensure that it is used

        ob.txt = "GHI"
        ob.id = 6
        try sqlite.inserted(&ob)
        XCTAssertEqual(6, ob.id, "manual primary key specification should have been used")

        ob.id = nil // auto-assign the next row
        try sqlite.inserted(&ob)
        XCTAssertEqual(7, ob.id)

        ob.id = 4
        try sqlite.insert(ob, upsert: false)

        ob.txt = "ZZZ"
        do {
            try sqlite.insert(ob, upsert: false)
            XCTFail("insert duplicate PK should have failed")
        } catch let error as SQLError {
            // expected
            XCTAssertEqual("UNIQUE constraint failed: SQLTYPES.ID", error.msg)
        }

        // try again as an upsert
        try sqlite.insert(ob, upsert: true)

        XCTAssertEqual(SQLValue.long(5), try count(table: "SQLTYPES"))

        do {
            let cursor = try sqlite.cursor(SQLTYPES.selectSQL())

            // if we don't close the cursor before dropping the table, results in the error in Kotlin (GC'd):
            // SQLite error code 6: database table is locked
            defer { cursor.close() }

            XCTAssertEqual(initialInstance.bindings, try? cursor.makeIterator().next()?.get())
        }

        // now try a cursored read of database instances
        do {
            let cursor = try SQLTYPES.select(context: sqlite)

            // if we don't close the cursor before dropping the table, results in the error in Kotlin (GC'd):
            // SQLite error code 6: database table is locked
            defer { cursor.close() }

            XCTAssertEqual(initialInstance, try? cursor.makeIterator().next()?.get())
        }

        do {
            let idRanges = try sqlite.query(sql: "SELECT GROUP_CONCAT(ROWID, ',') AS ids FROM SQLTYPES")
            XCTAssertEqual("1,2,4,6,7", idRanges.first?.first?.textValue)
        }

        do {
            // select a compact set of ranges of ROWIDs from the table
            let idRanges = try sqlite.query(sql: """
            WITH numbered_rows AS (
              SELECT 
                ROWID,
                ROWID - ROW_NUMBER() OVER (ORDER BY ROWID) AS grp
              FROM SQLTYPES
            ),
            ranges AS (
              SELECT 
                grp,
                MIN(ROWID) AS range_start,
                MAX(ROWID) AS range_end,
                COUNT(*) AS range_count
              FROM numbered_rows
              GROUP BY grp
            )
            SELECT 
              GROUP_CONCAT(
                CASE 
                  WHEN range_start = range_end THEN range_start
                  ELSE range_start || '-' || range_end
                END,
                ','
              ) AS compact_ranges
            FROM ranges
            ORDER BY range_start;
            """)

            XCTAssertEqual("1-2,4,6-7", idRanges.first?.first?.textValue)
        }

        try sqlite.exec(SQLTYPES.dropSQL())
    }
}


public enum SQLErrors : Error {
    case unknownColumn(SQLColumn)
    case nullColumn(SQLColumn)
    case columnValuesMismatch(Int, Int)

    /// Verifies that the value is not null, throwing a `nullColumn` error if it is null.
    public static func checkNonNull<T>(_ value: T?, _ column: SQLColumn) throws -> T {
        guard let value else { throw nullColumn(column) }
        return value
    }
}

public struct SQLColumn : Hashable {
    public var name: String
    public var type: SQLType
    public var primaryKey: Bool

    public init(name: String, type: SQLType, primaryKey: Bool = false) {
        self.name = name
        self.type = type
        self.primaryKey = primaryKey
    }

    public var definition: String {
        var def = name.quote() + " " + type.typeName
        if primaryKey {
            def += " PRIMARY KEY"
        }
        return def
    }
}

public protocol SQLTable {
    /// The name of the table
    static var tableName: String { get }
    /// The table's columns
    static var columns: [SQLColumn] { get }
    /// The current instance's properties in the form of `SQLValue` bindings
    var bindings: [SQLValue] { get }
    /// Instantiate this item with the given rows with the (optional) corresponding columns.
    static func create(withRow row: [SQLValue], fromColumns: [SQLColumn]?) throws -> Self
    /// Updates the property in this instance with the value of the given column, which must exactly match one of the `columns` values
    mutating func update(column: SQLColumn, value: SQLValue) throws
}

public extension SQLTable {
    static func selectSQL() -> SQLExpression {
        var sql = "SELECT "
        sql += columns.map({ $0.name.quote() }).joined(separator: ", ")
        sql += " FROM "
        sql += tableName.quote()

        return SQLExpression(sql)
    }

    static func dropSQL(ifExists: Bool = false) -> SQLExpression {
        var sql = "DROP TABLE "
        if ifExists {
            sql += "IF EXISTS "
        }
        sql += tableName.quote()
        return SQLExpression(sql)
    }

    static func createSQL(ifNotExists: Bool = false) -> SQLExpression {
        var sql = "CREATE TABLE "
        if ifNotExists {
            sql += "IF NOT EXISTS "
        }
        sql += tableName.quote()
        sql += " ("
        sql += columns.map({ $0.definition }).joined(separator: ", ")
        sql += ")"
        return SQLExpression(sql)
    }

    func insertSQL(upsert: Bool) -> SQLExpression {
        let columns = type(of: self).columns
        var sql = "INSERT INTO \(type(of: self).tableName) ("
        sql += columns.map({ $0.name.quote() }).joined(separator: ", ")
        sql += ") VALUES ("
        sql += columns.map({ _ in "?" }).joined(separator: ", ")
        sql += ")"
        if upsert, let pkColumn = columns.first(where: { $0.primaryKey == true }) {
            sql += " ON CONFLICT("
            sql += pkColumn.name.quote()
            sql += ") DO UPDATE SET"
            for (index, col) in columns.enumerated() {
                if index != 0 {
                    sql += ","
                }
                sql += " " + col.name.quote() + " = EXCLUDED." + col.name.quote()
            }
        }
        return SQLExpression(sql, self.bindings)
    }

    static func select(context: SQLContext) throws -> RowCursor<Self> {
        RowCursor(statement: try context.prepare(expr: selectSQL())) {
            try create(withRow: $0.rowValues(), fromColumns: columns)
        }
    }
}

public extension SQLContext {
    /// Prepares the given SQL as a statement, which can be executed with parameter bindings.
    func prepare(expr: SQLExpression) throws -> SQLStatement {
        let stmnt = try prepare(sql: expr.template)
        if !expr.bindings.isEmpty {
            try stmnt.bind(parameters: expr.bindings)
        }
        return stmnt
    }

    /// Performs an insert of the given `SQLTable` instance
    func insert<T: SQLTable>(_ ob: T, upsert: Bool = false) throws {
        try exec(ob.insertSQL(upsert: upsert))
    }

    /// Performs an insert of the given `SQLTable` instance and updates it with the expected ROWID for any primary key columns in the instance
    func inserted<T: SQLTable>(_ ob: inout T) throws {
        try insert(ob, upsert: false)

        // check for primary key column and update it with the last insert Row ID
        //let columns = T.columns
        let columns = type(of: ob).columns // needed for Kotlin
        for col in columns {
            if col.primaryKey && col.type == .long {
                // get the last inserted row id and update it in the object
                try ob.update(column: col, value: .long(lastInsertRowID))
                break // only a single primary key is supported for auto-update
            }
        }
    }

    #if !SKIP
    @inline(__always) func select<T: SQLTable>(_ type: T.Type, _ expr: SQLExpression? = nil) throws -> RowCursor<T> {
        // Type parameter 'T' cannot have or inherit a companion object, so it cannot be on the left-hand side of a dot.
        // SKIP REPLACE: val TType = T::class.companionObjectInstance as T.Companion
        typealias TType = T
        return RowCursor(statement: try prepare(expr: expr ?? TType.selectSQL()), creator: { try TType.create(withRow: $0.rowValues(), fromColumns: TType.columns) })
    }
    #endif

    // non-generic example
    internal func selectSQLTYPES(_ expr: SQLExpression = SQLTYPES.selectSQL()) throws -> RowCursor<SQLTYPES> {
        RowCursor(statement: try prepare(expr: expr)) {
            try SQLTYPES(withRow: $0.rowValues(), fromColumns: SQLTYPES.columns)
        }
    }

}

struct SQLTYPES : SQLTable, Hashable {
    static var tableName = "SQLTYPES"

    var id: Int64?
    static let idColumn = SQLColumn(name: "ID", type: .long, primaryKey: true)
    var txt: String?
    static let txtColumn = SQLColumn(name: "TXT", type: .text)
    var num: Double?
    static let numColumn = SQLColumn(name: "NUM", type: .real)
    var int: Int
    static let intColumn = SQLColumn(name: "INT", type: .long)
    var dbl: Double?
    static let dblColumn = SQLColumn(name: "DBL", type: .real)
    var blb: Data?
    static let blbColumn = SQLColumn(name: "BLB", type: .blob)

    static var columns: [SQLColumn] {
        [
            idColumn,
            txtColumn,
            numColumn,
            intColumn,
            dblColumn,
            blbColumn,
        ]
    }

    var bindings: [SQLValue] {
        [
            SQLValue(id),
            SQLValue(txt),
            SQLValue(num),
            SQLValue(int),
            SQLValue(dbl),
            SQLValue(blb),
        ]
    }

    init(id: Int64? = nil, txt: String? = nil, num: Double? = nil, int: Int, dbl: Double? = nil, blb: Data? = nil) {
        self.id = id
        self.txt = txt
        self.num = num
        self.int = int
        self.dbl = dbl
        self.blb = blb
    }

    static func create(withRow row: [SQLValue], fromColumns: [SQLColumn]? = nil) throws -> Self {
        try SQLTYPES(withRow: row, fromColumns: fromColumns)
    }

    init(withRow row: [SQLValue], fromColumns: [SQLColumn]? = nil) throws {
        self.int = 0 // need to initialize any non-nil instances with placeholder values
        let columns = fromColumns ?? Self.columns
        if row.count != columns.count {
            throw SQLErrors.columnValuesMismatch(row.count, columns.count)
        }
        for (value, column) in zip(row, columns) {
            try update(column: column, value: value)
        }
    }

    /// Updates the value of the given column with the given value
    mutating func update(column: SQLColumn, value: SQLValue) throws {
        switch column {
        case Self.idColumn: self.id = value.longValue
        case Self.txtColumn: self.txt = value.textValue
        case Self.numColumn: self.num = value.realValue
        case Self.intColumn: self.int = .init(try SQLErrors.checkNonNull(value.longValue, column))
        case Self.dblColumn: self.dbl = value.realValue
        case Self.blbColumn: self.blb = value.blobValue
        default: throw SQLErrors.unknownColumn(column)
        }
    }
}
