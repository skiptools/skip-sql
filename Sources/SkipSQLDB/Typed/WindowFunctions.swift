// Copyright 2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception

// This code is adapted from the SQLite.swift project, with the following license:

// SQLite.swift
// https://github.com/stephencelis/SQLite.swift
// Copyright © 2014-2015 Stephen Celis.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
import Foundation

// see https://www.sqlite.org/windowfunctions.html#builtins
private enum WindowFunction: String {
    // swiftlint:disable identifier_name
    case ntile
    case row_number
    case rank
    case dense_rank
    case percent_rank
    case cume_dist
    case lag
    case lead
    case first_value
    case last_value
    case nth_value
    // swiftlint:enable identifier_name

    #if !SKIP // SkipSQLDB TODO

    func wrap<T>(_ value: Int? = nil) -> SQLExpression<T> {
        if let value {
            return self.rawValue.wrap(SQLExpression(value: value))
        }
        return SQLExpression(literal: "\(rawValue)()")
    }

    func over<T>(value: Int? = nil, _ orderBy: Expressible) -> SQLExpression<T> {
        return SQLExpression<T>(" ".join([
            self.wrap(value),
            SQLExpression<T>("OVER (ORDER BY \(orderBy.expression.template))", orderBy.expression.bindings)
        ]).expression)
    }

    func over<T>(valueExpr: Expressible, _ orderBy: Expressible) -> SQLExpression<T> {
        return SQLExpression<T>(" ".join([
            self.rawValue.wrap(valueExpr),
            SQLExpression<T>("OVER (ORDER BY \(orderBy.expression.template))", orderBy.expression.bindings)
        ]).expression)
    }
    #endif
}

#if !SKIP // SkipSQLDB TODO

extension ExpressionType where UnderlyingType: Value {
    /// Builds a copy of the expression with `lag(self, offset, default) OVER (ORDER BY {orderBy})` window function
    ///
    /// - Parameter orderBy: Expression to evaluate window order
    /// - Returns: An expression returning `lag(self, offset, default) OVER (ORDER BY {orderBy})` window function
    public func lag(offset: Int = 0, default: Expressible? = nil, _ orderBy: Expressible) -> SQLExpression<UnderlyingType> {
        if let defaultExpression = `default` {
            return SQLExpression(
                "lag(\(template), \(offset), \(defaultExpression.asSQL())) OVER (ORDER BY \(orderBy.expression.template))",
                bindings + orderBy.expression.bindings
            )

        }
        return SQLExpression("lag(\(template), \(offset)) OVER (ORDER BY \(orderBy.expression.template))", bindings + orderBy.expression.bindings)
    }

    /// Builds a copy of the expression with `lead(self, offset, default) OVER (ORDER BY {orderBy})` window function
    ///
    /// - Parameter orderBy: Expression to evaluate window order
    /// - Returns: An expression returning `lead(self, offset, default) OVER (ORDER BY {orderBy})` window function
    public func lead(offset: Int = 0, default: Expressible? = nil, _ orderBy: Expressible) -> SQLExpression<UnderlyingType> {
        if let defaultExpression = `default` {
            return SQLExpression(
                "lead(\(template), \(offset), \(defaultExpression.asSQL())) OVER (ORDER BY \(orderBy.expression.template))",
                bindings + orderBy.expression.bindings)

        }
        return SQLExpression("lead(\(template), \(offset)) OVER (ORDER BY \(orderBy.expression.template))", bindings + orderBy.expression.bindings)
    }

    /// Builds a copy of the expression with `first_value(self) OVER (ORDER BY {orderBy})` window function
    ///
    /// - Parameter orderBy: Expression to evaluate window order
    /// - Returns: An expression returning `first_value(self) OVER (ORDER BY {orderBy})` window function
    public func firstValue(_ orderBy: Expressible) -> SQLExpression<UnderlyingType> {
        WindowFunction.first_value.over(valueExpr: self, orderBy)
    }

    /// Builds a copy of the expression with `last_value(self) OVER (ORDER BY {orderBy})` window function
    ///
    /// - Parameter orderBy: Expression to evaluate window order
    /// - Returns: An expression returning `last_value(self) OVER (ORDER BY {orderBy})` window function
    public func lastValue(_ orderBy: Expressible) -> SQLExpression<UnderlyingType> {
        WindowFunction.last_value.over(valueExpr: self, orderBy)
    }

    /// Builds a copy of the expression with `nth_value(self) OVER (ORDER BY {orderBy})` window function
    ///
    /// - Parameter index: Row N of the window frame to return
    /// - Parameter orderBy: Expression to evaluate window order
    /// - Returns: An expression returning `nth_value(self) OVER (ORDER BY {orderBy})` window function
    public func value(_ index: Int, _ orderBy: Expressible) -> SQLExpression<UnderlyingType> {
        SQLExpression("nth_value(\(template), \(index)) OVER (ORDER BY \(orderBy.expression.template))", bindings + orderBy.expression.bindings)
    }
}

/// Builds an expression representing `ntile(size) OVER (ORDER BY {orderBy})`
///
/// - Parameter orderBy: Expression to evaluate window order
/// - Returns: An expression returning  `ntile(size) OVER (ORDER BY {orderBy})`
public func ntile(_ size: Int, _ orderBy: Expressible) -> SQLExpression<Int> {
//    Expression.ntile(size, orderBy)

        WindowFunction.ntile.over(value: size, orderBy)
}

/// Builds an expression representing `row_count() OVER (ORDER BY {orderBy})`
///
/// - Parameter orderBy: Expression to evaluate window order
/// - Returns: An expression returning `row_count() OVER (ORDER BY {orderBy})`
public func rowNumber(_ orderBy: Expressible) -> SQLExpression<Int> {
    WindowFunction.row_number.over(orderBy)
}

/// Builds an expression representing `rank() OVER (ORDER BY {orderBy})`
///
/// - Parameter orderBy: Expression to evaluate window order
/// - Returns: An expression returning `rank() OVER (ORDER BY {orderBy})`
public func rank(_ orderBy: Expressible) -> SQLExpression<Int> {
    WindowFunction.rank.over(orderBy)
}

/// Builds an expression representing `dense_rank() OVER (ORDER BY {orderBy})`
///
/// - Parameter orderBy: Expression to evaluate window order
/// - Returns: An expression returning `dense_rank() OVER ('over')`
public func denseRank(_ orderBy: Expressible) -> SQLExpression<Int> {
    WindowFunction.dense_rank.over(orderBy)
}

/// Builds an expression representing `percent_rank() OVER (ORDER BY {orderBy})`
///
/// - Parameter orderBy: Expression to evaluate window order
/// - Returns: An expression returning `percent_rank() OVER (ORDER BY {orderBy})`
public func percentRank(_ orderBy: Expressible) -> SQLExpression<Double> {
    WindowFunction.percent_rank.over(orderBy)
}

/// Builds an expression representing `cume_dist() OVER (ORDER BY {orderBy})`
///
/// - Parameter orderBy: Expression to evaluate window order
/// - Returns: An expression returning `cume_dist() OVER (ORDER BY {orderBy})`
public func cumeDist(_ orderBy: Expressible) -> SQLExpression<Double> {
    WindowFunction.cume_dist.over(orderBy)
}
#endif

