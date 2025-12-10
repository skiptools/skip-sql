cmake_minimum_required(VERSION 3.3)

project(sqlext LANGUAGES C)

include_directories(sqlext PUBLIC sqlite/)
file(SOURCES sqlite/*.c)

include_directories(sqlext libtomcrypt/)
file(GLOB_RECURSE SOURCES libtomcrypt/*.c)

add_library(sqlext SHARED ${SOURCES})

# these should match the definitions in the Package.swift
# so the Android build and the Swift build options match
add_compile_definitions(SQLITE_DQS=0)
add_compile_definitions(SQLITE_ENABLE_API_ARMOR)
add_compile_definitions(SQLITE_ENABLE_COLUMN_METADATA)
add_compile_definitions(SQLITE_ENABLE_DBSTAT_VTAB)
add_compile_definitions(SQLITE_ENABLE_FTS3)
add_compile_definitions(SQLITE_ENABLE_FTS3_PARENTHESIS)
add_compile_definitions(SQLITE_ENABLE_FTS3_TOKENIZER)
add_compile_definitions(SQLITE_ENABLE_FTS4)
add_compile_definitions(SQLITE_ENABLE_FTS5)
add_compile_definitions(SQLITE_ENABLE_MEMORY_MANAGEMENT)
add_compile_definitions(SQLITE_ENABLE_PREUPDATE_HOOK)
add_compile_definitions(SQLITE_ENABLE_RTREE)
add_compile_definitions(SQLITE_ENABLE_SESSION)
add_compile_definitions(SQLITE_ENABLE_STMTVTAB)
add_compile_definitions(SQLITE_ENABLE_UNKNOWN_SQL_FUNCTION)
add_compile_definitions(SQLITE_ENABLE_UNLOCK_NOTIFY)
add_compile_definitions(SQLITE_MAX_VARIABLE_NUMBER=250000)
add_compile_definitions(SQLITE_LIKE_DOESNT_MATCH_BLOBS)
add_compile_definitions(SQLITE_OMIT_DEPRECATED)
add_compile_definitions(SQLITE_OMIT_SHARED_CACHE)
add_compile_definitions(SQLITE_SECURE_DELETE)
add_compile_definitions(SQLITE_THREADSAFE=2)
add_compile_definitions(SQLITE_USE_URI)
add_compile_definitions(SQLITE_ENABLE_SNAPSHOT)
add_compile_definitions(SQLITE_HAS_CODEC)
add_compile_definitions(SQLITE_HOMEGROWN_RECURSIVE_MUTEX)
add_compile_definitions(SQLITE_TEMP_STORE=2)
add_compile_definitions(SQLITE_EXTRA_INIT=sqlcipher_extra_init)
add_compile_definitions(SQLITE_EXTRA_SHUTDOWN=sqlcipher_extra_shutdown)
add_compile_definitions(HAVE_GETHOSTUUID=0)
add_compile_definitions(HAVE_STDINT_H)
add_compile_definitions(SQLCIPHER_CRYPTO_LIBTOMCRYPT)
add_compile_definitions(SQLCIPHER_CRYPTO_CUSTOM=sqlcipher_ltc_setup)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -frtti -fexceptions")

# sqlite has calls to __android_log_print
target_link_libraries(sqlext log)

# support 16 KB page sizes: https://developer.android.com/guide/practices/page-sizes
target_link_options(${CMAKE_PROJECT_NAME} PRIVATE "-Wl,-z,max-page-size=16384")
