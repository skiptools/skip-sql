// Copyright 2023–2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
import Foundation
#if SKIP
import kotlin.reflect.full.__
#endif

/// A type that can be stored and retrieved from a SQL context
public protocol SQLCodable : Sendable {
    /// The name of the table that stores this type
    static var tableName: String { get }
    /// The table's column definitions
    static var columns: [SQLColumn] { get }
    /// Instantiate this item with the given rows with the (optional) corresponding columns.
    static func create(withRow row: [SQLValue], fromColumns: [SQLColumn]?) throws -> Self
    /// Updates the property in this instance with the value of the given column, which must exactly match one of the `columns` values
    mutating func update(column: SQLColumn, value: SQLValue) throws
    /// Returns the binding for the given `SQLColumn`
    func binding(forColumn: SQLColumn) throws -> SQLValue
}

public struct SQLColumn : Hashable, Sendable {
    public var name: String
    public var type: SQLType
    public var primaryKey: Bool
    public var autoincrement: Bool
    public var unique: Bool
    public var nullable: Bool
    public var defaultValue: SQLValue?
    /// An optional override of the columns definition for use in a `CREATE TABLE` statement
    public var columnDefinition: String?

    public init(name: String, type: SQLType, primaryKey: Bool = false, autoincrement: Bool = false, unique: Bool = false, nullable: Bool = true, defaultValue: SQLValue? = nil, columnDefinition: String? = nil) {
        self.name = name
        self.type = type
        self.primaryKey = primaryKey
        self.autoincrement = autoincrement
        self.unique = unique
        self.nullable = nullable
        self.defaultValue = defaultValue
        self.columnDefinition = columnDefinition
    }

