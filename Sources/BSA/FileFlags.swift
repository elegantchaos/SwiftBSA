// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/03/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

public struct FileFlags: RawRepresentable {
    public let rawValue: UInt16

    public init() {
        self.rawValue = 0
    }
    
    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }
}

extension FileFlags: Equatable {
}
