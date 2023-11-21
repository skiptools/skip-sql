
The SkipSQL module is a dual-platform Skip framework that provides access to sqlite databases in Darwin and Android systems.

## Usage

### Connection example

To connect 
```swift
let dbpath = URL.documentsDirectoryURL.appendingPathComponent("db.sqlite")

let ctx = try SQLContext(path: dbpath, flags: [.create, .readWrite])
defer { ctx.close() }

try sqlite.exec(sql: "CREATE TABLE IF NOT EXISTS SOME_TABLE (STRING TEXT)")

try sqlite.exec(sql: "INSERT INTO SOME_TABLE (STRING) VALUES ('ABC')")

let rows: [[SQLValue]] = ctx.query(sql: "SELECT STRING FROM SOME_TABLE")
assert(rows[0][0] == SQLValue.string("ABC"))

```

### In-memory databases 

When passing `nil` as the path, the `SQLContext` will reside entirely in memory, and will not persist once the context is closed. This can be useful for unit testing and performing in-memory calculations, or as a temporary engine for calculations and sorting.

```swift
let ctx = try SQLContext(path: nil)
defer { ctx.close() }

let rows: [[SQLValue]] = ctx.query(sql: "SELECT 1, 2 + 3, 4 * 5")

assert(rows[0][0] == SQLValue.integer(1))
assert(rows[0][1] == SQLValue.integer(5))
assert(rows[0][2] == SQLValue.integer(20))

```

### Transactions

Performing multiple operations in the context of a transaction will ensure that either all the operations succeed (`COMMIT`) or fail (`ROLLBACK`) together.

```swift
try ctx.transaction {
    try ctx.exec(sql: "INSERT INTO TABLE_NAME VALUES(1)")
    try ctx.exec(sql: "INSERT INTO TABLE_NAME VALUES(2)")
}
```

### Bound parameters

Retaining a prepared `SQLStatement` will mean that the SQL doesn't need to be re-parsed each time a query or insert/update statement is performed.

SQL statements with a `?` symbol will expect those parameters to be applied with the `bind` function before the statement is executed. 

```swift

let insert = try sqlite.prepare(sql: "INSERT INTO TABLE_NAME (NUM, STR) VALUES (?, ?)")
defer { insert.close() }

// insert 1,000 rows in a single transaction, re-using the insert statement
try sqlite.transaction {
    for i in 1...1_000 {
        let params: [SQLValue] = [
            SQLValue.integer(Int64(i)),
            SQLValue.text("Row #\(i)")
        ]
        try insert.update(parameters: params)
    }
}

```


### Schema Migration

There is no built-in support the schema migrations.

Following is a part of a sample of how you might perform migrations in your own app (taken from the [DataBake](https://source.skip.tools/skipapp-databake) sample app). See the full app for details.


```swift
// track the version of the schema in the database, which can be used for schema migration
try ctx.exec(sql: "CREATE TABLE IF NOT EXISTS DB_SCHEMA_VERSION (id INTEGER PRIMARY KEY, version INTEGER)")
try ctx.exec(sql: "INSERT OR IGNORE INTO DB_SCHEMA_VERSION (id, version) VALUES (0, 0)")
var currentVersion = try ctx.query(sql: "SELECT version FROM DB_SCHEMA_VERSION").first?.first?.integerValue ?? 0

func migrateSchema(v version: Int64, ddl: String) throws {
    if currentVersion < version {
        let startTime = Date.now
        try ctx.exec(sql: ddl) // perform the DDL operation
        // then update the schema version
        try ctx.exec(sql: "UPDATE DB_SCHEMA_VERSION SET version = ?", parameters: [SQLValue.integer(version)])
        currentVersion = version
        logger.log("updated database schema to \(version) in \(startTime.durationToNow)")
    }
}

let tableName = "TABLE_NAME"

// the initial creation script for a new database
try migrateSchema(v: 1, ddl: """
CREATE TABLE \(tableName) (\(DataItem.CodingKeys.id.rawValue) INTEGER PRIMARY KEY AUTOINCREMENT)
""")

// incrementally migrate up to the current schema version
func addDataItemColumn(_ key: DataItem.CodingKeys) -> String {
    "ALTER TABLE \(tableName) ADD COLUMN \(key.rawValue) \(key.ddl)"
}

try migrateSchema(v: 2, ddl: addDataItemColumn(.title))
try migrateSchema(v: 3, ddl: addDataItemColumn(.created))
try migrateSchema(v: 4, ddl: addDataItemColumn(.modified))
try migrateSchema(v: 5, ddl: addDataItemColumn(.contents))
try migrateSchema(v: 6, ddl: addDataItemColumn(.rating))
try migrateSchema(v: 7, ddl: addDataItemColumn(.thumbnail))
// future migrations to follow…

```

### Threading 

As a think layer over a SQLite connection, SkipSQL itself performs no locking. It is up to the application layer to set up reader/writer locks, or else just perform all the operations on one thread (e.g., using `MainActor.run` to enqueue operations from a `Task`).

The Sqlite guide on [Locking And Concurrency](https://www.sqlite.org/lockingv3.html) can provide additional guidance.


## Implementation

SkipSQL is a very thin interface atop the low-level SQLite3 C library that is included with all Darwin/iOS/Android operating systems.
On Darwin/iOS, it communicates directly through Swift's C bridging support.
On Android, it uses the [SkipFFI](http://source.skip.tools/skip-ffi/) module to interact directly with the underlying sqlite installation on Android.
(For performance and a consistent API, SkipSQL eschews Android's `android.database.sqlite` Java wrapper, and uses JNA to directly access the SQLite C API.)

## SQLite Versions

Since SkipSQL just uses the version of SQLite that is shipped with the platform, care should be taken when using recent SQLite features, such as the [`json`](https://sqlite.org/json1.html) function, which is new in SQLite 3.38, in which case it would raise an error on Android versions below 14.0 (API 34) and iOS versions below 16.0.


### iOS

| iOS Version | SQLite Version |
|-------------|----------------|
| 13          | 3.28           |
| 14          | 3.32           |
| 15          | 3.36           |
| 16          | 3.39           |


### Android

|Android API     |SQLite Version|
|----------------|--------------|
| 9 (API 28)     | 3.22         |
| 10 (API 30)    | 3.28         |
| 11 (API 31)    | 3.32         |
| 12 (API 32)    | 3.32         |
| 13 (API 33)    | 3.32         |
| 14 (API 34)    | 3.39         |


## Building

This project is a Swift Package Manager module that uses the
[Skip](https://skip.tools) plugin to transpile Swift into Kotlin.

Building the module requires that Skip be installed using 
[Homebrew](https://brew.sh) with `brew install skiptools/skip/skip`.
This will also install the necessary build prerequisites:
Kotlin, Gradle, and the Android build tools.

## Testing

The module can be tested using the standard `swift test` command
or by running the test target for the macOS destination in Xcode,
which will run the Swift tests as well as the transpiled
Kotlin JUnit tests in the Robolectric Android simulation environment.

Parity testing can be performed with `skip test`,
which will output a table of the test results for both platforms.
