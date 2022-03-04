// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 04/03/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BinaryCoding
import Foundation

struct FilePromise {
    let name: Data
    let path: Data
    let hash: UInt64
    let url: URL
    var sizePatch: DataEncoder.Patch?
    var offsetPatch: DataEncoder.Patch?
    
    init(url: URL, path: String) {
        let name = url.lastPathComponent.lowercased()
        var nameData = Data()
        if let bytes = name.data(using: .windowsCP1252) {
            nameData.append(contentsOf: bytes)
            nameData.append(UInt8(0))
        }

        let fullPath = "\(path)\\\(url.lastPathComponent)"
        var pathData = Data()
        if let bytes = fullPath.data(using: .windowsCP1252) {
            pathData.append(UInt8(bytes.count))
            pathData.append(contentsOf: bytes)
        }
        
        self.url = url
        self.name = nameData
        self.path = pathData
        self.hash = name.bsaHash
        hashChannel.debug("file: \(name), hash: \(String(format: "0x%0X",hash))")
    }
    
    mutating func encodeRecordingPatches(to encoder: DataEncoder) throws {
        offsetPatch = encoder.getPatch(offset: BSAFile.offsetOffset)
        sizePatch = encoder.getPatch(offset: BSAFile.sizeOffset)
        try BSAFile(self).binaryEncode(to: encoder)
    }
    
    func resolvePatches(for encoder: DataEncoder, size: Int) {
        sizePatch?.resolve(UInt32(size))
        offsetPatch?.resolve(UInt32(encoder.data.count))
    }

}
