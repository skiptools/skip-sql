cmake_minimum_required(VERSION 3.3)

project(sqlext LANGUAGES C)

file(GLOB_RECURSE SOURCES sqlite/*.c)
add_library(sqlext SHARED ${SOURCES})
include_directories(sqlext PUBLIC sqlite/)

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
add_compile_definitions(SQLITE_TEMP_STORE=2)
add_compile_definitions(HAVE_GETHOSTUUID=0)
add_compile_definitions(SQLCIPHER_CRYPTO_LIBTOMCRYPT)


set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -frtti -fexceptions")

#set(CMAKE_FIND_LIBRARY_PREFIXES "lib")
#set(CMAKE_FIND_LIBRARY_SUFFIXES ".so")

set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE BOTH)

set(CMAKE_FIND_DEBUG_MODE ON)

get_filename_component(CMAKE_PARENT_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR} DIRECTORY)
#message("CMAKE FINDING LIBRARY FOR ABI: ${ANDROID_ABI} in: ${CMAKE_PARENT_SOURCE_DIR} for build type: ${CMAKE_BUILD_TYPE}")

if(CMAKE_BUILD_TYPE STREQUAL "Release")
    set(BUILD_MODE "Release")
elseif(CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
    set(BUILD_MODE "Release")
elseif(CMAKE_BUILD_TYPE STREQUAL "MinSizeRel")
    set(BUILD_MODE "Release")
elseif(CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(BUILD_MODE "Debug")
else()
    message(WARNING "CMAKE_BUILD_TYPE is set to an unsupported value: ${CMAKE_BUILD_TYPE}. Defaulting to Debug.")
    set(BUILD_MODE "Debug")
endif()

string(TOLOWER "${BUILD_MODE}" BUILD_MODE_LOWER)

#message("CHECKING CMAKE LIBRARY: ${CMAKE_PARENT_SOURCE_DIR}/../LibTomCrypt/")

find_library(TOMCRYPT
    NAMES tomcrypt
    REQUIRED
    PATHS

    # the output paths for the LibTomCrypt project
    # it would be nice if we could discover this automatically based on the gradle dependency
    # after updating to the android-gradle-plugin 8.5.0, the output has moved to mergeDebugNativeLibs/mergeReleaseNativeLibs
    #${CMAKE_PARENT_SOURCE_DIR}/../LibTomCrypt/build/intermediates/merged_native_libs/${BUILD_MODE_LOWER}/out/lib/${ANDROID_ABI}/
    ${CMAKE_PARENT_SOURCE_DIR}/../LibTomCrypt/build/intermediates/merged_native_libs/${BUILD_MODE_LOWER}/merge${BUILD_MODE}NativeLibs/out/lib/${ANDROID_ABI}/
    ${CMAKE_PARENT_SOURCE_DIR}/../LibTomCrypt/.build/*/intermediates/merged_native_libs/${BUILD_MODE_LOWER}/merge${BUILD_MODE}NativeLibs/out/lib/${ANDROID_ABI}/

    NO_DEFAULT_PATH
    NO_CMAKE_FIND_ROOT_PATH
)


#message("CMAKE FIND LIBRARY FOR: ${ANDROID_ABI}: ${TOMCRYPT}")

target_link_libraries(sqlext ${TOMCRYPT})

# sqlite has calls to __android_log_print
target_link_libraries(sqlext log)

# support 16 KB page sizes: https://developer.android.com/guide/practices/page-sizes
target_link_options(${CMAKE_PROJECT_NAME} PRIVATE "-Wl,-z,max-page-size=16384")
