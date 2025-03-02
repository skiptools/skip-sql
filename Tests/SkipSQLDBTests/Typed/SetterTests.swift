<<<<<<< HEAD
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
=======
>>>>>>> d0c842f (Add SkipSQLDB module)
import XCTest
import SkipSQLDB

class SetterTests: XCTestCase {

    func test_setterAssignmentOperator_buildsSetter() {
        assertSQL("\"int\" = \"int\"", int <- int)
        assertSQL("\"int\" = 1", int <- 1)
        assertSQL("\"intOptional\" = \"int\"", intOptional <- int)
        assertSQL("\"intOptional\" = \"intOptional\"", intOptional <- intOptional)
        assertSQL("\"intOptional\" = 1", intOptional <- 1)
        assertSQL("\"intOptional\" = NULL", intOptional <- nil)
    }

    func test_plusEquals_withStringExpression_buildsSetter() {
        assertSQL("\"string\" = (\"string\" || \"string\")", string += string)
        assertSQL("\"string\" = (\"string\" || 'literal')", string += "literal")
        assertSQL("\"stringOptional\" = (\"stringOptional\" || \"string\")", stringOptional += string)
        assertSQL("\"stringOptional\" = (\"stringOptional\" || \"stringOptional\")", stringOptional += stringOptional)
        assertSQL("\"stringOptional\" = (\"stringOptional\" || 'literal')", stringOptional += "literal")
    }

    func test_plusEquals_withNumberExpression_buildsSetter() {
        assertSQL("\"int\" = (\"int\" + \"int\")", int += int)
        assertSQL("\"int\" = (\"int\" + 1)", int += 1)
        assertSQL("\"intOptional\" = (\"intOptional\" + \"int\")", intOptional += int)
        assertSQL("\"intOptional\" = (\"intOptional\" + \"intOptional\")", intOptional += intOptional)
        assertSQL("\"intOptional\" = (\"intOptional\" + 1)", intOptional += 1)

        assertSQL("\"double\" = (\"double\" + \"double\")", double += double)
        assertSQL("\"double\" = (\"double\" + 1.0)", double += 1)
        assertSQL("\"doubleOptional\" = (\"doubleOptional\" + \"double\")", doubleOptional += double)
        assertSQL("\"doubleOptional\" = (\"doubleOptional\" + \"doubleOptional\")", doubleOptional += doubleOptional)
        assertSQL("\"doubleOptional\" = (\"doubleOptional\" + 1.0)", doubleOptional += 1)
    }

    func test_minusEquals_withNumberExpression_buildsSetter() {
        assertSQL("\"int\" = (\"int\" - \"int\")", int -= int)
        assertSQL("\"int\" = (\"int\" - 1)", int -= 1)
        assertSQL("\"intOptional\" = (\"intOptional\" - \"int\")", intOptional -= int)
        assertSQL("\"intOptional\" = (\"intOptional\" - \"intOptional\")", intOptional -= intOptional)
        assertSQL("\"intOptional\" = (\"intOptional\" - 1)", intOptional -= 1)

        assertSQL("\"double\" = (\"double\" - \"double\")", double -= double)
        assertSQL("\"double\" = (\"double\" - 1.0)", double -= 1)
        assertSQL("\"doubleOptional\" = (\"doubleOptional\" - \"double\")", doubleOptional -= double)
        assertSQL("\"doubleOptional\" = (\"doubleOptional\" - \"doubleOptional\")", doubleOptional -= doubleOptional)
        assertSQL("\"doubleOptional\" = (\"doubleOptional\" - 1.0)", doubleOptional -= 1)
    }

    func test_timesEquals_withNumberExpression_buildsSetter() {
        assertSQL("\"int\" = (\"int\" * \"int\")", int *= int)
        assertSQL("\"int\" = (\"int\" * 1)", int *= 1)
        assertSQL("\"intOptional\" = (\"intOptional\" * \"int\")", intOptional *= int)
        assertSQL("\"intOptional\" = (\"intOptional\" * \"intOptional\")", intOptional *= intOptional)
        assertSQL("\"intOptional\" = (\"intOptional\" * 1)", intOptional *= 1)

        assertSQL("\"double\" = (\"double\" * \"double\")", double *= double)
        assertSQL("\"double\" = (\"double\" * 1.0)", double *= 1)
        assertSQL("\"doubleOptional\" = (\"doubleOptional\" * \"double\")", doubleOptional *= double)
        assertSQL("\"doubleOptional\" = (\"doubleOptional\" * \"doubleOptional\")", doubleOptional *= doubleOptional)
        assertSQL("\"doubleOptional\" = (\"doubleOptional\" * 1.0)", doubleOptional *= 1)
    }

