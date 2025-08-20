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

    static func construct(row: SQLRow, context: SQLContext) throws -> Self {
        // this is needed because `init` is treated special by the transpiler in a way that breaks its invocation on a reified type
        // SKIP REPLACE: return init(row = row, context = context)
        try self.init(row: row, context: context)
    }

    static func selectSQL(alias: String? = nil) -> SQLExpression {
        var sql = "SELECT "
        sql += self.table.columns.map({ $0.quotedName(alias: alias) }).joined(separator: ", ")
        sql += " FROM "
        // permit the table name to have a bound parameter so we can select from things like `pragma_table_info(?)`
        sql += self.table.name.contains("?") ? self.table.name : self.table.name.quote()
        if let alias {
            sql += " AS " + alias
        }
        return SQLExpression(sql)
    }
}

// SKIP NOWARN
public extension SQLContext {
    /// Prepares the given SQL as a statement, which can be executed with parameter bindings.
    func prepare(expr: SQLExpression) throws -> SQLStatement {
        let stmnt = try prepare(sql: expr.sql)
        if !expr.bindings.isEmpty {
            try stmnt.bind(parameters: expr.bindings)
        }
        return stmnt
    }

    func count<T: SQLCodable>(_ type: T.Type, inSchema schemaName: String? = nil, where: SQLPredicate? = nil) throws -> Int64 {
        var countSQL = SQLExpression("SELECT COUNT(*) FROM " + type.table.quotedName(inSchema: schemaName))
        if let `where` {
            countSQL.append(" WHERE ")
            `where`.apply(to: &countSQL)
        }
        return try cursor(countSQL).map({ try $0.get() }).first?.first?.longValue ?? 0
    }

    /// Delete the given instances from the database. Instances must have at least one primary key defined.
    @inline(__always) func delete<T: SQLCodable>(instances: [T]) throws {
        try delete(T.self, where: primaryKeyQuery(instances))
    }

