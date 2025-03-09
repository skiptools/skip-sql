
The SkipSQL module is a dual-platform Skip framework that provides access to sqlite database in Darwin and Android systems.

## Usage

### Connection example

To connect 
```swift
let dbpath = URL.documentsDirectory.appendingPathComponent("db.sqlite")

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

let rows: [[SQLValue]] = ctx.query(sql: "SELECT 1, 1.1+2.2, 'AB'||'C'")

assert(rows[0][0] == SQLValue.integer(1))
assert(rows[0][1] == SQLValue.float(3.3))
assert(rows[0][2] == SQLValue.text("ABC"))

```

### Transactions

Performing multiple operations in the context of a transaction will ensure that either all the operations succeed (`COMMIT`) or fail (`ROLLBACK`) together.

```swift
try ctx.transaction {
    try ctx.exec(sql: "INSERT INTO TABLE_NAME VALUES(1)")
    try ctx.exec(sql: "INSERT INTO TABLE_NAME VALUES(2)")
}
```

The default transaction type is `.deferred`, but it can be specified as a parameter to `transaction` to override the default, or `nil` to perform the operation without a transaction.

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

There is no built-in support for schema migrations. Following is a part of a sample of how you might perform migrations in your own app.


```swift
// track the version of the schema in the database, which can be used for schema migration
try ctx.exec(sql: "CREATE TABLE IF NOT EXISTS DB_SCHEMA_VERSION (id INTEGER PRIMARY KEY, version INTEGER)")
try ctx.exec(sql: "INSERT OR IGNORE INTO DB_SCHEMA_VERSION (id, version) VALUES (0, 0)")
var currentVersion = try ctx.query(sql: "SELECT version FROM DB_SCHEMA_VERSION").first?.first?.integerValue ?? 0

func migrateSchema(v version: Int64, ddl: String) throws {
    if currentVersion < version {
        let startTime = Date.now
        try ctx.transaction {
            try ctx.exec(sql: ddl) // perform the DDL operation
            // then update the schema version
            try ctx.exec(sql: "UPDATE DB_SCHEMA_VERSION SET version = ?", parameters: [SQLValue.integer(version)])
        }
        currentVersion = version
        logger.log("updated database schema to \(version) in \(startTime.durationToNow)")
    }
}

// the initial creation script for a new database
try migrateSchema(v: 1, ddl: """
CREATE TABLE DATA_ITEM (ID INTEGER PRIMARY KEY AUTOINCREMENT)
""")
// migrate records to have new description column
try migrateSchema(v: 2, ddl: """
ALTER TABLE DATA_ITEM ADD COLUMN DESCRIPTION TEXT
""")
```

### Concurrency

As a thin layer over a SQLite connection, SkipSQL itself performs no locking or manages threads in any way. It is up to the application layer to set up reader/writer locks, or else just perform all the operations in an isolated context (e.g., using an actor).

