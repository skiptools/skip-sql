## 0.6.3

Released 2024-07-08

  - Update search paths for tomcrypt to point to intermediates/merged_native_libs/debug/mergeDebugNativeLibs/out/lib to accommodate change in android gradle plugin 8.5.0
  - Update README
  - ci: update workflow actions location

## 0.6.2

Released 2024-03-05

  - Link to external skip-ltc module for SQLExt
  - Add algorithm tests
  - Disable HAVE_GETHOSTUUID since it is disallowed on iOS
  - Ignore -Wconversion to reduce warnings

## 0.6.1

Released 2024-03-02

  - Harmonize build options between Android and Darwin
  - Add JSON tests
  - Add test cases

## 0.6.0

Released 2024-02-28

  - Update error messages and add JSON tests
  - Add SQLite JSON test
  - Add SQLPlus tests
  - Add SQLPlus tests
  - Add SQLPlus module that includes custom build of sqlite 3.44.2 with extensions

## 0.5.1

Released 2024-02-20

  - Blob statement parameter binding handling
  - Make UpdateHook class final

## 0.5.0

Released 2024-02-05


## 0.4.3

Released 2023-12-22


## 0.4.2

Released 2023-12-11

  - Minor comment updates
  - Update README.md

## 0.4.1

Released 2023-11-27

  - Dependency bump

## 0.4.0

Released 2023-11-25

  - Use direct mappings to optimize JNA access to C sqlite API
  - Refactor into separate implementation files

## 0.3.12

Released 2023-11-25

  - Require statements and connections to be closed

## 0.3.11

Released 2023-11-25

  - Add SQLContext.interrupt()

## 0.3.10

Released 2023-11-25

  - Fix in-memory database creation string

## 0.3.9

Released 2023-11-25

  - Add parameter inspection functions

## 0.3.8

Released 2023-11-24

  - Use SQLITE_TRANSIENT for bound strings and blobs

## 0.3.7

Released 2023-11-21

  - Doc updates
  - Docs

## 0.3.6

Released 2023-11-20


## 0.3.5

Released 2023-11-19

  - Add onUpdate hook and improve API
  - Add updateHook

## 0.3.4

Released 2023-11-16

  - Update API

## 0.3.3

Released 2023-11-14


## 0.3.2

Released 2023-11-14


## 0.3.1

Released 2023-11-02

  - More API and tests
  - Add blob accessor and transaction handling; test cases
  - Add SQLType and SQLValue and test cases
  - Add row accessor and test case
  - SQLStatement.next; SQLConnection.close

## 0.3.0

Released 2023-10-31

  - Import SQLite3 through SkipFFI

## 0.2.0

Released 2023-10-23


## 0.1.8

Released 2023-09-24


## 0.1.7

Released 2023-09-11

  - Elide SQLite version check since different emulators have different versions installed

## 0.1.6

Released 2023-09-09

  - Have tests use NSTemporaryDirectory() rather than /tmp/ (which doesn't exist on the Android emulator)

## 0.1.5

Released 2023-09-07


## 0.1.4

Released 2023-09-07


## 0.1.3

Released 2023-09-06

  - Modernize package

## 0.1.2

Released 2023-09-04


## 0.1.1

Released 2023-09-03


## 0.1.0

Released 2023-09-02


## 0.0.11

Released 2023-09-01


## 0.0.10

Released 2023-08-31


## 0.0.9

Released 2023-08-31


## 0.0.8

Released 2023-08-25


## 0.0.7

Released 2023-08-21

  - Update dependencies

## 0.0.6

Released 2023-08-21


## 0.0.5

Released 2023-08-20


## 0.0.4

Released 2023-08-20


## 0.0.3

Released 2023-08-20


## 0.0.2

Released 2023-08-20


