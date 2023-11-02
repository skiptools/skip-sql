# skip-sql

SQL module for [Skip](https://skip.tools) apps.

## Usage


## Limitations


## Performance

SkipSQL is a very thin interface atop the low-level SQLite3 C library.


### Write 1 Million Rows

iPhone Emulator:

```plaintext
2023-11-02 12:55:58.279764-0400 xctest[24601:11529757] [SQLiteTests] wrote 1000000 rows to db in 1.170464: /var/folders/zl/wkdjv4s1271fbm6w0plzknkh0000gn/T/testSQLitePerformance-5E961C54-D265-43AB-AE4F-11A8D8A20C92.db
```


Android Emulator:

```plaintext
STDOUT> I/skip.sql.SQLiteTests: wrote 1000000 rows to db in 5.4730000495910645: /var/folders/zl/wkdjv4s1271fbm6w0plzknkh0000gn/T/testSQLitePerformance-F4E41C05-7A09-4958-BFEC-E5614C1AD5DE.db
```


iPhone 12 Mini:

```plaintext
```


Pixel 6:

```plaintext
skip.sql.SQLiteTests: done writing to db in 74.45700001716614: /data/user/0/skip.sql.test/cache/testSQLitePerformance-827F3BEF-D534-4B4A-A39D-B2C2B3549235.db
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
