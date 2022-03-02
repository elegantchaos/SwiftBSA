// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/03/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import BinaryCoding

public struct ContentFlags: OptionSetFromEnum {
    public enum Options: String, EnumForOptionSet {
        case meshes
        case textures
        case menus
        case sounds
        case voices
        case shaders
        case trees
        case fonts
        case miscellaneous
    }

    public let rawValue: UInt16
    
    public init() {
        self.rawValue = 0
    }
    
    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }
}

extension ContentFlags: Equatable {
}