    func test_dividedByEquals_withNumberExpression_buildsSetter() {
        assertSQL("\"int\" = (\"int\" / \"int\")", int /= int)
        assertSQL("\"int\" = (\"int\" / 1)", int /= 1)
        assertSQL("\"intOptional\" = (\"intOptional\" / \"int\")", intOptional /= int)
        assertSQL("\"intOptional\" = (\"intOptional\" / \"intOptional\")", intOptional /= intOptional)
        assertSQL("\"intOptional\" = (\"intOptional\" / 1)", intOptional /= 1)

        assertSQL("\"double\" = (\"double\" / \"double\")", double /= double)
        assertSQL("\"double\" = (\"double\" / 1.0)", double /= 1)
        assertSQL("\"doubleOptional\" = (\"doubleOptional\" / \"double\")", doubleOptional /= double)
        assertSQL("\"doubleOptional\" = (\"doubleOptional\" / \"doubleOptional\")", doubleOptional /= doubleOptional)
        assertSQL("\"doubleOptional\" = (\"doubleOptional\" / 1.0)", doubleOptional /= 1)
    }

    func test_moduloEquals_withIntegerExpression_buildsSetter() {
        assertSQL("\"int\" = (\"int\" % \"int\")", int %= int)
        assertSQL("\"int\" = (\"int\" % 1)", int %= 1)
        assertSQL("\"intOptional\" = (\"intOptional\" % \"int\")", intOptional %= int)
        assertSQL("\"intOptional\" = (\"intOptional\" % \"intOptional\")", intOptional %= intOptional)
        assertSQL("\"intOptional\" = (\"intOptional\" % 1)", intOptional %= 1)
    }

<<<<<<< HEAD
    #if !SKIP // SkipSQLDB TODO
=======
>>>>>>> d0c842f (Add SkipSQLDB module)
    func test_leftShiftEquals_withIntegerExpression_buildsSetter() {
        assertSQL("\"int\" = (\"int\" << \"int\")", int <<= int)
        assertSQL("\"int\" = (\"int\" << 1)", int <<= 1)
        assertSQL("\"intOptional\" = (\"intOptional\" << \"int\")", intOptional <<= int)
        assertSQL("\"intOptional\" = (\"intOptional\" << \"intOptional\")", intOptional <<= intOptional)
        assertSQL("\"intOptional\" = (\"intOptional\" << 1)", intOptional <<= 1)
    }

    func test_rightShiftEquals_withIntegerExpression_buildsSetter() {
        assertSQL("\"int\" = (\"int\" >> \"int\")", int >>= int)
        assertSQL("\"int\" = (\"int\" >> 1)", int >>= 1)
        assertSQL("\"intOptional\" = (\"intOptional\" >> \"int\")", intOptional >>= int)
        assertSQL("\"intOptional\" = (\"intOptional\" >> \"intOptional\")", intOptional >>= intOptional)
        assertSQL("\"intOptional\" = (\"intOptional\" >> 1)", intOptional >>= 1)
    }

    func test_bitwiseAndEquals_withIntegerExpression_buildsSetter() {
        assertSQL("\"int\" = (\"int\" & \"int\")", int &= int)
        assertSQL("\"int\" = (\"int\" & 1)", int &= 1)
        assertSQL("\"intOptional\" = (\"intOptional\" & \"int\")", intOptional &= int)
        assertSQL("\"intOptional\" = (\"intOptional\" & \"intOptional\")", intOptional &= intOptional)
        assertSQL("\"intOptional\" = (\"intOptional\" & 1)", intOptional &= 1)
    }

    func test_bitwiseOrEquals_withIntegerExpression_buildsSetter() {
        assertSQL("\"int\" = (\"int\" | \"int\")", int |= int)
        assertSQL("\"int\" = (\"int\" | 1)", int |= 1)
        assertSQL("\"intOptional\" = (\"intOptional\" | \"int\")", intOptional |= int)
        assertSQL("\"intOptional\" = (\"intOptional\" | \"intOptional\")", intOptional |= intOptional)
        assertSQL("\"intOptional\" = (\"intOptional\" | 1)", intOptional |= 1)
    }

    func test_bitwiseExclusiveOrEquals_withIntegerExpression_buildsSetter() {
        assertSQL("\"int\" = (~((\"int\" & \"int\")) & (\"int\" | \"int\"))", int ^= int)
        assertSQL("\"int\" = (~((\"int\" & 1)) & (\"int\" | 1))", int ^= 1)
        assertSQL("\"intOptional\" = (~((\"intOptional\" & \"int\")) & (\"intOptional\" | \"int\"))", intOptional ^= int)
        assertSQL("\"intOptional\" = (~((\"intOptional\" & \"intOptional\")) & (\"intOptional\" | \"intOptional\"))", intOptional ^= intOptional)
        assertSQL("\"intOptional\" = (~((\"intOptional\" & 1)) & (\"intOptional\" | 1))", intOptional ^= 1)
    }

    func test_postfixPlus_withIntegerValue_buildsSetter() {
        assertSQL("\"int\" = (\"int\" + 1)", int++)
        assertSQL("\"intOptional\" = (\"intOptional\" + 1)", intOptional++)
    }

    func test_postfixMinus_withIntegerValue_buildsSetter() {
        assertSQL("\"int\" = (\"int\" - 1)", int--)
        assertSQL("\"intOptional\" = (\"intOptional\" - 1)", intOptional--)
    }
<<<<<<< HEAD
    #endif
=======

>>>>>>> d0c842f (Add SkipSQLDB module)
}