The SQLite guide on [Locking And Concurrency](https://www.sqlite.org/lockingv3.html) can provide additional guidance.


## Implementation

SkipSQL speaks directly to the low-level SQLite3 C library that is included with all Darwin/iOS/Android operating systems.
On Darwin/iOS, it communicates directly through Swift's C bridging support.
On Android, it uses the [SkipFFI](https://source.skip.tools/skip-ffi) module to interact directly with the underlying sqlite installation on Android.
(For performance and a consistent API, SkipSQL eschews Android's `android.database.sqlite` Java wrapper, and uses JNA to directly access the SQLite C API.)

## SQLite Versions

### Vendored SQLite Versions

Because SkipSQL uses the version of SQLite that is shipped with the platform, care should be taken when using recent SQLite features, such as the [`json`](https://sqlite.org/json1.html) function, which is new in SQLite 3.38. This would raise an error on Android versions below 14.0 (API 34) and iOS versions below 16.0.

Be aware that some very useful SQL features may only have been added to more recent versions of SQLite, such as strict tables (added in 3.37). This may impact the Android API version you can deploy back to, so be sure to test your code on the oldest available Android emulator and iOS simulator for your project.

Also be aware that the availability of some SQL features are contingent on the compile flags used to build the vendored sqlite implementation provided as part of the OS, such as `SQLITE_ENABLE_JSON1` enabling the various [`json_`](https://www.sqlite.org/json1.html) operations. In the case of Android, be aware that local Robolectric testing will be insufficient to identify any limitations resulting from sqlite compile flags, since local testing will use the local (i.e., macOS-vendored) version of SQLite. Testing against an Android emulator (or device) should be performed when developing new SQL operations.


| OS Version             | SQLite Version |
|------------------------|----------------|
| Android 9 (API 28)     | 3.22           |
| iOS 13                 | 3.28           |
| Android 10 (API 30)    | 3.28           |
| iOS 14                 | 3.32           |
| Android 11 (API 31)    | 3.32           |
| Android 12 (API 32)    | 3.32           |
| Android 13 (API 33)    | 3.32           |
| iOS 15                 | 3.36           |
| iOS 16                 | 3.39           |
| Android 14 (API 34)    | 3.39           |
| Android 15 (API 35)    | 3.42           |
| SQLPlus                | 3.44           |


---

### SQLPlus

The `skip-sql` framework includes an additional `SQLPlus` module,
which creates a local build with the following extensions enabled:

 - Full Text Search (FTS)
 - Encryption (sqlcipher)

The `SQLPlus` module uses sqlite version 3.44.2, which means
that it will be safe to use newer sqlite features like
the [`json`](https://sqlite.org/json1.html) function,
regardless of the Android API and iOS versions of the 
deployment platform.

This comes at the cost of additional build time for the native libraries,
as well as a larger artifact size (around 1MB on iOS and 4MB on Android).

#### Using SQLPlus

The SQLPlus extensions can be used by importing the `SkipSQLPlus` module
and passing `configuration: .plus` to the `SQLContext` constructor, like so:

```swift
import SkipSQL
import SkipSQLPlus

let dbpath = URL.documentsDirectory.appendingPathComponent("db.sqlite")
let db = try SQLContext(path: dbpath.path, flags: [.create, .readWrite], configuration: .plus)
// do something with the database
db.close()
```

#### JSON

SQLPlus enables the [`json`](https://sqlite.org/json1.html) extensions:


```swift
let sqlplus = SQLContext(configuration: .plus)
try sqlplus.exec(sql: #"CREATE TABLE users (id INTEGER PRIMARY KEY, profile JSON)"#)

try sqlplus.exec(sql: #"INSERT INTO users (id, profile) VALUES (1, '{"name": "Alice", "age": 30}')"#)
try sqlplus.exec(sql: #"INSERT INTO users (id, profile) VALUES (2, '{"name": "Bob", "age": 25}')"#)

let j1 = try sqlplus.query(sql: #"SELECT json_extract(profile, '$.name') as name FROM users WHERE id = ?"#, parameters: [.integer(1)]).first
assert j1 == [.text("Alice")]

let j2 = try sqlplus.query(sql: #"SELECT json_extract(profile, '$.name') as name, json_extract(profile, '$.age') as age FROM users WHERE id = ?"#, parameters: [.integer(2)]).first
assert j2 == [.text("Bob"), .integer(25)]
```


#### Encryption

SQLPlus contains the SQLCipher extension, which adds 256 bit AES encryption of database files and other security features like:

- On-the-fly encryption
- Tamper detection
- Memory sanitization
- Strong key derivation

SQLCipher is based on SQLite and stable upstream release features are periodically integrated. The extension is documented at the official [SQLCipher site](https://www.zetetic.net/sqlcipher/). It is used by many mobile applications like the [Signal](https://github.com/signalapp/sqlcipher) iOS and Android app to
secure local database files. Cryptographic algorithms are provided by the [LibTomCrypt](https://github.com/libtom/libtomcrypt) C library, which is included alongside the sqlcipher sources.

An example of creating an encryped database:

```swift
import SkipSQL
import SkipSQLPlus

let dbpath = URL.documentsDirectory.appendingPathComponent("encrypted.sqlite")
let db = try SQLContext(path: dbpath.path, flags: [.create, .readWrite], configuration: .plus)
_ = try db.query(sql: "PRAGMA key = 'password'")
try db.exec(sql: #"CREATE TABLE SOME_TABLE(col)"#)
try db.exec(sql: #"INSERT INTO SOME_TABLE(col) VALUES(?)"#, parameters: [.text("SOME SECRET STRING")])
try db.close()
```


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

## Contributing

We welcome contributions to this package in the form of enhancements and bug fixes.

The general flow for contributing to this and any other Skip package is:

1. Fork this repository and enable actions from the "Actions" tab
2. Check out your fork locally
3. When developing alongside a Skip app, add the package to a [shared workspace](https://skip.tools/docs/contributing) to see your changes incorporated in the app
4. Push your changes to your fork and ensure the CI checks all pass in the Actions tab
5. Add your name to the Skip [Contributor Agreement](https://github.com/skiptools/clabot-config)
6. Open a Pull Request from your fork with a description of your changes

## License

This software is licensed under the
[GNU Lesser General Public License v3.0](https://spdx.org/licenses/LGPL-3.0-only.html),
with the following
[linking exception](https://spdx.org/licenses/LGPL-3.0-linking-exception.html)
to clarify that distribution to restricted environments (e.g., app stores)
is permitted:

> This software is licensed under the LGPL3, included below.
> As a special exception to the GNU Lesser General Public License version 3
> ("LGPL3"), the copyright holders of this Library give you permission to
> convey to a third party a Combined Work that links statically or dynamically
> to this Library without providing any Minimal Corresponding Source or
> Minimal Application Code as set out in 4d or providing the installation
> information set out in section 4e, provided that you comply with the other
> provisions of LGPL3 and provided that you meet, for the Application the
> terms and conditions of the license(s) which apply to the Application.
> Except as stated in this special exception, the provisions of LGPL3 will
> continue to comply in full to this Library. If you modify this Library, you
> may apply this exception to your version of this Library, but you are not
> obliged to do so. If you do not wish to do so, delete this exception
> statement from your version. This exception does not (and cannot) modify any
> license terms which apply to the Application, with which you must still
> comply.