    public var quotedName: String {
        name.quote(#"""#)
    }

    public var definition: String {
        if let columnDefinition {
            // definition override
            return columnDefinition
        }
        var def = quotedName + " " + type.typeName
        if primaryKey {
            def += " PRIMARY KEY"
        }
        if autoincrement {
            def += " AUTOINCREMENT"
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

public extension SQLCodable {
    /// Returns the values for the primary key columns, if any
    var primaryKeyValues: [SQLValue] {
        // force unwrap because binding failing for a primary key value should be considered a programming error
        type(of: self).columns.filter(\.primaryKey).map({ try! self.binding(forColumn: $0) })
    }

    static func selectSQL(alias: String? = nil) -> SQLExpression {
        let aliasName = alias == nil ? "" : alias!
        let aliasSuffix = alias == nil ? "" : (" " + aliasName)
        let aliasPrefix = alias == nil ? "" : (aliasName + ".")

        var sql = "SELECT "
        sql += columns.map({ aliasPrefix + $0.quotedName }).joined(separator: ", ")
        sql += " FROM "
        sql += tableName.quote()
        sql += aliasSuffix

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

    func insertSQL(upsert: Bool, explicitNulls: Bool = false) throws -> SQLExpression {
        let allColumns = type(of: self).columns
        let allBindings = try allColumns.map({ try self.binding(forColumn: $0) })
        var columns: [SQLColumn] = []
        var bindings: [SQLValue] = []
        if explicitNulls {
            columns = allColumns
            bindings = allBindings
        } else {
            // filter out any NULL values so that defaults defined in the column are used
            for (col, value) in zip(allColumns, allBindings) {
                if value == .null {
                    continue
                }
                columns.append(col)
                bindings.append(value)
            }
        }

        var sql = "INSERT INTO \(type(of: self).tableName) ("
        sql += columns.map({ $0.quotedName }).joined(separator: ", ")
        sql += ") VALUES ("
        sql += columns.map({ _ in "?" }).joined(separator: ", ")
        sql += ")"
        if upsert, let pkColumn = columns.first(where: { $0.primaryKey == true }) {
            sql += " ON CONFLICT("
            sql += pkColumn.quotedName
            sql += ") DO UPDATE SET"
            for (index, col) in columns.enumerated() {
                if index != 0 {
                    sql += ","
                }
                sql += " " + col.quotedName + " = EXCLUDED." + col.quotedName
            }
        }
        return SQLExpression(sql, bindings)
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

    /// Performs an insert of the given `SQLCodable` instance
    func insert<T: SQLCodable>(_ ob: T, upsert: Bool = false) throws {
        try exec(ob.insertSQL(upsert: upsert))
    }

    /// Performs an insert of the given `SQLCodable` instance and updates it with the expected ROWID for any primary key columns in the instance
    @inline(__always) func inserted<T: SQLCodable>(_ ob: inout T, refresh: Bool = false) throws {
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
        if refresh {
            try self.refresh(&ob)
        }
    }

    /// Reloads the instance from the database to get updated values
    @inline(__always) func refresh<T: SQLCodable>(_ ob: inout T) throws {
        ob = try fetch(T.self, primaryKeys: ob.primaryKeyValues) ?? ob
    }

    @inline(__always) func select<T: SQLCodable>(_ type: T.Type, _ expr: SQLExpression? = nil) throws -> RowCursor<T> {
        // Type parameter 'T' cannot have or inherit a companion object, so it cannot be on the left-hand side of a dot.
        // SKIP REPLACE: val TType = T::class.companionObjectInstance as SQLCodableCompanion
        let TType = T.self
        return RowCursor(statement: try prepare(expr: expr ?? TType.selectSQL()), creator: { row in
            let values = row.rowValues()
            let columns = TType.columns
            let created = try TType.create(withRow: values, fromColumns: columns)
            return created as T
        })
    }

    /// Return the data item with the given primary keys.
    @inline(__always) func fetch<T: SQLCodable>(_ type: T.Type, id primaryKeys: SQLValue...) throws -> T? {
        try self.fetch(type, primaryKeys: primaryKeys)
    }

    /// Return the data item with the given primary keys.
    @inline(__always) func fetch<T: SQLCodable>(_ type: T.Type, primaryKeys: [SQLValue]) throws -> T? {
        // SKIP REPLACE: val TType = T::class.companionObjectInstance as SQLCodableCompanion
        let TType = T.self
        let columns = TType.columns
        let primaryKeyColumns = columns.filter(\.primaryKey)
        let cursor = try self.query(type, with: zip(primaryKeyColumns, primaryKeys).map({ SQLPredicate.equals($0, $1) }))
        defer { cursor.close() }
        return try cursor.makeIterator().next()?.get()
    }

    /// Issue a query for matching values for the given column/value comparison.
    @inline(__always) func query<T: SQLCodable>(_ type: T.Type, alias: String? = nil, with predicates: [SQLPredicate]) throws -> RowCursor<T> {
        // SKIP REPLACE: val TType = T::class.companionObjectInstance as SQLCodableCompanion
        let TType = T.self
        var select = TType.selectSQL(alias: alias)
        select.template += " WHERE "
        SQLPredicate.and(predicates).apply(to: &select)
        return try self.select(type, select)
    }
}

/// A type that can be represented in a SQL Statement
public protocol SQLRepresentable {
    /// Applies the given representation to the SQL statement
    func apply(to expression: inout SQLExpression)
}

extension SQLColumn : SQLRepresentable {
    public func apply(to expression: inout SQLExpression) {
        expression.template += self.quotedName
    }

    public func alias(_ aliasName: String) -> SQLAliasedColumn {
        SQLAliasedColumn(column: self, alias: aliasName)
    }
}

extension SQLValue : SQLRepresentable {
    public func apply(to expression: inout SQLExpression) {
        expression.template += "?"
        expression.bindings += [self]
    }
}

public struct SQLAliasedColumn : SQLRepresentable {
    public var column: SQLColumn
    public var alias: String

    public init(column: SQLColumn, alias: String) {
        self.column = column
        self.alias = alias
    }

    public func apply(to expression: inout SQLExpression) {
        expression.template += alias + "."
        column.apply(to: &expression)
    }
}

public struct SQLPredicate : SQLRepresentable {
    /// Applies the given predicate to the SQL statement
    public let applicator: (inout SQLExpression) -> ()

    public func apply(to expression: inout SQLExpression) {
        applicator(&expression)
    }
}

public extension SQLPredicate {
    private static func compound(conjunction: String, _ predicates: [SQLPredicate]) -> SQLPredicate {
        SQLPredicate { exp in
            if predicates.count > 1 {
                exp.template += "("
            }
            for (index, predicate) in predicates.enumerated() {
                if index > 0 {
                    exp.template += " " + conjunction + " "
                }
                predicate.apply(to: &exp)
            }
            if predicates.count > 1 {
                exp.template += ")"
            }
        }
    }

    static func and(_ predicates: [SQLPredicate]) -> SQLPredicate {
        compound(conjunction: "AND", predicates)
    }

    func and(_ predicates: SQLPredicate...) -> SQLPredicate {
        .and([self] + predicates)
    }

    static func or(_ predicates: [SQLPredicate]) -> SQLPredicate {
        compound(conjunction: "OR", predicates)
    }

    func or(_ predicates: SQLPredicate...) -> SQLPredicate {
        .or([self] + predicates)
    }

    static func not(_ predicate: SQLPredicate) -> SQLPredicate {
        SQLPredicate { exp in
            exp.template += "NOT "
            exp.template += "("
            predicate.apply(to: &exp)
            exp.template += ")"
        }
    }

    static func compare(lhs: SQLRepresentable, op: String, rhs: SQLRepresentable) -> SQLPredicate {
        SQLPredicate { exp in
            lhs.apply(to: &exp)
            exp.template += " " + op + " "
            rhs.apply(to: &exp)
        }
    }

    static func equals(_ lhs: SQLRepresentable, _ rhs: SQLRepresentable) -> SQLPredicate {
        if let rhsValue = rhs as? SQLValue, rhsValue == .null {
            return isNull(lhs)
        } else {
            return compare(lhs: lhs, op: "=", rhs: rhs)
        }
    }

    static func notEquals(_ lhs: SQLRepresentable, _ rhs: SQLRepresentable) -> SQLPredicate {
        if let rhsValue = rhs as? SQLValue, rhsValue == .null {
            return isNotNull(lhs)
        } else {
            return compare(lhs: lhs, op: "<>", rhs: rhs)
        }
    }

    static func lessThan(_ lhs: SQLRepresentable, _ rhs: SQLRepresentable) -> SQLPredicate {
        compare(lhs: lhs, op: "<", rhs: rhs)
    }

    static func lessThanOrEqual(_ lhs: SQLRepresentable, _ rhs: SQLRepresentable) -> SQLPredicate {
        compare(lhs: lhs, op: "<=", rhs: rhs)
    }

    static func greaterThan(_ lhs: SQLRepresentable, _ rhs: SQLRepresentable) -> SQLPredicate {
        compare(lhs: lhs, op: ">", rhs: rhs)
    }

    static func greaterThanOrEqual(_ lhs: SQLRepresentable, _ rhs: SQLRepresentable) -> SQLPredicate {
        compare(lhs: lhs, op: ">=", rhs: rhs)
    }

    static func like(_ lhs: SQLRepresentable, _ rhs: SQLRepresentable) -> SQLPredicate {
        compare(lhs: lhs, op: "LIKE", rhs: rhs)
    }

    static func notLike(_ lhs: SQLRepresentable, _ rhs: SQLRepresentable) -> SQLPredicate {
        compare(lhs: lhs, op: "NOT LIKE", rhs: rhs)
    }

    static func isNull(_ rep: SQLRepresentable) -> SQLPredicate {
        SQLPredicate { exp in
            rep.apply(to: &exp)
            exp.template += " IS NULL"
        }
    }

    static func isNotNull(_ rep: SQLRepresentable) -> SQLPredicate {
        SQLPredicate { exp in
            rep.apply(to: &exp)
            exp.template += " IS NOT NULL"
        }
    }

    static func between(_ rep: SQLRepresentable, min: SQLRepresentable, max: SQLRepresentable) -> SQLPredicate {
        SQLPredicate { exp in
            rep.apply(to: &exp)
            exp.template += " BETWEEN "
            min.apply(to: &exp)
            exp.template += " AND "
            min.apply(to: &exp)
        }
    }

    static func notBetween(_ rep: SQLRepresentable, min: SQLRepresentable, max: SQLRepresentable) -> SQLPredicate {
        SQLPredicate { exp in
            rep.apply(to: &exp)
            exp.template += " NOT BETWEEN "
            min.apply(to: &exp)
            exp.template += " AND "
            min.apply(to: &exp)
        }
    }

    static func `in`(_ rep: SQLRepresentable, _ values: [SQLValue]) -> SQLPredicate {
        SQLPredicate { exp in
            rep.apply(to: &exp)
            exp.template += " IN "
            exp.template += "("
            for (index, value) in values.enumerated() {
                if index > 0 {
                    exp.template += ", "
                }
                value.apply(to: &exp)
            }
            exp.template += ")"
        }
    }

    static func custom(sql: String, bindings: [SQLValue] = []) -> SQLPredicate {
        SQLPredicate { exp in
            exp.template += " " + sql
            exp.bindings += bindings
        }
    }
}

public extension SQLRepresentable {
    func equals(_ rhs: SQLRepresentable) -> SQLPredicate {
        .equals(self, rhs)
    }

    func notEquals(_ rhs: SQLRepresentable) -> SQLPredicate {
        .notEquals(self, rhs)
    }

    func lessThan(_ rhs: SQLRepresentable) -> SQLPredicate {
        .lessThan(self, rhs)
    }

    func lessThanOrEqual(_ rhs: SQLRepresentable) -> SQLPredicate {
        .lessThanOrEqual(self, rhs)
    }

    func greaterThan(_ rhs: SQLRepresentable) -> SQLPredicate {
        .greaterThan(self, rhs)
    }

    func greaterThanOrEqual(_ rhs: SQLRepresentable) -> SQLPredicate {
        .greaterThanOrEqual(self, rhs)
    }

    func like(_ rhs: SQLRepresentable) -> SQLPredicate {
        .like(self, rhs)
    }

    func notLike(_ rhs: SQLRepresentable) -> SQLPredicate {
        .notLike(self, rhs)
    }

    func isNull() -> SQLPredicate {
        .isNull(self)
    }

    func isNotNull() -> SQLPredicate {
        .isNotNull(self)
    }

    func between(min: SQLRepresentable, max: SQLRepresentable) -> SQLPredicate {
        .between(self, min: min, max: max)
    }

    func notBetween(min: SQLRepresentable, max: SQLRepresentable) -> SQLPredicate {
        .notBetween(self, min: min, max: max)
    }

    func `in`(_ values: [SQLValue]) -> SQLPredicate {
        .in(self, values)
    }
}

public enum SQLBindingError : Error {
    case unknownColumn(SQLColumn)
    case nullColumn(SQLColumn)
    case columnValuesMismatch(Int, Int)

    /// Verifies that the value is not null, throwing a `nullColumn` error if it is null.
    public static func checkNonNull<T>(_ value: T?, _ column: SQLColumn) throws -> T {
        guard let value else { throw nullColumn(column) }
        return value
    }
}
