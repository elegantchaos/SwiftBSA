// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/03/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BinaryCoding
import Foundation

public struct FolderRecord: BinaryCodable {
    /// Hash of the folder name
    let hash: UInt64
    
    /// Number of files in the folder
    let count: UInt32
    
    /// Offset to the start of the folder/file data
    let offset: UInt32
    
    static var recordSize: UInt32 { return 24 }
    static var patchOffset: Int { return 16 }

    public init(fromBinary decoder: BinaryDecoder) throws {
        var container = try decoder.unkeyedContainer()
        self.hash = try container.decode(UInt64.self)
        let count = try container.decode(UInt32.self)
        _ = try container.decode(UInt32.self)
        self.offset = try container.decode(UInt32.self)
        _ = try container.decode(UInt32.self)
    
        self.count = count
    }
    
    init(_ folder: FolderPromise) {
        self.hash = folder.hash
        self.count = UInt32(folder.files.count)
        self.offset = 0
    }
    
    public func binaryEncode(to encoder: BinaryEncoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(hash)
        try container.encode(UInt32(count))
        try container.encode(UInt32(0))
        try container.encode(offset)
        try container.encode(UInt32(0))
    }
    
}
