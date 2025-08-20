// Copyright 2023–2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
import Foundation

public typealias SQLRow = [SQLColumn: SQLValue]

/// A representable of a SQL table
public struct SQLTable : Hashable, Sendable {
    public var name: String
    public var columns: [SQLColumn]

    public init(name: String, columns: [SQLColumn]) {
        self.name = name
        self.columns = columns
    }

    public func quotedName(inSchema: String? = nil) -> String {
        if let inSchema {
            return inSchema.quote(#"""#) + "." + name.quote(#"""#)
        } else {
            return name.quote(#"""#)
        }
    }

    public func dropTableSQL(inSchema schemaName: String? = nil, ifExists: Bool = false) -> SQLExpression {
        var sql = "DROP TABLE "
        if ifExists {
            sql += "IF EXISTS "
        }
        sql += self.quotedName(inSchema: schemaName)
        return SQLExpression(sql)
    }

    /// Returns the SQL to create this table.
    public func createTableSQL(inSchema schemaName: String? = nil, ifNotExists: Bool = false, withIndexes: Bool = true, columns: [SQLColumn]? = nil, additionalClauses: [String] = []) -> [SQLExpression] {
        var sql = "CREATE TABLE "
        if ifNotExists {
            sql += "IF NOT EXISTS "
        }

        sql += self.quotedName(inSchema: schemaName)

        let columns = columns ?? self.columns

        var clauses: [String] = []
        let pkColumns = columns.filter(\.primaryKey)
        if pkColumns.count >= 2 {
            // primary key clause added to the end only when there are multiple PKs for the table
            clauses.append("PRIMARY KEY (\(pkColumns.map({ $0.quotedName() }).joined(separator: ", ")))")
        }

        let fkColumns = columns.filter({ $0.references != nil })
        for fkColumn in fkColumns {
            // add in any foreign key clauses
            if let reference = fkColumn.references {
                clauses.append("FOREIGN KEY (\(fkColumn.quotedName())) REFERENCES \(reference.referencesClause(inSchema: schemaName))")
            }
        }

        // finally add any manual clauses that are needed
        clauses += additionalClauses

        sql += " ("
        sql += (columns.map({ col in
            col.definition(withPrimaryKey: pkColumns.count == 1)
        }) + clauses).joined(separator: ", ")
        sql += ")"

        return [SQLExpression(sql)] + (withIndexes ? createIndexSQL(inSchema: schemaName, ifNotExists: ifNotExists, columns: columns) : [])
    }

    /// Returns the SQL to add a column to the given table
    public func addColumnSQL(column: SQLColumn, inSchema schemaName: String? = nil, withIndexes: Bool = true) -> [SQLExpression] {
        var sql = "ALTER TABLE \(self.quotedName(inSchema: schemaName)) ADD COLUMN "
        sql += column.definition(withPrimaryKey: false)
        return [SQLExpression(sql)] + (withIndexes ? createIndexSQL(inSchema: schemaName, columns: [column]) : [])
    }

    /// Returns the SQL to add a column to the given table
    public func dropColumnSQL(column: SQLColumn, inSchema schemaName: String? = nil) -> SQLExpression {
        var sql = "ALTER TABLE \(self.quotedName(inSchema: schemaName)) DROP COLUMN "
        sql += column.quotedName()
        return SQLExpression(sql)
    }

    /// Returns the SQL to create any indices on this table.
    public func createIndexSQL(inSchema schemaName: String? = nil, ifNotExists: Bool = false, columns: [SQLColumn]? = nil) -> [SQLExpression] {
        var stmnts: [SQLExpression] = []
        for column in columns ?? self.columns {
            if let index = column.index {
                var sql = "CREATE INDEX "
                if ifNotExists {
                    sql += "IF NOT EXISTS "
                }
                if let schemaName {
                    sql += schemaName.quote()
                    sql += "."
                }
                sql += index.name.quote()
                sql += " ON "
                sql += self.quotedName(inSchema: nil) // schema goes on index name, not table name
                sql += "("
                // TODO: compound indices
                sql += column.quotedName()
                sql += ")"
                stmnts.append(SQLExpression(sql))
            }
        }
        return stmnts
    }
}

/// A representable of a SQL column
public struct SQLColumn : Hashable, Sendable {
    public var name: String
    public var type: SQLType
    public var primaryKey: Bool
    public var autoincrement: Bool
    public var unique: Bool
    public var nullable: Bool
    public var defaultValue: SQLValue?
    public var index: SQLIndex?
    public var references: SQLForeignKey?
    /// An optional override of the columns definition for use in a `CREATE TABLE` statement
    public var columnDefinition: String?

    public init(name: String, type: SQLType, primaryKey: Bool = false, autoincrement: Bool = false, unique: Bool = false, nullable: Bool = true, defaultValue: SQLValue? = nil, index: SQLIndex? = nil, references: SQLForeignKey? = nil, columnDefinition: String? = nil) {
        self.name = name
        self.type = type
        self.primaryKey = primaryKey
        self.autoincrement = autoincrement
        self.unique = unique
        self.nullable = nullable
        self.defaultValue = defaultValue
        self.references = references
        self.index = index
        self.columnDefinition = columnDefinition
    }

    public func quotedName(alias: String? = nil) -> String {
        if let alias {
            return alias + "." + name.quote(#"""#)
        } else {
            return name.quote(#"""#)
        }
    }

    func definition(withPrimaryKey: Bool) -> String {
        if let columnDefinition {
            // definition override
            return columnDefinition
        }
        var def = quotedName() + " " + type.typeName
        if withPrimaryKey {
            if primaryKey {
                def += " PRIMARY KEY"
            }
            if autoincrement {
                def += " AUTOINCREMENT"
            }
        }
        if unique {
            def += " UNIQUE"
        }
        if !nullable {
            def += " NOT NULL"
        }
        if let defaultValue = defaultValue {
            def += " DEFAULT \(defaultValue.literalValue)"
        }
        return def
    }
}

public struct SQLIndex : Hashable, Sendable {
    public var name: String
    public var unique: Bool

    public init(name: String, unique: Bool = false) {
        self.name = name
        self.unique = unique
    }
}

public struct SQLForeignKey : Hashable, Sendable {
    public var table: SQLTable
    public var columns: [SQLColumn]
    public var deleteAction: SQLForeignKeyAction?
    public var updateAction: SQLForeignKeyAction?

    public init(table: SQLTable, column: SQLColumn, onDelete deleteAction: SQLForeignKeyAction? = nil, onUpdate updateAction: SQLForeignKeyAction? = nil) {
        self.table = table
        self.columns = [column]
        self.deleteAction = deleteAction
        self.updateAction = updateAction
    }

    public func referencesClause(inSchema schemaName: String? = nil) -> String {
        var fkClause = self.table.quotedName(inSchema: schemaName)
        fkClause += "("
        fkClause += self.columns.map({ $0.quotedName() }).joined(separator: ", ")
        fkClause += ")"
        if let onDelete = self.deleteAction {
            fkClause += " ON DELETE \(onDelete.actionClause)"
        }
        if let onUpdate = self.updateAction {
            fkClause += " ON UPDATE \(onUpdate.actionClause)"
        }
        return fkClause
    }
}

public enum SQLForeignKeyAction : Hashable, Sendable {
    case cascade
    case restrict
    case setNull
    case setDefault

    public var actionClause: String {
        switch self {
        case .cascade: return "CASCADE"
        case .restrict: return "RESTRICT"
        case .setNull: return "SET NULL"
        case .setDefault: return "SET DEFAULT"
        }
    }
}

public extension SQLColumn {
    func value(in row: SQLRow) -> SQLValue? {
        row[self]
    }

    func valueRequired(in row: SQLRow) throws -> SQLValue {
        try SQLBindingError.checkNonNull(value(in: row), self)
    }

    func longValue(in row: SQLRow) -> Int64? {
        row[self]?.longValue
    }

    func longValueRequired(in row: SQLRow) throws -> Int64 {
        try SQLBindingError.checkNonNull(longValue(in: row), self)
    }

    func realValue(in row: SQLRow) -> Double? {
        row[self]?.realValue
    }

    func realValueRequired(in row: SQLRow) throws -> Double {
        try SQLBindingError.checkNonNull(realValue(in: row), self)
    }

    func textValue(in row: SQLRow) -> String? {
        row[self]?.textValue
    }

    func textValueRequired(in row: SQLRow) throws -> String {
        try SQLBindingError.checkNonNull(textValue(in: row), self)
    }

    func blobValue(in row: SQLRow) -> Data? {
        row[self]?.blobValue
    }

    func blobValueRequired(in row: SQLRow) throws -> Data {
        try SQLBindingError.checkNonNull(blobValue(in: row), self)
    }

    /// SQLite does not have a storage class set aside for storing dates and/or times. Instead, the built-in Date And Time Functions of SQLite are capable of storing dates and times as TEXT, REAL, or INTEGER values:
    ///
    ///  - TEXT as ISO8601 strings ("YYYY-MM-DD HH:MM:SS.SSS").
    ///  - REAL as Julian day numbers, the number of days since noon in Greenwich on November 24, 4714 B.C. according to the proleptic Gregorian calendar.
    ///  - INTEGER as Unix Time, the number of seconds since 1970-01-01 00:00:00 UTC.
    ///
    /// Applications can choose to store dates and times in any of these formats and freely convert between formats using the built-in date and time functions.
    func dateValue(in row: SQLRow) -> Date? {
        if self.type == .real {
            return self.realValue(in: row).flatMap({ Date(timeIntervalSince1970: $0) })
        } else if self.type == .text {
            guard let textValue = self.textValue(in: row) else {
                return nil
            }
            var dateString = textValue
            // try to parse the full date, and if it cannot, coerce some common degenerate variants
            if let date = sharedISO8601DateFormatter.date(from: dateString) {
                return date
            }
            dateString = dateString.replacingOccurrences(of: " ", with: "T")
            if let date = sharedISO8601DateFormatter.date(from: dateString) {
                return date
            }

            dateString += "Z"
            if let date = sharedISO8601DateFormatter.date(from: dateString) {
                return date
            }

            dateString = (dateString.split(separator: ".").first?.description ?? dateString) + "Z"
            if let date = sharedISO8601DateFormatter.date(from: dateString) {
                return date
            }

            //logger.warn("could not parse date string from text field: \(textValue) in column \(self.name)")
            return nil
        } else {
            return nil
        }
    }

    func dateValueRequired(in row: SQLRow) throws -> Date {
        try SQLBindingError.checkNonNull(dateValue(in: row), self)
    }
}

private let sharedISO8601DateFormatter = ISO8601DateFormatter()

// SKIP NOWARN // "This extension will be moved into its extended type definition when translated to Kotlin. It will not be able to access this file's private types or fileprivate members"
public extension SQLContext {
    /// Returns an array of tables in the database obtained by querying the `sqlite_master` table.
    func tables(types: [String] = ["table"]) throws -> [TableInfo] {
        try issueQuery(TableInfo.self, where: TableInfo.type.in(types.map({ SQLValue.text($0) }))).load()
    }
    
    /// Returns the list of columns for the specified table and schema name by querying the `pragma_table_info` table.
    ///
    /// https://www.sqlite.org/pragma.html#pragma_table_info
    func columns(for tableName: String, in schemaName: String = "main") throws -> [ColumnInfo] {
        // the custom sql is a bit of a hack
        try issueQuery(ColumnInfo.self, where: .custom(sql: "name IS NOT NULL", bindings: [.text(tableName), .text(schemaName)])).load()
    }
}

/// `sqlite_master` (the new recommended `sqlite_schema` name was introduced in SQLite 3.33.0)
/// `type|name|tbl_name|rootpage|sql`
public struct TableInfo : SQLCodable, Equatable {
    public var type: String
    static let type = SQLColumn(name: "type", type: .text)

    public var name: String
    static let name = SQLColumn(name: "name", type: .text)

    public var tbl_name: String
    static let tbl_name = SQLColumn(name: "tbl_name", type: .text)

    public var rootpage: Int64
    static let rootpage = SQLColumn(name: "rootpage", type: .long)

    /// the default value for the column
    public var sql: String?
    static let sql = SQLColumn(name: "sql", type: .text)

    public static let table = SQLTable(name: "sqlite_master", columns: [type, name, tbl_name, rootpage, sql])

    public init(type: String, name: String, tbl_name: String, rootpage: Int64, sql: String?) {
        self.type = type
        self.name = name
        self.tbl_name = tbl_name
        self.rootpage = rootpage
        self.sql = sql
    }

    public init(row: SQLRow, context: SQLContext) throws {
        self.type = try Self.type.textValueRequired(in: row)
        self.name = try Self.name.textValueRequired(in: row)
        self.tbl_name = try Self.tbl_name.textValueRequired(in: row)
        self.rootpage = try Self.rootpage.longValueRequired(in: row)
        self.sql = Self.sql.textValue(in: row)
    }

    public func encode(row: inout SQLRow) throws {
        row[Self.type] = SQLValue(self.type)
        row[Self.name] = SQLValue(self.name)
        row[Self.tbl_name] = SQLValue(self.tbl_name)
        row[Self.rootpage] = SQLValue(self.rootpage)
        row[Self.sql] = SQLValue(self.sql)
    }
}

/// https://sqlite.org/pragma.html#pragma_table_info
///
/// `select * from pragma_table_info('foo')`
public struct ColumnInfo : SQLCodable, Equatable {
    public var cid: Int64
    static let cid = SQLColumn(name: "cid", type: .long)

    public var name: String
    static let name = SQLColumn(name: "name", type: .text)

    /// data type if given, else ''
    public var type: String
    static let type = SQLColumn(name: "type", type: .text)

    /// whether or not the column can be NULL
    public var notnull: Int64
    static let notnull = SQLColumn(name: "notnull", type: .long)

    /// the default value for the column
    public var dflt_value: SQLValue
    static let dflt_value = SQLColumn(name: "dflt_value", type: .text)

    /// either zero for columns that are not part of the primary key, or the 1-based index of the column within the primary key
    public var pk: Int64
    static let pk = SQLColumn(name: "pk", type: .long)

    public static let table = SQLTable(name: "pragma_table_info(?, ?)", columns: [cid, name, type, notnull, dflt_value, pk])

    public init(cid: Int64, name: String, type: String, notnull: Int64, dflt_value: SQLValue, pk: Int64) {
        self.cid = cid
        self.name = name
        self.type = type
        self.notnull = notnull
        self.dflt_value = dflt_value
        self.pk = pk
    }

    public init(row: SQLRow, context: SQLContext) throws {
        self.cid = try Self.cid.longValueRequired(in: row)
        self.name = try Self.name.textValueRequired(in: row)
        self.type = try Self.type.textValueRequired(in: row)
        self.notnull = try Self.notnull.longValueRequired(in: row)
        self.dflt_value = try Self.dflt_value.valueRequired(in: row)
        self.pk = try Self.pk.longValueRequired(in: row)
    }

    public func encode(row: inout SQLRow) throws {
        row[Self.cid] = SQLValue(self.cid)
        row[Self.name] = SQLValue(self.name)
        row[Self.type] = SQLValue(self.type)
        row[Self.notnull] = SQLValue(self.notnull)
        row[Self.dflt_value] = self.dflt_value
        row[Self.pk] = SQLValue(self.pk)
    }
}
