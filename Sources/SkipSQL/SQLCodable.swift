// Copyright 2023–2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
import Foundation
#if SKIP
import kotlin.reflect.full.companionObjectInstance
#endif

/// A type that can be stored and retrieved from a SQL context
public protocol SQLCodable {
    /// The table and columns for this type
    static var table: SQLTable { get }

    /// Create this instance from a map of columns and their values
    init(row: SQLRow, context: SQLContext) throws

    func encode(row: inout SQLRow) throws
}

public typealias SQLRow = [SQLColumn: SQLValue]

/// A representable of a SQL table
public struct SQLTable : Hashable, Sendable {
    public var name: String
    public var columns: [SQLColumn]

    public init(name: String, columns: [SQLColumn]) {
        self.name = name
        self.columns = columns
    }

    public var quotedName: String {
        name.quote(#"""#)
    }

    public func dropTableSQL(ifExists: Bool = false) -> SQLExpression {
        var sql = "DROP TABLE "
        if ifExists {
            sql += "IF EXISTS "
        }
        sql += self.quotedName
        return SQLExpression(sql)
    }
    
    /// Returns the SQL to create this table.
    public func createTableSQL(ifNotExists: Bool = false, clauses additionalClauses: [String] = []) -> SQLExpression {
        var sql = "CREATE TABLE "
        if ifNotExists {
            sql += "IF NOT EXISTS "
        }
        var clauses: [String] = []
        let pkColumns = self.columns.filter(\.primaryKey)
        if pkColumns.count >= 2 {
            // primary key clause added to the end only when there are multiple PKs for the table
            clauses.append("PRIMARY KEY (\(pkColumns.map(\.quotedName).joined(separator: ", ")))")
        }

        let fkColumns = self.columns.filter({ $0.references != nil })
        for fkColumn in fkColumns {
            // add in any foreign key clauses
            if let reference = fkColumn.references {
                clauses.append("FOREIGN KEY (\(fkColumn.quotedName)) REFERENCES \(reference.referencesClause)")
            }
        }

        // finally add any manual clauses that are needed
        clauses += additionalClauses

        sql += self.quotedName
        sql += " ("
        sql += (self.columns.map({ col in
            col.definition(withPrimaryKey: pkColumns.count == 1)
        }) + clauses).joined(separator: ", ")
        sql += ")"

        return SQLExpression(sql)
    }

    /// Returns the SQL to create any indices on this table.
    public func createIndexSQL(ifNotExists: Bool = false) -> [SQLExpression] {
        var stmnts: [SQLExpression] = []
        for column in self.columns {
            if let index = column.index {
                var sql = "CREATE INDEX "
                if ifNotExists {
                    sql += "IF NOT EXISTS "
                }
                sql += index.name.quote()
                sql += " ON "
                sql += self.name.quote()
                sql += "("
                // TODO: compound indices
                sql += column.quotedName
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

    public var quotedName: String {
        name.quote(#"""#)
    }

    func definition(withPrimaryKey: Bool) -> String {
        if let columnDefinition {
            // definition override
            return columnDefinition
        }
        var def = quotedName + " " + type.typeName
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

    public var referencesClause: String {
        var fkClause = self.table.quotedName
        fkClause += "("
        fkClause += self.columns.map(\.quotedName).joined(separator: ", ")
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

public extension SQLCodable {
    /// Returns the encoded row of this instance
    func encodedRow() throws -> SQLRow {
        var row = SQLRow()
        try encode(row: &row)
        return row
    }

    /// Returns the values for the primary key columns, if any
    static var primaryKeyColumns: [SQLColumn] {
        self.table.columns.filter(\.primaryKey)
    }

    /// Returns the values for the primary key columns, if any
    var primaryKeyValues: [SQLValue] {
        get throws {
            let row = try self.encodedRow()
            return type(of: self).primaryKeyColumns.map({ row[$0] ?? .null })
        }
    }

    /// Returns true if this is a new instance without a primary key value assigned, or nil if it is unknown (i.e., no primary key values)
    var isNewInstance: Bool? {
        get throws {
            let pks = try self.primaryKeyValues
            if pks.isEmpty { return nil }
            return pks.allSatisfy({ $0 == .null || $0 == .defaultPrimaryKeyValue })
        }
    }

    static func selectSQL(alias: String? = nil) -> SQLExpression {
        let aliasName = alias == nil ? "" : alias!
        let aliasSuffix = alias == nil ? "" : (" AS " + aliasName)
        let aliasPrefix = alias == nil ? "" : (aliasName + ".")

        var sql = "SELECT "
        sql += self.table.columns.map({ aliasPrefix + $0.quotedName }).joined(separator: ", ")
        sql += " FROM "
        sql += self.table.name.quote()
        sql += aliasSuffix

        return SQLExpression(sql)
    }
}

public extension SQLContext {
    /// Prepares the given SQL as a statement, which can be executed with parameter bindings.
    func prepare(expr: SQLExpression) throws -> SQLStatement {
        let stmnt = try prepare(sql: expr.sql)
        if !expr.bindings.isEmpty {
            try stmnt.bind(parameters: expr.bindings)
        }
        return stmnt
    }

    /// Delete the given instances from the database. Instances must have at least one primary key defined.
    @inline(__always) func delete<T: SQLCodable>(instances: [T]) throws {
        try delete(T.self, where: primaryKeyQuery(instances))
    }

    /// Delete the given instances from the database. Instances must have at least one primary key defined.
    @inline(__always) func delete<T: SQLCodable>(_ type: T.Type, where: SQLPredicate? = nil) throws {
        // SKIP INSERT: val T = T::class.companionObjectInstance as SQLCodableCompanion // needed to access statics in generic constrained type
        var deleteSQL = SQLExpression("DELETE FROM " + T.table.quotedName)
        if let `where` {
            deleteSQL.append(" WHERE ")
            `where`.apply(to: &deleteSQL)
        }
        try exec(deleteSQL)
    }

    /// Returns a predicate that can be used to locate instances based on the primary key(s) of the given instances
    @inline(__always) func primaryKeyQuery<T: SQLCodable>(_ instances: [T]) throws -> SQLPredicate {
        // SKIP INSERT: val T = T::class.companionObjectInstance as SQLCodableCompanion // needed to access statics in generic constrained type
        let tableName = T.table.name
        let pkColumns = T.primaryKeyColumns

        let pkValues = try instances.map({ try $0.primaryKeyValues })

        if pkColumns.isEmpty {
            // we need at least a single primary keys defined
            throw SQLBindingError.noPrimaryKeys(tableName)
        } else if pkColumns.count == 1 {
            let pkColumn = pkColumns[0]
            let pks = pkValues.map({ $0[0] })
            if pks.count == 1 {
                return SQLPredicate.equals(pkColumn, pks[0])
            } else {
                return SQLPredicate.in(pkColumn, pks.map({ $0 }))
            }
        } else {
            if supports(feature: .rowValueInSyntax) {
                let columnsTuple: SQLRepresentable = SQLTuple(columns: pkColumns)
                let valuesTuples: [SQLRepresentable] = pkValues.map({ SQLTuple(values: $0) })
                // multiple primary keys: query based on the tuple
                return SQLPredicate.in(columnsTuple, valuesTuples)
            } else {
                // no support for tuple IN queries, so we need to fall back to: (ID1 = X1 AND ID2 = Y1) OR (ID1 = X2 AND ID2 = Y2)…
                var equalsQueries: [SQLPredicate] = []
                for pkValueTuple in pkValues {
                    let parts = zip(pkColumns, pkValueTuple).map({ $0.equals($1) })
                    equalsQueries.append(SQLPredicate.and(parts))
                }
                return SQLPredicate.or(equalsQueries)
            }
        }
    }

    /// Returns the SQL for an INSERT or UPDATE for the given instance.
    /// - Parameters:
    ///   - upsert: INSERT if false, INSERT … ON CONFLICT if true, UPDATE if nil
    @inline(__always) func insertUpdateSQL<T: SQLCodable>(for instance: T, upsert: Bool? = nil, explicitNulls: Bool = false) throws -> SQLExpression {
        // SKIP INSERT: val T = T::class.companionObjectInstance as SQLCodableCompanion // needed to access statics in generic constrained type
        let tableName = T.table.quotedName
        let allColumns = T.table.columns
        let row = try instance.encodedRow()
        let allBindings = allColumns.map({ row[$0] ?? .null })
        var columns: [SQLColumn] = []
        var bindings: [SQLValue] = []
        let update = upsert == nil

        // filter out any NULL values so that defaults defined in the column are used
        for (col, value) in zip(allColumns, allBindings) {
            if !update {
                if col.primaryKey && col.autoincrement && value == SQLValue.defaultPrimaryKeyValue {
                    // for insert with autoincrement primary key values, filter out zero so that pk fields don't need to be null
                    continue
                }
                if value == SQLValue.null {
                    continue
                }
            }
            columns.append(col)
            bindings.append(value)
        }

        var expression = SQLExpression("")
        if update {
            expression.append("UPDATE \(tableName) SET ")
        } else {
            expression.append("INSERT INTO \(tableName) ")
            expression.append("(")
            expression.append(columns.map(\.quotedName).joined(separator: ", "))
            expression.append(")")
            expression.append(" VALUES ")
            expression.append("(")
        }
        var updateValueCount = 0
        for (col, value) in zip(columns, bindings) {
            if updateValueCount > 0 {
                expression.append(", ")
            }
            if update {
                if !col.primaryKey { // don't bother updating the primary key values, because these don't change
                    expression.append(col.quotedName + " = ")
                    value.apply(to: &expression) // add the "?" and binding
                    updateValueCount += 1
                }
            } else {
                value.apply(to: &expression) // add the "?" and binding
                updateValueCount += 1
            }
        }
        if !update {
            expression.append(")")
        }

        if update == false,
            upsert == true,
            let pkColumn = columns.first(where: { $0.primaryKey == true }) {
            expression.append(" ON CONFLICT(")
            expression.append(pkColumn.quotedName)
            expression.append(") DO UPDATE SET ")
            for (index, col) in columns.enumerated() {
                if index != 0 {
                    expression.append(", ")
                }
                expression.append(col.quotedName + " = EXCLUDED." + col.quotedName)
            }
        } else if update == true {
            expression.append(" WHERE ")
            try primaryKeyQuery([instance]).apply(to: &expression)
        }
        return expression
    }

    /// Performs an update of the given `SQLCodable` instance
    @inline(__always) func update<T: SQLCodable>(_ ob: T) throws {
        try exec(insertUpdateSQL(for: ob, upsert: nil))
    }

    /// Performs an insert of the given `SQLCodable` instance
    @inline(__always) @discardableResult func insert<T: SQLCodable>(_ ob: T, upsert: Bool = false) throws -> T {
        // SKIP INSERT: val T = T::class.companionObjectInstance as SQLCodableCompanion // needed to access statics in generic constrained type
        try exec(insertUpdateSQL(for: ob, upsert: upsert))
        // check for primary key column and update it with the last insert Row ID
        let columns = T.table.columns
        let row = try ob.encodedRow()
        var rowMap = try _createSQLRow(columns, columns.map({ row[$0] ?? .null }))
        var changedFields = 0
        for col in columns {
            if col.primaryKey && col.autoincrement && (row[col] == .null || row[col] == SQLValue.defaultPrimaryKeyValue) {
                // get the last inserted row id and update it in the object
                let lastID = SQLValue(lastInsertRowID)
                if rowMap[col] != lastID {
                    rowMap[col] = lastID
                    changedFields += 1
                }
            } else if let defaultValue = col.defaultValue, row[col] == .null {
                if rowMap[col] != defaultValue {
                    rowMap[col] = defaultValue
                    changedFields += 1
                }
            }
        }
        if changedFields == 0 {
            // if we didn't auto-assign any fields, don't bother re-initializing a new instance just to set the fields again
            return ob
        } else {
            // SKIP NOWARN
            let created = try type(of: ob).init(row: rowMap, context: self) as T
            return created
        }
    }

    /// Performs an insert of the given `SQLCodable` instance and updates it with the expected ROWID for any primary key columns in the instance
    @inline(__always) func inserted<T: SQLCodable>(_ ob: inout T, refresh: Bool = false) throws {
        ob = try insert(ob, upsert: false)
        if refresh {
            // TODO: this could be changed to use a "RETURNING *" clause to get the inserted rows back in a single statement, but "RETURNING" is only available in SQLite 3.35.0 (iOS 15/Android 14 API 34), so we would need to gracefully fallback to this implementation for older OSs.
            try self.refresh(&ob)
        }
    }

    /// Reloads the instance from the database to get updated values
    @inline(__always) func refresh<T: SQLCodable>(_ ob: inout T) throws {
        ob = try fetch(T.self, primaryKeys: ob.primaryKeyValues) ?? ob
    }

    private func selectQuery<T: SQLCodable>(_ type: T.Type, _ expr: SQLExpression? = nil) throws -> RowCursor<T> {
        let columns = type.table.columns
        return RowCursor(statement: try prepare(expr: expr ?? type.selectSQL()), creator: { row in
            // SKIP NOWARN
            let created: T = try type.init(row: _createSQLRow(columns, row.rowValues()), context: self) as T
            return created
        })
    }

    /// Return the data item with the given primary keys.
    func fetch<T: SQLCodable>(_ type: T.Type, id primaryKeys: SQLValue...) throws -> T? {
        try self.fetch(type, primaryKeys: primaryKeys)
    }

    /// Return the data item with the given primary keys.
    func fetch<T: SQLCodable>(_ type: T.Type, primaryKeys: [SQLValue]) throws -> T? {
        let columns = type.table.columns
        let primaryKeyColumns = columns.filter(\.primaryKey)
        let cursor = try self.query(type, where: .and(zip(primaryKeyColumns, primaryKeys).map({ SQLPredicate.equals($0, $1) })))
        defer { cursor.close() }
        return try cursor.makeIterator().next()?.get()
    }

    /// Issue a query for matching values for the given column/value comparison.
    func query<T: SQLCodable>(_ type: T.Type, _ alias: String? = nil, where predicate: SQLPredicate? = nil, orderBy: [(SQLRepresentable, SQLOrder)] = [], limit: Int? = nil, offset: Int? = nil) throws -> RowCursor<T> {
        var select = type.selectSQL(alias: alias)
        applyClauses(to: &select, where: predicate, orderBy: orderBy, limit: limit, offset: offset)
        return try self.selectQuery(type, select)
    }

    internal func joinQuery(tableAliases: [(SQLTable, String?)], joins: [SQLJoinType], onColumns: [SQLColumn?], where: SQLPredicate?, orderBy: [(SQLRepresentable, SQLOrder)] = [], limit: Int? = nil, offset: Int? = nil) throws -> SQLExpression {
        var sql = "SELECT "

        var selectColumns: [String] = []
        for tableAliase in tableAliases {
            selectColumns += tableAliase.0.columns.map({ (tableAliase.1?.appendingString(".") ?? "") + $0.quotedName })
        }

        sql += selectColumns.joined(separator: ", ")
        sql += " FROM "

        var select = SQLExpression(sql)

        for (index, tableAlias) in tableAliases.enumerated() {
            let table = tableAlias.0
            let alias = tableAlias.1
            if index > 0 {
                select.append(" " + joins[index - 1].joinClause + " ")
            }
            select.append(table.quotedName)
            if let alias {
                select.append(" AS " + alias)
            }
            if index > 0 {
                let onColumn = onColumns[index - 1]
                if let onColumn {
                    let previousTable = tableAliases[index - 1].0
                    let previousAlias = tableAliases[index - 1].1
                    var joinPredicates: [SQLPredicate] = []

                    // scan the columns on each side of the table for foreign keys that match the other table
                    if let reference = onColumn.references {
                        for refColumn in reference.columns {
                            // if aliases are null, we will disambiguate the columns by referencing them with the table name
                            let palias = previousAlias ?? previousTable.quotedName
                            let talias = alias ?? table.quotedName
                            let isPreviousRef = previousTable == reference.table && previousTable.columns.contains(refColumn)
                            let col1 = refColumn.alias(isPreviousRef ? palias : talias)
                            let col2 = onColumn.alias(isPreviousRef ? talias : palias)
                            // only equijoins are currently supported
                            joinPredicates.append(SQLPredicate.equals(col1, col2))
                        }
                    }
                    if !joinPredicates.isEmpty {
                        select.append(" ON ")
                        SQLPredicate.and(joinPredicates).apply(to: &select)
                    }
                }
            }
        }

        applyClauses(to: &select, where: `where`, orderBy: orderBy, limit: limit, offset: offset)
        return select
    }

    func applyClauses(to select: inout SQLExpression, where predicate: SQLPredicate?, orderBy: [(SQLRepresentable, SQLOrder)], limit: Int?, offset: Int?) {
        if let predicate {
            select.append(" WHERE ")
            predicate.apply(to: &select)
        }
        if !orderBy.isEmpty {
            select.append(" ORDER BY ")
            for (index, columnDirection) in orderBy.enumerated() {
                if index > 0 {
                    select.append(", ")
                }
                columnDirection.0.apply(to: &select)
                select.append(" " + (columnDirection.1.orderClause))
            }
        }

        if let limit {
            select.append(" LIMIT \(limit)")
        }

        if let offset {
            select.append(" OFFSET \(offset)")
        }
    }

    /// Performs a query with a 2-way join.
    /// - Parameters:
    ///   - type1: the first SQLCodable type
    ///   - join: the join between the first and second table
    ///   - type2: the second SQLCodable type
    ///   - where: a WHERE clause
    /// - Returns: a RowCursor that deserializes into the instance types
    func query<T1: SQLCodable, T2: SQLCodable>(_ type1: T1.Type, _ alias1: String?, join: SQLJoinType, on: SQLColumn?, _ type2: T2.Type, _ alias2: String?, where: SQLPredicate? = nil, orderBy: [(SQLRepresentable, SQLOrder)] = []) throws -> RowCursor<(T1?, T2?)> {
        let columns1 = type1.table.columns
        let c1c = columns1.count
        let columns2 = type2.table.columns
        let c2c = columns2.count

        let select = try joinQuery(tableAliases: [(type1.table, alias1), (type2.table, alias2)], joins: [join], onColumns: [on], where: `where`, orderBy: orderBy)
        return RowCursor(statement: try prepare(expr: select), creator: { row in
            let values = row.rowValues()

            let values1 = Array(values[0..<c1c])
            // SKIP NOWARN
            let created1 = _areAllNull(values1) ? nil : (try type1.init(row: _createSQLRow(columns1, values1), context: self) as T1)

            let values2 = Array(values[c1c..<c1c + c2c])
            // SKIP NOWARN
            let created2 = _areAllNull(values2) ? nil : (try type2.init(row: _createSQLRow(columns2, values2), context: self) as T2)

            return (created1 as T1?, created2 as T2?)
        })
    }
    
    /// Performs a query with a 3-way join.
    /// - Parameters:
    ///   - type1: the first SQLCodable type
    ///   - join1: the join between the first and second table
    ///   - type2: the second SQLCodable type
    ///   - join2: the join between the second and third table
    ///   - type3: the thid SQLCodable type
    ///   - where: a WHERE clause
    /// - Returns: a RowCursor that deserializes into the instance types
    func query<T1: SQLCodable, T2: SQLCodable, T3: SQLCodable>(_ type1: T1.Type, _ alias1: String, join1: SQLJoinType, on1: SQLColumn?, _ type2: T2.Type, _ alias2: String, join2: SQLJoinType, on2: SQLColumn?, _ type3: T3.Type, _ alias3: String, where: SQLPredicate? = nil, orderBy: [(SQLRepresentable, SQLOrder)] = []) throws -> RowCursor<(T1?, T2?, T3?)> {
        let columns1 = type1.table.columns
        let c1c = columns1.count
        let columns2 = type2.table.columns
        let c2c = columns2.count
        let columns3 = type3.table.columns
        let c3c = columns3.count

        let select = try joinQuery(tableAliases: [(type1.table, alias1), (type2.table, alias2), (type3.table, alias3)], joins: [join1, join2], onColumns: [on1, on2], where: `where`, orderBy: orderBy)
        return RowCursor(statement: try prepare(expr: select), creator: { row in
            let values = row.rowValues()

            let values1 = Array(values[0..<c1c])
            // SKIP NOWARN
            let created1 = _areAllNull(values1) ? nil : (try type1.init(row: _createSQLRow(columns1, values1), context: self) as T1)

            let values2 = Array(values[c1c..<c1c + c2c])
            // SKIP NOWARN
            let created2 = _areAllNull(values2) ? nil : (try type2.init(row: _createSQLRow(columns2, values2), context: self) as T2)

            let values3 = Array(values[c1c + c2c..<c1c + c2c + c3c])
            // SKIP NOWARN
            let created3 = _areAllNull(values3) ? nil : (try type3.init(row: _createSQLRow(columns3, values3), context: self) as T3)

            return (created1 as T1?, created2 as T2?, created3 as T3?)
        })
    }

    /// Performs a query with a 4-way join.
    /// - Parameters:
    ///   - type1: the first SQLCodable type
    ///   - join1: the join between the first and second table
    ///   - type2: the second SQLCodable type
    ///   - join2: the join between the second and third table
    ///   - type3: the thid SQLCodable type
    ///   - join3: the join between the third and fourth table
    ///   - type4: the fourth SQLCodable type
    ///   - where: a WHERE clause
    /// - Returns: a RowCursor that deserializes into the instance types
    func query<T1: SQLCodable, T2: SQLCodable, T3: SQLCodable, T4: SQLCodable>(_ type1: T1.Type, _ alias1: String, join1: SQLJoinType, on1: SQLColumn?, _ type2: T2.Type, _ alias2: String, join2: SQLJoinType, on2: SQLColumn?, _ type3: T3.Type, _ alias3: String, join3: SQLJoinType, on3: SQLColumn?, _ type4: T4.Type, _ alias4: String, where: SQLPredicate? = nil, orderBy: [(SQLRepresentable, SQLOrder)] = []) throws -> RowCursor<(T1?, T2?, T3?, T4?)> {
        let columns1 = type1.table.columns
        let c1c = columns1.count
        let columns2 = type2.table.columns
        let c2c = columns2.count
        let columns3 = type3.table.columns
        let c3c = columns3.count
        let columns4 = type4.table.columns
        let c4c = columns4.count

        let select = try joinQuery(tableAliases: [(type1.table, alias1), (type2.table, alias2), (type3.table, alias3), (type4.table, alias4)], joins: [join1, join2, join3], onColumns: [on1, on2, on3], where: `where`, orderBy: orderBy)
        return RowCursor(statement: try prepare(expr: select), creator: { row in
            let values = row.rowValues()

            let values1 = Array(values[0..<c1c])
            // SKIP NOWARN
            let created1 = _areAllNull(values1) ? nil : (try type1.init(row: _createSQLRow(columns1, values1), context: self) as T1)

            let values2 = Array(values[c1c..<c1c + c2c])
            // SKIP NOWARN
            let created2 = _areAllNull(values2) ? nil : (try type2.init(row: _createSQLRow(columns2, values2), context: self) as T2)

            let values3 = Array(values[c1c + c2c..<c1c + c2c + c3c])
            // SKIP NOWARN
            let created3 = _areAllNull(values3) ? nil : (try type3.init(row: _createSQLRow(columns3, values3), context: self) as T3)

            let values4 = Array(values[c1c + c2c + c3c..<c1c + c2c + c3c + c4c])
            // SKIP NOWARN
            let created4 = _areAllNull(values4) ? nil : (try type4.init(row: _createSQLRow(columns4, values4), context: self) as T4)

            return (created1 as T1?, created2 as T2?, created3 as T3?, created4 as T4?)
        })
    }
}

/// Create a rwo from the list of columns and values.
public func _createSQLRow(_ columns: [SQLColumn], _ values: [SQLValue]) throws -> SQLRow {
    SQLRow(uniqueKeysWithValues: zip(columns, values))
}

/// Returns true is all the values in the list are null
public func _areAllNull(_ values: [SQLValue]) -> Bool {
    // needs to be public for the reified Kotlin side
    values.first(where: { $0 != .null }) == nil
}

/// A type that can be represented in a SQL Statement
public protocol SQLRepresentable {
    /// Applies the given representation to the SQL statement
    func apply(to expression: inout SQLExpression)
}

extension SQLColumn : SQLRepresentable {
    public func apply(to expression: inout SQLExpression) {
        expression.append(self.quotedName)
    }

    public func alias(_ aliasName: String) -> SQLAliasedColumn {
        SQLAliasedColumn(column: self, alias: aliasName)
    }
}

extension SQLValue : SQLRepresentable {
    /// The empty primary key value, signifying that the primary key should be assigned
    public static let defaultPrimaryKeyValue = SQLValue.long(0)

    public func apply(to expression: inout SQLExpression) {
        expression.append("?", self)
    }
}

/// A list of multiple `SQLRepresentable`s expressed as a tuple.
public struct SQLTuple : SQLRepresentable {
    public var representations: [SQLRepresentable]

    public init(_ representations: [SQLRepresentable]) {
        self.representations = representations
    }

    public init(columns: [SQLColumn]) {
        self.representations = columns.map({ $0 as SQLRepresentable }) // needed to help Kotlin contravariant array
    }

    public init(values: [SQLValue]) {
        self.representations = values.map({ $0 as SQLRepresentable }) // needed to help Kotlin contravariant array
    }

    public func apply(to expression: inout SQLExpression) {
        expression.append("(")
        for (index, rep) in representations.enumerated() {
            if index > 0 {
                expression.append(", ")
            }
            rep.apply(to: &expression)
        }
        expression.append(")")
    }
}

/// A column with an alias.
public struct SQLAliasedColumn : SQLRepresentable {
    public var column: SQLColumn
    public var alias: String

    public init(column: SQLColumn, alias: String) {
        self.column = column
        self.alias = alias
    }

    public func apply(to expression: inout SQLExpression) {
        expression.append(alias + ".")
        column.apply(to: &expression)
    }
}

public enum SQLOrder {
    case ascending
    case descending

    public var orderClause: String {
        switch self {
        case .ascending: return "ASC"
        case .descending: return "DESC"
        }
    }
}

/// A type of join
public enum SQLJoinType {
    case left
    case right // needs 3.39.0+
    case full // needs 3.39.0+
    case inner
    case cross

    public var joinClause: String {
        switch self {
        case .left: return "LEFT OUTER JOIN"
        case .right: return "RIGHT OUTER JOIN"
        case .full: return "FULL OUTER JOIN"
        case .inner: return "INNER JOIN"
        case .cross: return "CROSS JOIN"
        }
    }
}

internal struct SQLJoinClause {
    let aliases: [String]
    let columns: [SQLColumn?]
    let joinType: SQLJoinType

    init(aliases: [String], columns: [SQLColumn?], joinType: SQLJoinType) {
        self.aliases = aliases
        self.columns = columns
        self.joinType = joinType
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
                exp.append("(")
            }
            for (index, predicate) in predicates.enumerated() {
                if index > 0 {
                    exp.append(" " + conjunction + " ")
                }
                predicate.apply(to: &exp)
            }
            if predicates.count > 1 {
                exp.append(")")
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
            exp.append("NOT ")
            exp.append("(")
            predicate.apply(to: &exp)
            exp.append(")")
        }
    }

    static func compare(lhs: SQLRepresentable, op: String, rhs: SQLRepresentable) -> SQLPredicate {
        SQLPredicate { exp in
            lhs.apply(to: &exp)
            exp.append(" " + op + " ")
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
            exp.append(" IS NULL")
        }
    }

    static func isNotNull(_ rep: SQLRepresentable) -> SQLPredicate {
        SQLPredicate { exp in
            rep.apply(to: &exp)
            exp.append(" IS NOT NULL")
        }
    }

    static func between(_ rep: SQLRepresentable, min: SQLRepresentable, max: SQLRepresentable) -> SQLPredicate {
        SQLPredicate { exp in
            rep.apply(to: &exp)
            exp.append(" BETWEEN ")
            min.apply(to: &exp)
            exp.append(" AND ")
            min.apply(to: &exp)
        }
    }

    static func notBetween(_ rep: SQLRepresentable, min: SQLRepresentable, max: SQLRepresentable) -> SQLPredicate {
        SQLPredicate { exp in
            rep.apply(to: &exp)
            exp.append(" NOT BETWEEN ")
            min.apply(to: &exp)
            exp.append(" AND ")
            min.apply(to: &exp)
        }
    }

    static func `in`(_ rep: SQLRepresentable, _ values: [SQLRepresentable]) -> SQLPredicate {
        SQLPredicate { exp in
            rep.apply(to: &exp)
            exp.append(" IN ")
            exp.append("(")
            for (index, value) in values.enumerated() {
                if index > 0 {
                    exp.append(", ")
                }
                value.apply(to: &exp)
            }
            exp.append(")")
        }
    }

    static func custom(sql: String, bindings: [SQLValue] = []) -> SQLPredicate {
        SQLPredicate { exp in
            exp.append(" " + sql)
            for binding in bindings {
                exp.append("", binding)
            }
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

    func `in`(_ values: [SQLRepresentable]) -> SQLPredicate {
        .in(self, values)
    }
}

public enum SQLBindingError : Error {
    case unknownColumn(SQLColumn)
    case nullColumn(SQLColumn)
    case columnValuesMismatch(Int, Int)
    case noPrimaryKeys(String)

    /// Verifies that the value is not null, throwing a `nullColumn` error if it is null.
    public static func checkNonNull<T>(_ value: T?, _ column: SQLColumn) throws -> T {
        guard let value else { throw nullColumn(column) }
        return value
    }
}

public extension SQLColumn {
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
}
