cmake_minimum_required(VERSION 3.1)

project(sqlext, LANGUAGES C)

file(GLOB_RECURSE SOURCES sqlcipher/*.c libtomcrypt/*.c)
add_library(sqlext SHARED ${SOURCES})
include_directories(sqlext PUBLIC sqlcipher/)
include_directories(sqlext PUBLIC libtomcrypt/headers/)

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
add_compile_definitions(SQLITE_OMIT_LOAD_EXTENSION)
add_compile_definitions(SQLITE_OMIT_SHARED_CACHE)
add_compile_definitions(SQLITE_SECURE_DELETE)
add_compile_definitions(SQLITE_THREADSAFE=2)
add_compile_definitions(SQLITE_USE_URI)
add_compile_definitions(SQLITE_ENABLE_SNAPSHOT)
add_compile_definitions(SQLITE_HAS_CODEC)
add_compile_definitions(SQLITE_TEMP_STORE=2)
add_compile_definitions(SQLCIPHER_CRYPTO_LIBTOMCRYPT)


# we use LTC_NO_ASM in the Package.swift cSettings, but we can enable -maes for android
# failure to do so results in the compile error:
# libtomcrypt/ciphers/aes/aesni.c:150:26: error: always_inline function '_mm_aesimc_si128' requires target feature 'aes', but would be inlined into function 'aesni_setup' that is compiled without support for 'aes'
#target_compile_options(sqlext PRIVATE -maes)

# sqlcipher has calls to __android_log_print
target_link_libraries(sqlext log)
