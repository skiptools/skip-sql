// Copyright 2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception

// This code is adapted from the SQLite.swift project, with the following license:

// SQLite.swift
// https://github.com/stephencelis/SQLite.swift
// Copyright © 2014-2015 Stephen Celis.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
import Foundation

/// See https://www.sqlite.org/uri.html
public enum URIQueryParameter: CustomStringConvertible {
    public enum FileMode: String {
        case readOnly = "ro", readWrite = "rw", readWriteCreate = "rwc", memory
    }

    public enum CacheMode: String {
        case shared, `private`
    }

    /// The cache query parameter determines if the new database is opened using shared cache mode or with a private cache.
    case cache(CacheMode)

    /// The immutable query parameter is a boolean that signals to SQLite that the underlying database file is held on read-only media
    /// and cannot be modified, even by another process with elevated privileges.
    case immutable(Bool)

    /// When creating a new database file during `sqlite3_open_v2()` on unix systems, SQLite will try to set the permissions of the new database
    /// file to match the existing file "filename".
    case modeOf(String)

    /// The mode query parameter determines if the new database is opened read-only, read-write, read-write and created if it does not exist,
    /// or that the database is a pure in-memory database that never interacts with disk, respectively.
    case mode(FileMode)

    /// The nolock query parameter is a boolean that disables all calls to the `xLock`, ` xUnlock`, and `xCheckReservedLock` methods
    /// of the VFS when true.
    case nolock(Bool)

    /// The psow query parameter overrides the `powersafe_overwrite` property of the database file being opened.
    case powersafeOverwrite(Bool)

    /// The vfs query parameter causes the database connection to be opened using the VFS called NAME.
    case vfs(String)

    public var description: String {
        queryItem.description
    }

    var queryItem: URLQueryItem {
        switch self {
        case .cache(let mode): return .init(name: "cache", value: mode.rawValue)
        case .immutable(let bool): return .init(name: "immutable", value: bool ? "true" : "false")
        case .modeOf(let filename): return .init(name: "modeOf", value: filename)
        case .mode(let fileMode): return .init(name: "mode", value: fileMode.rawValue)
        case .nolock(let bool): return .init(name: "nolock", value: bool ? "true" : "false")
        case .powersafeOverwrite(let bool): return .init(name: "psow", value: bool ? "true" : "false")
        case .vfs(let name): return .init(name: "vfs", value: name)
        }
    }
}
