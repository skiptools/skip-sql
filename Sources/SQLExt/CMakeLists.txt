cmake_minimum_required(VERSION 3.1)

project(sqlext, LANGUAGES C)

file(GLOB_RECURSE SOURCES sqlcipher/*.c libtomcrypt/*.c)
add_library(sqlext SHARED ${SOURCES})
include_directories(sqlext PUBLIC sqlcipher/)
include_directories(sqlext PUBLIC libtomcrypt/headers/)
add_compile_definitions(SQLITE_ENABLE_SNAPSHOT SQLITE_ENABLE_FTS5 SQLITE_HAS_CODEC SQLCIPHER_CRYPTO_LIBTOMCRYPT SQLITE_TEMP_STORE=2)

# we use LTC_NO_ASM in the Package.swift cSettings, but we can enable -maes for android
# failure to do so results in the compile error:
# libtomcrypt/ciphers/aes/aesni.c:150:26: error: always_inline function '_mm_aesimc_si128' requires target feature 'aes', but would be inlined into function 'aesni_setup' that is compiled without support for 'aes'
#target_compile_options(sqlext PRIVATE -maes)

# sqlcipher has calls to __android_log_print
target_link_libraries(sqlext log)
