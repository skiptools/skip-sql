cmake_minimum_required(VERSION 3.1)

project(sqlext, LANGUAGES C)

file(GLOB_RECURSE SOURCES sqlcipher/*.c libtomcrypt/*.c)
add_library(sqlext SHARED ${SOURCES})
include_directories(sqlext PUBLIC sqlcipher/)
include_directories(sqlext PUBLIC libtomcrypt/headers/)
add_compile_definitions(SQLITE_ENABLE_SNAPSHOT SQLITE_ENABLE_FTS5 SQLITE_HAS_CODEC SQLCIPHER_CRYPTO_LIBTOMCRYPT SQLITE_TEMP_STORE=2)
target_compile_options(sqlext PRIVATE -maes)
target_link_libraries(sqlext log)


# TODO: translate SwiftPM compile flags
#.headerSearchPath("sqlcipher"),
#.headerSearchPath("libtomcrypt/headers"),
#.define("SQLITE_ENABLE_SNAPSHOT"),
#.define("SQLITE_ENABLE_FTS5"),
#.define("SQLITE_HAS_CODEC"),
#.define("SQLITE_TEMP_STORE", to: "2"),
#.define("SQLCIPHER_CRYPTO_LIBTOMCRYPT"),
