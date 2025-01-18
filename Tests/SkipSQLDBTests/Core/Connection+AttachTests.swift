import XCTest
import Foundation
@testable import SkipSQLDB

#if SQLITE_SWIFT_STANDALONE
import sqlite3
#elseif SQLITE_SWIFT_SQLCIPHER
import SQLCipher
#elseif os(Linux) || os(Windows) || os(Android)
import CSQLite
#else
import SQLite3
#endif

class ConnectionAttachTests: SQLiteTestCase {
    func test_attach_detach_memory_database() throws {
        let schemaName = "test"

        try db.attach(.inMemory, as: schemaName)

        let table = Table("attached_users", database: schemaName)
        let name = SQLExpression<String>("string")

        // create a table, insert some data
        try db.run(table.create { builder in
            builder.column(name)
        })
        _ = try db.run(table.insert(name <- "test"))

        // query data
        let rows = try db.prepare(table.select(name)).map { $0[name] }
        XCTAssertEqual(["test"], rows)

        try db.detach(schemaName)
    }

    #if !os(Windows) // fails on Windows for some reason, maybe due to URI parameter (because test_init_with_Uri_and_Parameters fails too)
    func test_attach_detach_file_database() throws {
        let schemaName = "test"
        let testDb = fixture("test", withExtension: "sqlite")

        try db.attach(.uri(testDb, parameters: [.mode(.readOnly)]), as: schemaName)

        let table = Table("tests", database: schemaName)
        let email = SQLExpression<String>("email")

        let rows = try db.prepare(table.select(email)).map { $0[email] }
        XCTAssertEqual(["foo@bar.com"], rows)

        try db.detach(schemaName)
    }
    #endif

    func test_detach_invalid_schema_name_errors_with_no_such_database() throws {
        XCTAssertThrowsError(try db.detach("no-exist")) { error in
            if case let Result.error(message, code, _) = error {
                XCTAssertEqual(code, SQLITE_ERROR)
                XCTAssertEqual("no such database: no-exist", message)
            } else {
                XCTFail("unexpected error: \(error)")
            }
        }
    }
}