    /// Delete the given instances from the database. Instances must have at least one primary key defined.
    func delete<T: SQLCodable>(_ type: T.Type, inSchema schemaName: String? = nil, where: SQLPredicate? = nil) throws {
        var deleteSQL = SQLExpression("DELETE FROM " + type.table.quotedName(inSchema: schemaName))
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
    @inline(__always) func insertUpdateSQL<T: SQLCodable>(for instance: T, inSchema schemaName: String?, upsert: Bool? = nil, explicitNulls: Bool = false) throws -> SQLExpression {
        // SKIP INSERT: val T = T::class.companionObjectInstance as SQLCodableCompanion // needed to access statics in generic constrained type
        let tableName = T.table.quotedName(inSchema: schemaName)
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
            expression.append(columns.map({ $0.quotedName() }).joined(separator: ", "))
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
                    expression.append(col.quotedName() + " = ")
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

        let pkColumns = T.primaryKeyColumns
        if update == false, upsert == true, !pkColumns.isEmpty {
            expression.append(" ON CONFLICT(")
            expression.append(pkColumns.map({ $0.quotedName() }).joined(separator: ", "))
            expression.append(") DO UPDATE SET ")
            for (index, col) in columns.enumerated() {
                if index != 0 {
                    expression.append(", ")
                }
                expression.append(col.quotedName() + " = " + col.quotedName(alias: "EXCLUDED"))
            }
        } else if update == true {
            expression.append(" WHERE ")
            try primaryKeyQuery([instance]).apply(to: &expression)
        }
        return expression
    }

    /// Performs an update of the given `SQLCodable` instance
    @inline(__always) func update<T: SQLCodable>(_ ob: T, inSchema schemaName: String? = nil) throws {
        try exec(insertUpdateSQL(for: ob, inSchema: schemaName, upsert: nil))
    }

    /// Performs an insert of the given `SQLCodable` instance
    @inline(__always) @discardableResult func insert<T: SQLCodable>(_ ob: T, inSchema schemaName: String? = nil, upsert: Bool = false) throws -> T {
        // SKIP INSERT: val T = T::class.companionObjectInstance as SQLCodableCompanion // needed to access statics in generic constrained type
        try exec(insertUpdateSQL(for: ob, inSchema: schemaName, upsert: upsert))
        // check for primary key column and update it with the last insert Row ID
        let columns = T.table.columns
        let row = try ob.encodedRow()
        var rowMap = try _createSQLRow(columns, columns.map({ row[$0] ?? .null }))
        var changedFields = 0
        for col in columns {
            if col.primaryKey && (row[col] == .null || (col.autoincrement && row[col] == SQLValue.defaultPrimaryKeyValue)) {
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
        let cursor = try self.issueQuery(type, where: .and(zip(primaryKeyColumns, primaryKeys).map({ SQLPredicate.equals($0, $1) })))
        defer { cursor.close() }
        return try cursor.makeIterator().next()?.get()
    }

    /// Issue a query for matching values for the given column/value comparison.
    internal func issueQuery<T: SQLCodable>(_ type: T.Type, _ alias: String? = nil, where predicate: SQLPredicate? = nil, orderBy: [(SQLRepresentable, SQLOrder)] = [], limit: Int? = nil, offset: Int? = nil) throws -> RowCursor<T> {
        var select = type.selectSQL(alias: alias)
        applyClauses(to: &select, whereClauses: predicate.map({ [$0] }) ?? [], orderBy: orderBy, limit: limit, offset: offset)
        return try self.selectQuery(type, select)
    }

    internal func _assembleQuery(tables tableAliases: [QualifiedTable], joins: [SQLJoinType], onColumns: [SQLColumn?], whereClauses: [SQLPredicate], orderBy: [(SQLRepresentable, SQLOrder)] = [], limit: Int? = nil, offset: Int? = nil) throws -> SQLExpression {
        var sql = "SELECT "

        var selectColumns: [String] = []
        for tableAlias in tableAliases {
            selectColumns += tableAlias.table.columns.map({ $0.quotedName(alias: tableAlias.alias) })
        }

        sql += selectColumns.joined(separator: ", ")
        sql += " FROM "

        var select = SQLExpression(sql)

        for (index, tableAlias) in tableAliases.enumerated() {
            let table = tableAlias.table
            let alias = tableAlias.alias
            let schemaName = tableAlias.schema
            if index > 0 {
                select.append(" " + joins[index - 1].joinClause + " ")
            }
            select.append(table.quotedName(inSchema: schemaName))
            if let alias {
                select.append(" AS " + alias)
            }
            if index > 0 {
                let onColumn = onColumns[index - 1]
                if let onColumn {
                    let previousTable = tableAliases[index - 1].table
                    let previousAlias = tableAliases[index - 1].alias
                    let previousSchema = tableAliases[index - 1].schema
                    var joinPredicates: [SQLPredicate] = []

                    // scan the columns on each side of the table for foreign keys that match the other table
                    if let reference = onColumn.references {
                        for refColumn in reference.columns {
                            // if aliases are null, we will disambiguate the columns by referencing them with the table name
                            let palias = previousAlias ?? previousTable.quotedName(inSchema: previousSchema)
                            let talias = alias ?? table.quotedName(inSchema: schemaName)
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

        applyClauses(to: &select, whereClauses: whereClauses, orderBy: orderBy, limit: limit, offset: offset)
        return select
    }

    internal func applyClauses(to select: inout SQLExpression, whereClauses: [SQLPredicate], orderBy: [(SQLRepresentable, SQLOrder)], limit: Int?, offset: Int?) {
        if !whereClauses.isEmpty {
            select.append(" WHERE ")
            SQLPredicate.and(whereClauses).apply(to: &select)
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

/// A table descriptor that includes an optional alias and schema name
struct QualifiedTable {
    var table: SQLTable
    var alias: String?
    var schema: String?

    init(table: SQLTable, alias: String?, schema: String?) {
        self.table = table
        self.alias = alias
        self.schema = schema
    }
}

public extension SQLContext {
    /// Create a query against the specified type with the optional alias and schema.
    func query<T: SQLCodable>(_ type: T.Type, alias: String? = nil, schema: String? = nil) -> SQLTableQuery<T> {
        SQLTableQuery<T>(type: type, table: type.table, alias: alias, schema: schema, context: self)
    }
}

public protocol SQLQuery {
    var context: SQLContext { get }
}

/// A query against a single `SQLCodable` type
public struct SQLTableQuery<T: SQLCodable> : SQLQuery {
    let type: T.Type
    let qtable: QualifiedTable
    var whereClauses: [SQLPredicate]
    var orderByColumns: [(SQLRepresentable, SQLOrder)]
    var limit: Int?
    var offset: Int?
    public let context: SQLContext

    init(type: T.Type, table: SQLTable, alias: String? = nil, schema: String? = nil, context: SQLContext) {
        self.type = type
        self.qtable = QualifiedTable(table: table, alias: alias, schema: schema)
        self.context = context
        self.whereClauses = []
        self.orderByColumns = []
        self.limit = nil
        self.offset = nil
    }

    public func join<T2: SQLCodable>(_ to: T2.Type, alias: String? = nil, schema: String? = nil, kind: SQLJoinType, on joinColumn: SQLColumn?) -> SQLJoin2Query<T, T2> {
        SQLJoin2Query<T, T2>(type: to, base: self, kind: kind, table: to.table, joinColumn: joinColumn, alias: alias, schema: schema)
    }

    public func `where`(_ whereClause: SQLPredicate?) -> Self {
        guard let whereClause else { return self }
        var q = self
        q.whereClauses.append(whereClause)
        return q
    }

    public func orderBy(_ orderBy: SQLRepresentable, order: SQLOrder = .ascending) -> Self {
        var q = self
        q.orderByColumns.append((orderBy, order))
        return q
    }

    public func limit(_ limit: Int, offset: Int? = nil) -> Self {
        var q = self
        q.limit = limit
        q.offset = offset
        return q
    }

    /// Shorthand for `eval().load()`
    public func load() throws -> [T] {
        try eval().load()
    }

    public func eval() throws -> RowCursor<T> {
        let table = self.qtable

        let columns1 = table.table.columns
        let c1c = columns1.count

        let select = try context._assembleQuery(tables: [table], joins: [], onColumns: [], whereClauses: whereClauses, orderBy: orderByColumns, limit: limit, offset: offset)
        return RowCursor(statement: try context.prepare(expr: select), creator: { row in
            let values = row.rowValues()
            let values1 = Array(values[0..<c1c])
            return try type.construct(row: _createSQLRow(columns1, values1), context: context) as T
        })
    }
}

/// A query joining two `SQLCodable` types
public struct SQLJoin2Query<T1: SQLCodable, T2: SQLCodable> : SQLQuery {
    let type: T2.Type
    let qtable: QualifiedTable
    var base: SQLTableQuery<T1>
    let kind: SQLJoinType
    let joinColumn: SQLColumn?

    init(type: T2.Type, base: SQLTableQuery<T1>, kind: SQLJoinType, table: SQLTable, joinColumn: SQLColumn?, alias: String? = nil, schema: String? = nil) {
        self.type = type
        self.qtable = QualifiedTable(table: table, alias: alias, schema: schema)
        self.base = base
        self.kind = kind
        self.joinColumn = joinColumn
    }

    public var context: SQLContext {
        base.context
    }

    public func join<T3: SQLCodable>(_ to: T3.Type, alias: String? = nil, schema: String? = nil, kind: SQLJoinType, on joinColumn: SQLColumn?) -> SQLJoin3Query<T1, T2, T3> {
        SQLJoin3Query<T1, T2, T3>(type: to, base: self, kind: kind, table: to.table, joinColumn: joinColumn, alias: alias, schema: schema)
    }

    public func `where`(_ whereClause: SQLPredicate?) -> Self {
        guard let whereClause else { return self }
        var q = self
        q.base.whereClauses.append(whereClause)
        return q
    }

    public func orderBy(_ orderBy: SQLRepresentable, order: SQLOrder = .ascending) -> Self {
        var q = self
        q.base = q.base.orderBy(orderBy, order: order)
        return q
    }

    public func limit(_ limit: Int, offset: Int? = nil) -> Self {
        var q = self
        q.base.limit = limit
        q.base.offset = offset
        return q
    }

    /// Shorthand for `eval().load()`
    public func load() throws -> [(T1?, T2?)] {
        try eval().load()
    }

    public func eval() throws -> RowCursor<(T1?, T2?)> {
        let table1 = base.qtable
        let table2 = self.qtable

        let columns1 = table1.table.columns
        let c1c = columns1.count
        let columns2 = table2.table.columns
        let c2c = columns2.count

        let select = try context._assembleQuery(tables: [table1, table2], joins: [kind], onColumns: [joinColumn], whereClauses: base.whereClauses, orderBy: base.orderByColumns, limit: base.limit, offset: base.offset)
        return RowCursor(statement: try context.prepare(expr: select), creator: { row in
            let values = row.rowValues()

            let values1 = Array(values[0..<c1c])
            let created1 = _areAllNull(values1) ? nil : (try base.type.construct(row: _createSQLRow(columns1, values1), context: context) as T1)

            let values2 = Array(values[c1c..<c1c + c2c])
            let created2 = _areAllNull(values2) ? nil : (try self.type.construct(row: _createSQLRow(columns2, values2), context: context) as T2)

            return (created1 as T1?, created2 as T2?)
        })
    }
}

/// A query joining three `SQLCodable` types
public struct SQLJoin3Query<T1: SQLCodable, T2: SQLCodable, T3: SQLCodable> : SQLQuery {
    let type: T3.Type
    let qtable: QualifiedTable
    var base: SQLJoin2Query<T1, T2>
    let kind: SQLJoinType
    let joinColumn: SQLColumn?

    init(type: T3.Type, base: SQLJoin2Query<T1, T2>, kind: SQLJoinType, table: SQLTable, joinColumn: SQLColumn?, alias: String? = nil, schema: String? = nil) {
        self.type = type
        self.qtable = QualifiedTable(table: table, alias: alias, schema: schema)
        self.base = base
        self.kind = kind
        self.joinColumn = joinColumn
    }

    public var context: SQLContext {
        base.context
    }

    public func `where`(_ whereClause: SQLPredicate?) -> Self {
        guard let whereClause else { return self }
        var q = self
        q.base.base.whereClauses.append(whereClause)
        return q
    }

    public func orderBy(_ orderBy: SQLRepresentable, order: SQLOrder = .ascending) -> Self {
        var q = self
        q.base.base = q.base.base.orderBy(orderBy, order: order)
        return q
    }

    public func limit(_ limit: Int, offset: Int? = nil) -> Self {
        var q = self
        q.base.base.limit = limit
        q.base.base.offset = offset
        return q
    }

    /// Shorthand for `eval().load()`
    public func load() throws -> [(T1?, T2?, T3?)] {
        try eval().load()
    }

    public func eval() throws -> RowCursor<(T1?, T2?, T3?)> {
        let table1 = base.base.qtable
        let table2 = base.qtable
        let table3 = self.qtable

        let columns1 = table1.table.columns
        let c1c = columns1.count
        let columns2 = table2.table.columns
        let c2c = columns2.count
        let columns3 = table3.table.columns
        let c3c = columns3.count

        let select = try context._assembleQuery(tables: [table1, table2, table3], joins: [base.kind, kind], onColumns: [base.joinColumn, joinColumn], whereClauses: base.base.whereClauses, orderBy: base.base.orderByColumns, limit: base.base.limit, offset: base.base.offset)
        return RowCursor(statement: try context.prepare(expr: select), creator: { row in
            let values = row.rowValues()

            let values1 = Array(values[0..<c1c])
            let created1 = _areAllNull(values1) ? nil : (try base.base.type.construct(row: _createSQLRow(columns1, values1), context: context) as T1)

            let values2 = Array(values[c1c..<c1c + c2c])
            let created2 = _areAllNull(values2) ? nil : (try base.type.construct(row: _createSQLRow(columns2, values2), context: context) as T2)

            let values3 = Array(values[c1c + c2c..<c1c + c2c + c3c])
            let created3 = _areAllNull(values3) ? nil : (try self.type.construct(row: _createSQLRow(columns3, values3), context: context) as T3)

            return (created1 as T1?, created2 as T2?, created3 as T3?)
        })
    }
}

/// A type that can be represented in a SQL Statement
public protocol SQLRepresentable {
    /// Applies the given representation to the SQL statement
    func apply(to expression: inout SQLExpression)
}

// SKIP NOWARN // "This extension will be moved into its extended type definition when translated to Kotlin. It will not be able to access this file's private types or fileprivate members"
extension SQLColumn : SQLRepresentable {
    public func apply(to expression: inout SQLExpression) {
        expression.append(self.quotedName())
    }

    public func alias(_ aliasName: String) -> SQLAliasedColumn {
        SQLAliasedColumn(column: self, alias: aliasName)
    }
}

// SKIP NOWARN // "This extension will be moved into its extended type definition when translated to Kotlin. It will not be able to access this file's private types or fileprivate members"
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

    static func custom(sql: String?, bindings: [SQLValue] = []) -> SQLPredicate {
        SQLPredicate { exp in
            if let sql {
                exp.append(" " + sql)
            }
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
