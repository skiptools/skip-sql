// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org
import SkipSQL

extension SQLiteConfiguration {
    /// The shared SQLContextTests uses thus local variable to determine the configuration to use
    public static let test = SQLiteConfiguration.platform
}
