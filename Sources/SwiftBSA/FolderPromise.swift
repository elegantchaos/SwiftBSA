// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/03/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import BinaryCoding

/// Contains all the information needed to write a folder record.
struct FolderPromise {
    let path: String
    let hash: UInt64
    let name: Data
    var files: [FilePromise]
    var patch: DataEncoder.Patch?
    
    init(path: String, files: [FilePromise]) {
        var data = Data()
        if let bytes = path.data(using: .windowsCP1252) {
            data.append(UInt8(bytes.count + 1)) // length includes zero byte
            data.append(contentsOf: bytes)
            data.append(UInt8(0))
        }
        
        self.path = path
        self.hash = path.bsaHash
        self.files = files
        self.name = data
        hashChannel.debug("folder: \(path), hash: \(String(format: "0x%0X",hash))")
    }
    
    mutating func encodeRecordingPatch(to encoder: DataEncoder) throws {
        patch = encoder.getPatch(offset: FolderRecord.patchOffset)
        try FolderRecord(self).binaryEncode(to: encoder)
    }
    
    func resolvePatch(for encoder: DataEncoder, header: BSAHeader) {
        patch?.resolve(UInt32(encoder.data.count + Int(header.totalFileNameLength)))
    }
}
